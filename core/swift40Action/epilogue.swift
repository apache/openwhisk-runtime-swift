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

// Imports
import Foundation

let inputStr: String = readLine() ?? "{}"
let json = inputStr.data(using: .utf8, allowLossyConversion: true)!


// snippet of code "injected" (wrapper code for invoking traditional main)
func _run_main(mainFunction: ([String: Any]) -> [String: Any]) -> Void {
    let parsed = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
    let result = mainFunction(parsed)
    if JSONSerialization.isValidJSONObject(result) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
            if let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8) {
                print("\(jsonStr)")
            } else {
                print("Error serializing data to JSON, data conversion returns nil string")
            }
        } catch {
            print(("\(error)"))
        }
    } else {
        print("Error serializing JSON, data does not appear to be valid JSON")
    }
}

