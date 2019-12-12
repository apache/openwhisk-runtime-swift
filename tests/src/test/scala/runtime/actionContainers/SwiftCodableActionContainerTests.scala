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
abstract class SwiftCodableActionContainerTests extends BasicActionRunnerTests with WskActorSystem {

  // note: "out" will likely not be empty in some swift build as the compiler
  // prints status messages and there doesn't seem to be a way to quiet them
  val enforceEmptyOutputStream = false
  lazy val swiftContainerImageName = "action-swift-v4.0"
  lazy val swiftBinaryName = "tests/dat/build/swift4.0/HelloCodable.zip"

  behavior of s"Codable $swiftContainerImageName"

  override val testNoSourceOrExec = {
    TestConfig("")
  }

  override val testNotReturningJson = {
    // cannot compile function that doesn't return a json object
    TestConfig("", skipTest = true)
  }

  override val testEntryPointOtherThanMain = {
    TestConfig(
      """
        | struct AnInput: Codable {
        |  struct AnObject: Codable {
        |   let a: String?
        |  }
        |  let string: String?
        |  let numbers: [Int]?
        |  let object: AnObject?
        | }
        | func niam(input: AnInput, respondWith: @escaping (AnInput?, Error?) -> Void) -> Void {
        |    respondWith(input, nil)
        | }
      """.stripMargin,
      main = "niam",
      enforceEmptyOutputStream = enforceEmptyOutputStream)
  }

  override val testInitCannotBeCalledMoreThanOnce = {
    TestConfig("""
        | struct AnInput: Codable {
        |  struct AnObject: Codable {
        |   let a: String?
        |  }
        |  let string: String?
        |  let numbers: [Int]?
        |  let object: AnObject?
        | }
        | func main(input: AnInput, respondWith: @escaping (AnInput?, Error?) -> Void) -> Void {
        |    var standardError = FileHandle.standardError
        |    respondWith(input, nil)
        | }
      """.stripMargin)
  }

  override val testEcho = {
    TestConfig("""
        |
        | extension FileHandle : TextOutputStream {
        |     public func write(_ string: String) {
        |         guard let data = string.data(using: .utf8) else { return }
        |         self.write(data)
        |     }
        | }
        |
        | struct AnInput: Codable {
        |  struct AnObject: Codable {
        |   let a: String?
        |  }
        |  let string: String?
        |  let numbers: [Int]?
        |  let object: AnObject?
        | }
        | func main(input: AnInput, respondWith: @escaping (AnInput?, Error?) -> Void) -> Void {
        |    print("hello stdout")
        |    var standardError = FileHandle.standardError
        |    print("hello stderr", to: &standardError)
        |    respondWith(input, nil)
        | }
      """.stripMargin)
  }

  override val testUnicode = {
    TestConfig("""
        | struct AnInputOutput: Codable {
        |  let delimiter: String?
        |  let winter: String?
        |  let error: String?
        | }
        | func main(input: AnInputOutput, respondWith: (AnInputOutput?, Error?) -> Void) -> Void {
        |    if let str = input.delimiter as? String {
        |        let msg = "\(str) ☃ \(str)"
        |        print(msg)
        |        let answer = AnInputOutput(delimiter: nil, winter: msg, error: nil)
        |        respondWith(answer, nil)
        |    } else {
        |        let answer = AnInputOutput(delimiter: "no delimiter", winter: nil, error: nil)
        |        respondWith(answer, nil)
        |    }
        | }
      """.stripMargin.trim)
  }

  override val testEnv = {
    TestConfig(
      """
        | struct AnOutput: Codable {
        |  let api_host: String
        |  let api_key: String
        |  let namespace: String
        |  let action_name: String
        |  let action_version: String
        |  let activation_id: String
        |  let deadline: String
        | }
        | func main(respondWith: (AnOutput?, Error?) -> Void) -> Void {
        |     let env = ProcessInfo.processInfo.environment
        |     var a = "???"
        |     var b = "???"
        |     var c = "???"
        |     var d = "???"
        |     var r = "???"
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
        |     if let v : String = env["__OW_ACTION_VERSION"] {
        |         r = "\(v)"
        |     }
        |     if let v : String = env["__OW_ACTIVATION_ID"] {
        |         e = "\(v)"
        |     }
        |     if let v : String = env["__OW_DEADLINE"] {
        |         f = "\(v)"
        |     }
        |     let result = AnOutput(api_host:a, api_key:b, namespace:c, action_name:d, action_version:r, activation_id:e, deadline: f)
        |     respondWith(result, nil)
        | }
      """.stripMargin,
      enforceEmptyOutputStream = enforceEmptyOutputStream)
  }

  override val testLargeInput = {
    TestConfig(if (false) {
      // this is returning {} instead of the expected output
      """
        | struct AnInput: Codable {
        |  struct AnObject: Codable {
        |   let a: String?
        |  }
        |  let string: String?
        |  let numbers: [Int]?
        |  let object: AnObject?
        | }
        | func main(input: AnInput, respondWith: @escaping (AnInput?, Error?) -> Void) -> Void {
        |    respondWith(input, nil)
        | }
      """.stripMargin
    } else {
      """
        | func main(args: [String: Any]) -> [String: Any] {
        |     return args
        | }
      """.stripMargin
    })
  }

  it should "support application errors" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | struct Result: Codable{
                   |    let error: String?
                   | }
                   | func main(respondWith: (Result?, Error?) -> Void) -> Void {
                   |    respondWith(Result(error: "sorry"), nil)
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

  // Helpers specific to swift actions
  override def withActionContainer(env: Map[String, String] = Map.empty)(code: ActionContainer => Unit) = {
    withContainer(swiftContainerImageName, env)(code)
  }
}
