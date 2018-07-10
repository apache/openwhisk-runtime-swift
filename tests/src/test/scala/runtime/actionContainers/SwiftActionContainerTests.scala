/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package runtime.actionContainers

import java.io.File

import common.WskActorSystem
import actionContainers.{ActionContainer, BasicActionRunnerTests}
import actionContainers.ActionContainer.withContainer
import actionContainers.ResourceHelpers.readAsBase64
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import spray.json._

@RunWith(classOf[JUnitRunner])
abstract class SwiftActionContainerTests extends BasicActionRunnerTests with WskActorSystem {

  // note: "out" will likely not be empty in some swift build as the compiler
  // prints status messages and there doesn't seem to be a way to quiet them
  val enforceEmptyOutputStream = false
  lazy val swiftContainerImageName: String = ???
  lazy val swiftBinaryName: String = ???
  val httpCode: String

  behavior of swiftContainerImageName

  override val testNoSourceOrExec = {
    TestConfig("")
  }

  override val testNotReturningJson = {
    // cannot compile function that doesn't return a json object
    TestConfig("", skipTest = true)
  }

  override val testInitCannotBeCalledMoreThanOnce = {
    TestConfig("""
        | func main(args: [String: Any]) -> [String: Any] {
        |     return args
        | }
      """.stripMargin)
  }

  override val testEntryPointOtherThanMain = {
    TestConfig(
      """
        | func niam(args: [String: Any]) -> [String: Any] {
        |     return args
        | }
      """.stripMargin,
      main = "niam",
      enforceEmptyOutputStream = enforceEmptyOutputStream)
  }

  override val testEcho = {
    TestConfig("""
        | import Foundation
        |
        | extension FileHandle : TextOutputStream {
        |     public func write(_ string: String) {
        |         guard let data = string.data(using: .utf8) else { return }
        |         self.write(data)
        |     }
        | }
        |
        | func main(args: [String: Any]) -> [String: Any] {
        |     print("hello stdout")
        |     var standardError = FileHandle.standardError
        |     print("hello stderr", to: &standardError)
        |     return args
        | }
      """.stripMargin)
  }

  override val testUnicode = {
    TestConfig("""
        | func main(args: [String: Any]) -> [String: Any] {
        |     if let str = args["delimiter"] as? String {
        |         let msg = "\(str) ☃ \(str)"
        |         print(msg)
        |         return [ "winter" : msg ]
        |     } else {
        |         return [ "error" : "no delimiter" ]
        |     }
        | }
      """.stripMargin.trim)
  }

  override val testEnv = {
    TestConfig(
      """
        | func main(args: [String: Any]) -> [String: Any] {
        |     let env = ProcessInfo.processInfo.environment
        |     var a = "???"
        |     var b = "???"
        |     var c = "???"
        |     var d = "???"
        |     var e = "???"
        |     var f = "???"
        |     if let v : String = env["__OW_API_HOST"] {
        |         a = "\(v)"
        |     }
        |     if let v : String = env["__OW_API_KEY"] {
        |         b = "\(v)"
        |     }
        |     if let v : String = env["__OW_NAMESPACE"] {
        |         c = "\(v)"
        |     }
        |     if let v : String = env["__OW_ACTION_NAME"] {
        |         d = "\(v)"
        |     }
        |     if let v : String = env["__OW_ACTIVATION_ID"] {
        |         e = "\(v)"
        |     }
        |     if let v : String = env["__OW_DEADLINE"] {
        |         f = "\(v)"
        |     }
        |     return ["api_host": a, "api_key": b, "namespace": c, "action_name": d, "activation_id": e, "deadline": f]
        | }
      """.stripMargin,
      enforceEmptyOutputStream = enforceEmptyOutputStream)
  }

  override val testLargeInput = {
    TestConfig("""
        | func main(args: [String: Any]) -> [String: Any] {
        |     return args
        | }
      """.stripMargin)
  }

  it should "return some error on action error" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | // You need an indirection, or swiftc detects the div/0
                   | // at compile-time. Smart.
                   | func div(x: Int, y: Int) -> Int {
                   |     return x/y
                   | }
                   | func main(args: [String: Any]) -> [String: Any] {
                   |     return [ "divBy0": div(x:5, y:0) ]
                   | }
                 """.stripMargin

      val (initCode, _) = c.init(initPayload(code))
      initCode should be(200)

      val (runCode, runRes) = c.run(runPayload(JsObject()))
      runCode should be(502)

      runRes shouldBe defined
      runRes.get.fields.get("error") shouldBe defined
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        if (enforceEmptyOutputStream) e shouldBe empty
    })
  }

  it should "log compilation errors" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | 10 PRINT "Hello!"
                   | 20 GOTO 10
                 """.stripMargin

      val (initCode, _) = c.init(initPayload(code))
      initCode should not be (200)
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e.toLowerCase should include("error")
    })
  }

  it should "support application errors" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | func main(args: [String: Any]) -> [String: Any] {
                   |     return [ "error": "sorry" ]
                   | }
                 """.stripMargin

      val (initCode, _) = c.init(initPayload(code))
      initCode should be(200)

      val (runCode, runRes) = c.run(runPayload(JsObject()))
      runCode should be(200) // action writer returning an error is OK

      runRes shouldBe defined
      runRes should be(Some(JsObject("error" -> JsString("sorry"))))
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  it should "support pre-compiled binary in a zip file" in {
    val zip = new File(swiftBinaryName).toPath
    val code = readAsBase64(zip)

    val (out, err) = withActionContainer() { c =>
      val (initCode, initRes) = c.init(initPayload(code))
      initCode should be(200)

      val args = JsObject()
      val (runCode, runRes) = c.run(runPayload(args))

      runCode should be(200)
      runRes.get shouldBe JsObject("greeting" -> (JsString("Hello stranger!")))
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  it should "be able to do an http request" in {
    val (out, err) = withActionContainer() { c =>
      val (initCode, _) = c.init(initPayload(httpCode))

      initCode should be(200)

      val argss = List(JsObject("getUrl" -> JsString("https://openwhisk.ng.bluemix.net/api/v1")))

      for (args <- argss) {
        val (runCode, out) = c.run(runPayload(args))
        runCode should be(200)
      }
    }

    // in side try catch finally print (out file)
    // in catch block an error has occurred, get docker logs and print
    // throw

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }

  // Helpers specific to swift actions
  override def withActionContainer(env: Map[String, String] = Map.empty)(code: ActionContainer => Unit) = {
    withContainer(swiftContainerImageName, env)(code)
  }

}
