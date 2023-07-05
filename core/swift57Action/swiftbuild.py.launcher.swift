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
import _Concurrency
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public struct _WhiskRuntime {

    private enum WhiskRuntimeErrorMessage: String {
        case actionHandlerCallbackError = "Action handler callback returned an error:"
        case actionHandlerCallbackNullOrError = "Action handler callback did not return response or error."
        case failToEncodeDictionary = "Failed to encode Dictionary type to JSON string:"
        case failToEncodeCodableToJson = "JSONEncoder failed to encode Codable type to JSON string:"
        case errorSerializingJSON = "Error serializing JSON, data does not appear to be valid JSON"
        case failedToExecuteActionHandler = "Failed to execute action handler with error:"
    }

    public static func wiskRunLoop(actionMain: ((Data) async -> Void)) async throws {
        while let inputStr: String = readLine() {
            let json = inputStr.data(using: .utf8, allowLossyConversion: true)!
            let parsed = try JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
            for (key, value) in parsed {
                if key != "value" {
                    setenv("__OW_\(key.uppercased())",value as! String,1)
                }
            }
            let jsonData = try JSONSerialization.data(withJSONObject: parsed["value"] as Any, options: [])
            await actionMain(jsonData)
        }
    }

    private static func whiskPrintJSONDecoderError(json: Data, error: Error?) {
        let jsonString = String(
            data: json,
            encoding: .utf8
        ) ?? ""
        let fixedJSONString = jsonString.replacingOccurrences(of: "\"", with: "\\\"")

        let message = "JSONDecoder failed to decode JSON string \(fixedJSONString) to Codable type:"
        var errStr =  "{\"error\":\"\(message)\"}\n"
        if let error = error {
            errStr = "{\"error\":\"\(message) \(error.localizedDescription)\"\n}"
        }
        whiskPrintBuffer(jsonString: errStr)
    }

    private static func whiskPrintError(message: WhiskRuntimeErrorMessage, error: Error?){
        var errStr =  "{\"error\":\"\(message.rawValue)\"}\n"
        if let error = error {
            errStr = "{\"error\":\"\(message.rawValue) \(error.localizedDescription)\"\n}"
        }
        whiskPrintBuffer(jsonString: errStr)
    }

    private static func whiskPrintResult(jsonData: Data){
        let jsonString = String(data: jsonData, encoding: .utf8)!
        whiskPrintBuffer(jsonString: jsonString)
    }

    private static func whiskPrintBuffer(jsonString: String){
        var buf : [UInt8] = Array(jsonString.utf8)
        buf.append(10)
        fflush(stdout)
        fflush(stderr)
        write(3, buf, buf.count)
    }

    /**
     Execute an async throwing Action with Any Input and Any Output

     Example:

     ```
     func action(args: Any) async throws -> Any {
         //async code sleep for 1 sec
         try await Task.sleep(nanoseconds: 1_000_000_000)

         let newArgs = args as! [String:Any]
         if let name = newArgs["name"] as? String {
             return [ "greeting" : "Hello \(name)!" ]
         } else {
             return [ "greeting" : "Hello stranger!" ]
         }
     }
     ```

     - Parameters:
        - mainFunction: action
        - json: action parameters
        - Returns: Void
    */
    public static func runAsyncMain(mainFunction: (Any) async throws -> Any, json: Data) async -> Void {
        do {
            let parsed = try JSONSerialization.jsonObject(with: json, options: [])
            let result = try await mainFunction(parsed)
            if JSONSerialization.isValidJSONObject(result) {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
                    whiskPrintResult(jsonData: jsonData)
                } catch {
                    whiskPrintError(message: .failToEncodeDictionary, error: error)
                }
            } else {
                whiskPrintError(message: .errorSerializingJSON, error: nil)
            }
        } catch let error as DecodingError {
            whiskPrintJSONDecoderError(json: json, error: error)
            return
        } catch {
            whiskPrintError(message: .failedToExecuteActionHandler, error: error)
            return
        }
    }

    /**
     Execute an Action with Codable Input and completion with Codable Output and Error

     Example:

     ```
     struct Input: Codable {
         let name: String?
     }

     struct Output: Codable {
         let count: Int
     }

     func action(input: Input, completion: @escaping (Output?, Error?) -> Void) -> Void {
         if let name = input.name {
             let output = Output(count: name.count)
             completion(output, nil)
         } else {
             let output = Output(count: 0)
             completion(output, nil)
         }
     }
     ```

     - Parameters:
        - mainFunction: action
        - json: action parameters
        - Returns: Void
    */
    public static func runAsyncMain<In: Decodable, Out: Encodable>(mainFunction: (In, @escaping (Out?, Error?) -> Void) -> Void, json: Data) {
        do {
            let input = try Whisk.jsonDecoder.decode(In.self, from: json)
            let resultHandler = { (out: Out?, error: Error?) in
                if let error = error {
                    whiskPrintError(message: .actionHandlerCallbackError, error: error)
                    return
                }
                guard let out = out else {
                    whiskPrintError(message: .actionHandlerCallbackNullOrError, error: nil)
                    return
                }
                do {
                    let jsonData = try Whisk.jsonEncoder.encode(out)
                    whiskPrintResult(jsonData: jsonData)
                } catch let error as EncodingError {
                    whiskPrintError(message: .failToEncodeCodableToJson, error: error)
                    return
                } catch {
                    whiskPrintError(message: .failedToExecuteActionHandler, error: error)
                    return
                }
            }
            let _ = mainFunction(input, resultHandler)
        } catch let error as DecodingError {
            whiskPrintJSONDecoderError(json: json, error: error)
            return
        } catch {
            whiskPrintError(message: .failedToExecuteActionHandler, error: error)
            return
        }
    }

    /**
     Execute an async throwing Action with a Codable Input and a Codable Output

     Example:

     ```
     struct Input: Codable {
         let name: String?
     }

     struct Output: Codable {
         let count: Int
     }

     func action(input: Input) async throws -> Output? {
         try await Task.sleep(nanoseconds: 1_000_000_000)
         if let name = input.name {
             return Output(count: name.count)
         } else {
             return Output(count: 0)
         }
     }
     ```

     - Parameters:
        - mainFunction: action
        - json: action parameters
        - Returns: Void
    */
    public static func runAsyncMain<In: Decodable, Out: Encodable>(mainFunction: (In) async throws -> Out?, json: Data) async {
        do {
            let input = try Whisk.jsonDecoder.decode(In.self, from: json)
            do {
                let out = try await mainFunction(input)
                guard let out = out else {
                    whiskPrintError(message: .actionHandlerCallbackNullOrError, error: nil)
                    return
                }
                do {
                    let jsonData = try Whisk.jsonEncoder.encode(out)
                    whiskPrintResult(jsonData: jsonData)
                } catch let error as EncodingError {
                    whiskPrintError(message: .failToEncodeCodableToJson, error: error)
                    return
                } catch {
                    whiskPrintError(message: .failedToExecuteActionHandler, error: error)
                    return
                }
            } catch {
                whiskPrintError(message: .actionHandlerCallbackError, error: error)
                return
            }
        } catch let error as DecodingError {
            whiskPrintJSONDecoderError(json: json, error: error)
            return
        } catch {
            whiskPrintError(message: .failedToExecuteActionHandler, error: error)
            return
        }
    }

    /**
     Execute an Action with Codable Input and completion with Codable Output and Error

     Example:

     ```
     struct Input: Codable {
         let name: String?
     }

     struct Output: Codable {
         let count: Int
     }

     func action(completion: @escaping (Output?, Error?) -> Void) -> Void {
         let output = Output(count: 0)
         completion(output, nil)
     }
     ```

     - Parameters:
        - mainFunction: action
        - json: action parameters
        - Returns: Void
    */
    public static func runAsyncMain<Out: Encodable>(mainFunction: ( @escaping (Out?, Error?) -> Void) -> Void, json: Data) {
        let resultHandler = { (out: Out?, error: Error?) in
            if let error = error {
                whiskPrintError(message: .actionHandlerCallbackError, error: error)
                return
            }
            guard let out = out else {
                whiskPrintError(message: .actionHandlerCallbackNullOrError, error: nil)
                return
            }
            do {
                let jsonData = try Whisk.jsonEncoder.encode(out)
                whiskPrintResult(jsonData: jsonData)
            } catch let error as EncodingError {
                whiskPrintError(message: .failToEncodeCodableToJson, error: error)
                return
            } catch {
                whiskPrintError(message: .failedToExecuteActionHandler, error: error)
                return
            }
        }
        let _ = mainFunction(resultHandler)
    }

    /**
     Execute an async throwing Action with Codable Output

     Example:

     ```
     struct Input: Codable {
         let name: String?
     }

     struct Output: Codable {
         let count: Int
     }

     func action() async throws -> Output? {
         try await Task.sleep(nanoseconds: 1_000_000_000)
         return Output(count: 0)
     }
     ```

     - Parameters:
        - mainFunction: action
        - json: action parameters
        - Returns: Void
    */
    public static func runAsyncMain<Out: Encodable>(mainFunction: () async throws -> Out?, json: Data) async {
        do {
            let out = try await mainFunction()
            guard let out = out else {
                whiskPrintError(message: .actionHandlerCallbackNullOrError, error: nil)
                return
            }
            do {
                let jsonData = try Whisk.jsonEncoder.encode(out)
                whiskPrintResult(jsonData: jsonData)
            } catch let error as EncodingError {
                whiskPrintError(message: .failToEncodeCodableToJson, error: error)
                return
            } catch {
                whiskPrintError(message: .failedToExecuteActionHandler, error: error)
                return
            }
        } catch {
            whiskPrintError(message: .actionHandlerCallbackError, error: error)
            return
        }
    }
}




