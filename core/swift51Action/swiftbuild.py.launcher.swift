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
    _whisk_print_buffer(jsonString: errStr)
}
func _whisk_print_result(jsonData: Data){
    let jsonString = String(data: jsonData, encoding: .utf8)!
    _whisk_print_buffer(jsonString: jsonString)
}
func _whisk_print_buffer(jsonString: String){
    var buf : [UInt8] = Array(jsonString.utf8)
    buf.append(10)
    fflush(stdout)
    fflush(stderr)
    write(3, buf, buf.count)
}

// snippet of code "injected" (wrapper code for invoking traditional main)
func _run_main(mainFunction: ([String: Any]) -> [String: Any], json: Data) -> Void {
    do {
        let parsed = try JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
        let result = mainFunction(parsed)
        if JSONSerialization.isValidJSONObject(result) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
                 _whisk_print_result(jsonData: jsonData)
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
func _run_main<In: Decodable, Out: Encodable>(mainFunction: (In, @escaping (Out?, Error?) -> Void) -> Void, json: Data) {
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
                _whisk_print_result(jsonData: jsonData)
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
        _whisk_print_error(message: "JSONDecoder failed to decode JSON string \(String(data: json, encoding: .utf8)!.replacingOccurrences(of: "\"", with: "\\\"")) to Codable type:", error: error)
        return
    } catch {
        _whisk_print_error(message: "Failed to execute action handler with error:", error: error)
        return
    }
}

// Codable main signature no input
func _run_main<Out: Encodable>(mainFunction: ( @escaping (Out?, Error?) -> Void) -> Void, json: Data) {
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
            _whisk_print_result(jsonData: jsonData)
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

// snippets of code "injected", depending on the type of function the developer
// wants to use traditional vs codable







