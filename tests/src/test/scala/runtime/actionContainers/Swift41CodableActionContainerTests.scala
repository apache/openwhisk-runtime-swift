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

import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import spray.json.JsObject

@RunWith(classOf[JUnitRunner])
class Swift41CodableActionContainerTests extends SwiftCodableActionContainerTests {
  override lazy val swiftContainerImageName = "action-swift-v4.1"
  override lazy val swiftBinaryName = "tests/dat/build/swift4.1/HelloSwift4Codable.zip"

  // TODO
  // swift 4.2 exceptions executable exiting doesn't return error from web proxy or ends container
  // the action times out
  it should "return some error on action error" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
                   | // You need an indirection, or swiftc detects the div/0
                   | // at compile-time. Smart.
                   | func div(x: Int, y: Int) -> Int {
                   |    return x/y
                   | }
                   | struct Result: Codable{
                   |    let divBy0: Int?
                   | }
                   | func main(respondWith: (Result?, Error?) -> Void) -> Void {
                   |    respondWith(Result(divBy0: div(x:5, y:0)), nil)
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
        e should not be empty
    })
  }
}
