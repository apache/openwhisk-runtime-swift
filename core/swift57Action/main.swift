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

import Foundation

enum MainActionError: LocalizedError {
    case invalidArgs
    var errorDescription: String? {
        switch self {
        case .invalidArgs:
            return "Invalid arguments"
        }
    }
}

func main(args: Any) async throws -> Any {
    
    //async code sleep for 1 microsecond
    try await Task.sleep(nanoseconds: 1_000)
    
    guard let newArgs = args as? [String:Any] else {
        throw MainActionError.invalidArgs
    }
    if let name = newArgs["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello stranger!" ]
    }
}


/* Examples of Actions supported by Swift 5.7

// Action with Any Input and Any Output
func main(args: Any) -> Any {
    let newArgs = args as! [String:Any]
    if let name = newArgs["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello stranger!" ]
    }
}
 
// Async Action with Any Input and Any Output
func mainAsync(args: Any) async -> Any {
    do {
        //async code sleep for 1 sec
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let newArgs = args as! [String:Any]
        if let name = newArgs["name"] as? String {
            return [ "greeting" : "Hello \(name)!" ]
        } else {
            return [ "greeting" : "Hello stranger!" ]
        }
    } catch {
        return ["error" : error.localizedDescription]
    }
}

// Async throwing Action with Any Input and Any Output
func mainAsyncThrows(args: Any) async throws -> Any {
    //async code sleep for 1 sec
    try await Task.sleep(nanoseconds: 1_000_000_000)
    
    let newArgs = args as! [String:Any]
    if let name = newArgs["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello stranger!" ]
    }
}

struct Input: Codable {
    let name: String?
}

struct Output: Codable {
    let count: Int
}

// Action with Codable Input and completion with Codable Output and Error
func mainCompletionCodable(input: Input, completion: @escaping (Output?, Error?) -> Void) -> Void {
    if let name = input.name {
        let output = Output(count: name.count)
        completion(output, nil)
    } else {
        let output = Output(count: 0)
        completion(output, nil)
    }
}

// Action with Codable Input and completion with Codable Output and Error
func mainCompletionCodableNoInput(completion: @escaping (Output?, Error?) -> Void) -> Void {
    let output = Output(count: 0)
    completion(output, nil)
}

// Async throwing Action with Codable Output
func mainCodableAsyncThrowsNoInput() async throws -> Output? {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    return Output(count: 0)
}

// Async throwing Action with a Codable Input and a Codable Output
func mainCodableAsyncThrows(input: Input) async throws -> Output? {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    if let name = input.name {
        return Output(count: name.count)
    } else {
        return Output(count: 0)
    }
}

*/
