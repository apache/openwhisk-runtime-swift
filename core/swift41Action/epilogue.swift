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
import Dispatch

let inputStr: String = readLine() ?? "{}"
let json = inputStr.data(using: .utf8, allowLossyConversion: true)!

let _whisk_semaphore = DispatchSemaphore(value: 0)
func _whisk_print_error(message: String, error: Error?){
    if let error = error {
        print("{\"error\":\"\(message) \(error.localizedDescription)\"}")
    } else {
       print("{\"error\":\"\(message)\"}")
    }
    _whisk_semaphore.signal()
}

// snippet of code "injected" (wrapper code for invoking traditional main)
func _run_main(mainFunction: ([String: Any]) -> [String: Any]) -> Void {
    do {
        let parsed = try JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
        let result = mainFunction(parsed)
        if JSONSerialization.isValidJSONObject(result) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
                if let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8) {
                    print("\(jsonStr)")
                    _whisk_semaphore.signal()
                } else {
                    _whisk_print_error(message: "Error serializing data to JSON, data conversion returns nil string", error: nil)
                }
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

// Codable main signature input Codable
func _run_main<In: Decodable, Out: Encodable>(mainFunction: (In, @escaping (Out?, Error?) -> Void) -> Void) {
    do {
        let input = try Whisk.jsonDecoder.decode(In.self, from: json)
        let resultHandler = { (out: Out?, error: Error?) in
            if let error = error {
                _whisk_print_error(message: "Action handler callback returned an error:", error: error)
                return
            }
            guard let out = out else {
                _whisk_print_error(message: "Action handler callback did not return response or error.", error: nil)
                return
            }
            do {
                let jsonData = try Whisk.jsonEncoder.encode(out)
                let jsonString = String(data: jsonData, encoding: .utf8)
                print("\(jsonString!)")
                _whisk_semaphore.signal()
            } catch let error as EncodingError {
                _whisk_print_error(message: "JSONEncoder failed to encode Codable type to JSON string:", error: error)
                return
            } catch {
                _whisk_print_error(message: "Failed to execute action handler with error:", error: error)
                return
            }
        }
        let _ = mainFunction(input, resultHandler)
    } catch let error as DecodingError {
        _whisk_print_error(message: "JSONDecoder failed to decode JSON string \(inputStr.replacingOccurrences(of: "\"", with: "\\\"")) to Codable type:", error: error)
        return
    } catch {
        _whisk_print_error(message: "Failed to execute action handler with error:", error: error)
        return
    }
}

// Codable main signature no input
func _run_main<Out: Encodable>(mainFunction: ( @escaping (Out?, Error?) -> Void) -> Void) {
    let resultHandler = { (out: Out?, error: Error?) in
        if let error = error {
            _whisk_print_error(message: "Action handler callback returned an error:", error: error)
            return
        }
        guard let out = out else {
            _whisk_print_error(message: "Action handler callback did not return response or error.", error: nil)
            return
        }
        do {
            let jsonData = try Whisk.jsonEncoder.encode(out)
            let jsonString = String(data: jsonData, encoding: .utf8)
            print("\(jsonString!)")
            _whisk_semaphore.signal()
        } catch let error as EncodingError {
            _whisk_print_error(message: "JSONEncoder failed to encode Codable type to JSON string:", error: error)
            return
        } catch {
            _whisk_print_error(message: "Failed to execute action handler with error:", error: error)
            return
        }
    }
    let _ = mainFunction(resultHandler)
}

// snippets of code "injected", dependending on the type of function the developer
// wants to use traditional vs codable

