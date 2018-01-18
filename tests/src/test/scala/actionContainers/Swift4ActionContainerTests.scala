package runtime.actionContainers

import common.WskActorSystem
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import spray.json.{JsObject, JsString}
import ActionContainer.withContainer


@RunWith(classOf[JUnitRunner])
class Swift4ActionContainerTests extends BasicActionRunnerTests with WskActorSystem {

  val enforceEmptyOutputStream = false
  lazy val swiftContainerImageName = "action-swift-v4"
  lazy val envCode = makeEnvCode("ProcessInfo.processInfo")

  def makeEnvCode(processInfo: String) = (
          """
          |func main(args: [String: Any]) -> [String: Any] {
          |     let env = """ + processInfo + """.environment
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
          |}
          """).stripMargin
  lazy val errorCode = """
           | // You need an indirection, or swiftc detects the div/0
           | // at compile-time. Smart.
           | func div(x: Int, y: Int) -> Int {
           |     return x/y
           | }
           | func main(args: [String: Any]) -> [String: Any] {
           |     return [ "divBy0": div(x:5, y:0) ]
           | }
         """.stripMargin

  behavior of swiftContainerImageName

  testEcho(Seq {
    (
      "swift 4 echo",
      """
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
  })

  testUnicode(Seq {
    (
      "swift 4",
      """
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
  })

  testEnv(Seq {
    ("swift 4", envCode)
  }, enforceEmptyOutputStream)


  it should "support actions using non-default entry points" in {
    withActionContainer() { c =>
      val code = """
                   | func niam(args: [String: Any]) -> [String: Any] {
                   |     return [ "result": "it works" ]
                   | }
                   |""".stripMargin

      val (initCode, initRes) = c.init(initPayload(code, main = "niam"))
      initCode should be(200)

      val (_, runRes) = c.run(runPayload(JsObject()))
      runRes.get.fields.get("result") shouldBe Some(JsString("it works"))
    }
  }

  it should "return some error on action error" in {
    val (out, err) = withActionContainer() { c =>
      val code = errorCode

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
        e shouldBe empty
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


  // Helpers specific to swift actions
  override def withActionContainer(env: Map[String, String] = Map.empty)(code: ActionContainer => Unit) = {
    withContainer(swiftContainerImageName, env)(code)
  }

}
