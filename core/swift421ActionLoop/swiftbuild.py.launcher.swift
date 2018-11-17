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
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

func _whisk_print_error(message: String, error: Error?){
    var errStr =  "{\"error\":\"\(message)\"}\n"
    if let error = error {
      errStr = "{\"error\":\"\(message) \(error.localizedDescription)\"\n}"
    }
    let buf : [UInt8] = Array(errStr.utf8)
    write(3, buf, buf.count)
}

// snippet of code "injected" (wrapper code for invoking traditional main)
func _run_main(mainFunction: ([String: Any]) -> [String: Any]) -> Void {
    while let inputStr: String = readLine() {
        do {
            let json = inputStr.data(using: .utf8, allowLossyConversion: true)!
            let parsed = try JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
            // TODO put the values in the env
            let value = parsed["value"] as! [String: Any]
            let result = mainFunction(value)
            if JSONSerialization.isValidJSONObject(result) {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
                    var json = [UInt8](jsonData)
                    json.append(10)
                    write(3, json, json.count)
                    fflush(stdout)
                    fflush(stderr)
                } catch {
                    _whisk_print_error(message: "Failed to encode Dictionary type to JSON string:", error: error)
                }
            } else {
                _whisk_print_error(message: "Error serializing JSON, data does not appear to be valid JSON", error: nil)
            }
        } catch {
            _whisk_print_error(message: "Failed to execute action handler with error:", error: error)
            return
        }
    }
}

// snippets of code "injected", dependending on the type of function the developer
// wants to use traditional vs codable

