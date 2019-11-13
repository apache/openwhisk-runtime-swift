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

import SwiftyRequest
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    var resp :[String:Any] = ["error":"Action failed"]
    let echoURL = "http://httpbin.org/post"

    // setting body data to {"Data":"string"}
    let origJson: [String: Any] = args
    guard let data = try? JSONSerialization.data(withJSONObject: origJson, options: []) else {
        return ["error": "Could not encode json"]
    }
    let request = RestRequest(method: .post, url: echoURL)
    request.messageBody = data
    let semaphore = DispatchSemaphore(value: 0)
    //sending with query ?hour=9
    request.responseData(queryItems: [URLQueryItem(name: "hour", value: "9")]) { result in
        switch result {
        case .success(let retval):
            if let json = try? JSONSerialization.jsonObject(with: retval.body, options: []) as? [String:Any]  {
                resp = json
            } else {
                resp = ["error":"Response from server is not a dictionary like"]
            }
        case .failure(let error):
            resp = ["error":"Failed to get data response: \(error)"]
        }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .distantFuture)
    return resp
}
//let r = main(args:["message":"serverless"])
//print(r)
