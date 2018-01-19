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
import spray.json.JsString


@RunWith(classOf[JUnitRunner])
class Swift311ActionContainerTests extends SwiftActionContainerTests {

  override lazy val swiftContainerImageName = "action-swift-v3.1.1"
  override lazy val swiftBinaryName = System.getProperty("user.dir") + "/dat/build/swift311/HelloSwift3.zip"


  lazy val watsonCode = """
        | import AlchemyDataNewsV1
        | import ConversationV1
        | import DiscoveryV1
        | import DocumentConversionV1
        | import NaturalLanguageClassifierV1
        | import NaturalLanguageUnderstandingV1
        | import PersonalityInsightsV3
        | import RetrieveAndRankV1
        | import ToneAnalyzerV3
        | import TradeoffAnalyticsV1
        | import VisualRecognitionV3
        |
        | func main(args: [String:Any]) -> [String:Any] {
        |     return ["message": "I compiled and was able to import Watson SDKs"]
        | }
    """.stripMargin

  val httpCode = """
         | import KituraNet
         | import Foundation
         | import Dispatch
         | func main(args:[String: Any]) -> [String:Any] {
         |       let retries = 3
         |       var resp = [String:Any]()
         |       var attempts = 0
         |       if let url = args["getUrl"] as? String {
         |           while attempts < retries {
         |               let group = DispatchGroup()
         |               let queue = DispatchQueue.global(qos: .default)
         |               group.enter()
         |               queue.async {
         |                   HTTP.get(url, callback: { response in
         |                       if let response = response {
         |                           do {
         |                               var jsonData = Data()
         |                               try response.readAllData(into: &jsonData)
         |                               if let dic = WhiskJsonUtils.jsonDataToDictionary(jsonData: jsonData) {
         |                                   resp = dic
         |                               } else {
         |                                   resp = ["error":"response from server is not JSON"]
         |                               }
         |                           } catch {
         |                              resp["error"] = error.localizedDescription
         |                           }
         |                       }
         |                       group.leave()
         |                   })
         |               }
         |            switch group.wait(timeout: DispatchTime.distantFuture) {
         |                case DispatchTimeoutResult.success:
         |                    resp["attempts"] = attempts
         |                    return resp
         |                case DispatchTimeoutResult.timedOut:
         |                    attempts = attempts + 1
         |            }
         |        }
         |     }
         |     return ["status":"Exceeded \(retries) attempts, aborting."]
         | }
       """.stripMargin

  it should "properly use KituraNet and Dispatch" in {
    val (out, err) = withActionContainer() { c =>
      val code = """
          | import KituraNet
          | import Foundation
          | import Dispatch
          | func main(args:[String: Any]) -> [String:Any] {
          |       let retries = 3
          |       var resp = [String:Any]()
          |       var attempts = 0
          |       if let url = args["getUrl"] as? String {
          |           while attempts < retries {
          |               let group = DispatchGroup()
          |               let queue = DispatchQueue.global(qos: .default)
          |               group.enter()
          |               queue.async {
          |                   HTTP.get(url, callback: { response in
          |                       if let response = response {
          |                           do {
          |                               var jsonData = Data()
          |                               try response.readAllData(into: &jsonData)
          |                               if let dic = WhiskJsonUtils.jsonDataToDictionary(jsonData: jsonData) {
          |                                   resp = dic
          |                               } else {
          |                                   resp = ["error":"response from server is not JSON"]
          |                               }
          |                           } catch {
          |                              resp["error"] = error.localizedDescription
          |                           }
          |                       }
          |                       group.leave()
          |                   })
          |               }
          |            switch group.wait(timeout: DispatchTime.distantFuture) {
          |                case DispatchTimeoutResult.success:
          |                    resp["attempts"] = attempts
          |                    return resp
          |                case DispatchTimeoutResult.timedOut:
          |                    attempts = attempts + 1
          |            }
          |        }
          |     }
          |     return ["status":"Exceeded \(retries) attempts, aborting."]
          | }
      """.stripMargin

      val (initCode, _) = c.init(initPayload(code))

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

  it should "make Watson SDKs available to action authors" in {
    val (out, err) = withActionContainer() { c =>
      val code = watsonCode

      val (initCode, _) = c.init(initPayload(code))

      initCode should be(200)

      val (runCode, out) = c.run(runPayload(JsObject()))
      runCode should be(200)
    }

    checkStreams(out, err, {
      case (o, e) =>
        if (enforceEmptyOutputStream) o shouldBe empty
        e shouldBe empty
    })
  }
}
