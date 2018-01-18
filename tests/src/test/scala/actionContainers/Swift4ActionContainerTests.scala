package runtime.actionContainers

import common.WskActorSystem
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import spray.json.{JsObject, JsString}
import ActionContainer.withContainer


@RunWith(classOf[JUnitRunner])
class Swift4ActionContainerTests extends BasicActionRunnerTests with WskActorSystem {

  lazy val swiftContainerImageName = "action-swift-v4"

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
  // Helpers specific to swift actions
  override def withActionContainer(env: Map[String, String] = Map.empty)(code: ActionContainer => Unit) = {
    withContainer(swiftContainerImageName, env)(code)
  }

}
