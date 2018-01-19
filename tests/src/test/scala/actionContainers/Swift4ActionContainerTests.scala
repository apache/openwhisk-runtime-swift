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


@RunWith(classOf[JUnitRunner])
class Swift4ActionContainerTests extends SwiftActionContainerTests {

  override lazy val swiftContainerImageName = "action-swift-v4"
  override lazy val swiftBinaryName = System.getProperty("user.dir") + "/dat/build/swift4/HelloSwift4.zip"

  val httpCode = """
       | import Dispatch
       | func main(args:[String: Any]) -> [String:Any] {
       |     var resp :[String:Any] = ["error":"getUrl failed"]
       |     guard let urlStr = args["getUrl"] as? String else {
       |         return ["error":"getUrl not found in action input"]
       |     }
       |     guard let url = URL(string: urlStr) else {
       |         return ["error":"invalid url string \(urlStr)"]
       |     }
       |     let request = URLRequest(url: url)
       |     let session = URLSession(configuration: .default)
       |     let semaphore = DispatchSemaphore(value: 0)
       |     let task = session.dataTask(with: request, completionHandler: {data, response, error -> Void in
       |         print("done with http request")
       |         if let error = error {
       |             print("There was an error \(error)")
       |         } else if let data = data,
       |             let response = response as? HTTPURLResponse,
       |             response.statusCode == 200 {
       |             do {
       |                 let respJson = try JSONSerialization.jsonObject(with: data)
       |                 if respJson is [String:Any] {
       |                     resp = respJson as! [String:Any]
       |                 } else {
       |                     resp = ["error":"Response from server is not a dictionary"]
       |                 }
       |             } catch {
       |                 resp = ["error":"Error creating json from response: \(error)"]
       |             }
       |         }
       |         semaphore.signal()
       |     })
       |     task.resume()
       |     _ = semaphore.wait(timeout: .distantFuture)
       |     return resp
       | }
     """.stripMargin

}