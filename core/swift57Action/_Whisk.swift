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
import Dispatch
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class Whisk {

    static var baseUrl = ProcessInfo.processInfo.environment["__OW_API_HOST"]
    static var apiKey = ProcessInfo.processInfo.environment["__OW_API_KEY"]
    // This will allow user to modify the default JSONDecoder and JSONEncoder used by epilogue
    static var jsonDecoder = JSONDecoder()
    static var jsonEncoder = JSONEncoder()

    class func invoke(actionNamed action: String, withParameters params: [String: Any], blocking: Bool = true) -> [String: Any] {
        let parsedAction = parseQualifiedName(name: action)
        let strBlocking = blocking ? "true" : "false"
        let path = "/api/v1/namespaces/\(parsedAction.namespace)/actions/\(parsedAction.name)?blocking=\(strBlocking)"
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "POST")
    }

    class func trigger(eventNamed event : String, withParameters params: [String: Any]) -> [String: Any] {
        let parsedEvent = parseQualifiedName(name: event)
        let path = "/api/v1/namespaces/\(parsedEvent.namespace)/triggers/\(parsedEvent.name)?blocking=true"
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "POST")
    }

    class func createTrigger(triggerNamed trigger: String, withParameters params: [String:Any]) -> [String: Any] {
        let parsedTrigger = parseQualifiedName(name: trigger)
        let path = "/api/v1/namespaces/\(parsedTrigger.namespace)/triggers/\(parsedTrigger.name)"
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "PUT")
    }

    class func createRule(ruleNamed ruleName: String, withTrigger triggerName: String, andAction actionName: String) -> [String: Any] {
        let parsedRule = parseQualifiedName(name: ruleName)
        let path = "/api/v1/namespaces/\(parsedRule.namespace)/rules/\(parsedRule.name)"
        let params = ["trigger":triggerName, "action":actionName]
        return sendWhiskRequestSyncronish(uriPath: path, params: params, method: "PUT")
    }

    // handle the GCD dance to make the post async, but then obtain/return
    // the result from this function sync
    private class func sendWhiskRequestSyncronish(uriPath path: String, params: [String: Any], method: String) -> [String: Any] {
        var response : [String: Any]!

        let queue = DispatchQueue.global()
        let invokeGroup = DispatchGroup()

        invokeGroup.enter()
        queue.async {
            postUrlSession(uriPath: path, params: params, method: method, group: invokeGroup) { result in
                response = result
            }
        }

        // On one hand, FOREVER seems like an awfully long time...
        // But on the other hand, I think we can rely on the system to kill this
        // if it exceeds a reasonable execution time.
        switch invokeGroup.wait(timeout: DispatchTime.distantFuture) {
        case DispatchTimeoutResult.success:
            break
        case DispatchTimeoutResult.timedOut:
            break
        }

        return response
    }


    /**
     * Using new UrlSession
     */
    private class func postUrlSession(uriPath: String, params : [String:Any], method: String,group: DispatchGroup, callback : @escaping([String:Any]) -> Void) {

        guard let encodedPath = uriPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            callback(WhiskError.invalidURIPath.body)
            return
        }

        let urlStr = "\(baseUrl!)\(encodedPath)"
        if let url = URL(string: urlStr) {
            var request = URLRequest(url: url)
            request.httpMethod = method

            do {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: params)

                let loginData: Data = apiKey!.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                let base64EncodedAuthKey  = loginData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                request.addValue("Basic \(base64EncodedAuthKey)", forHTTPHeaderField: "Authorization")
                let session = URLSession(configuration: URLSessionConfiguration.default)

                let task = session.dataTask(with: request, completionHandler: {data, response, error -> Void in

                    // exit group after we are done
                    defer {
                        group.leave()
                    }

                    if let error = error {
                        callback(WhiskError.generic(error).body)
                    } else {
                        if let data = data {
                            let decodeReponse = decodeWhiskResponse(data: data)
                            callback(decodeReponse)
                        }
                    }
                })

                task.resume()
            } catch {
                callback(WhiskError.invalidParams(error).body)
            }
        }
    }

    static func invoke(actionNamed action: String, withParameters params: [String: Any], blocking: Bool = true) async throws -> Data {
        let parsedAction = parseQualifiedName(name: action)
        let strBlocking = blocking ? "true" : "false"
        let path = "/api/v1/namespaces/\(parsedAction.namespace)/actions/\(parsedAction.name)?blocking=\(strBlocking)"
        return try await postUrlSession(uriPath: path, params: params, method: "POST")
    }

    static func trigger(eventNamed event: String, withParameters params: [String: Any]) async throws -> Data {
        let parsedEvent = parseQualifiedName(name: event)
        let path = "/api/v1/namespaces/\(parsedEvent.namespace)/triggers/\(parsedEvent.name)?blocking=true"
        return try await postUrlSession(uriPath: path, params: params, method: "POST")
    }

    static func createTrigger(triggerNamed trigger: String, withParameters params : [String:Any]) async throws -> Data {
        let parsedTrigger = parseQualifiedName(name: trigger)
        let path = "/api/v1/namespaces/\(parsedTrigger.namespace)/triggers/\(parsedTrigger.name)"
        return try await postUrlSession(uriPath: path, params: params, method: "PUT")
    }

    static func createRule(ruleNamed ruleName: String, withTrigger triggerName: String, andAction actionName: String) async throws -> Data {
        let parsedRule = parseQualifiedName(name: ruleName)
        let path = "/api/v1/namespaces/\(parsedRule.namespace)/rules/\(parsedRule.name)"
        let params = ["trigger":triggerName, "action":actionName]
        return try await postUrlSession(uriPath: path, params: params, method: "PUT")
    }
        
    private static func postUrlSession(uriPath: String, params : [String:Any], method: String) async throws -> Data {
        
        guard let encodedPath = uriPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            throw WhiskError.invalidURIPath
        }
        
        guard let baseUrl = baseUrl,
              let url = URL(string: "\(baseUrl)\(encodedPath)") else {
            throw WhiskError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        } catch {
            throw WhiskError.invalidParams(error)
        }
    
        guard let loginData: Data = apiKey?.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            throw WhiskError.invalidLogin
        }
        let base64EncodedAuthKey  = loginData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        request.addValue("Basic \(base64EncodedAuthKey)", forHTTPHeaderField: "Authorization")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        return try await session.asyncWhiskData(with: request)
    }
    
    static func decodeWhiskResponse(data: Data) -> [String: Any] {
        do {
            let respJson = try JSONSerialization.jsonObject(with: data)
            if let respJson = respJson as? [String:Any] {
                return respJson
            } else {
                return WhiskError.jsonIsNotDictionary.body
            }
        } catch {
            return WhiskError.invalidJSON(error).body
        }
    }

    // separate an OpenWhisk qualified name (e.g. "/whisk.system/samples/date")
    // into namespace and name components
    private class func parseQualifiedName(name qualifiedName : String) -> (namespace : String, name : String) {
        let defaultNamespace = "_"
        let delimiter = "/"

        let segments :[String] = qualifiedName.components(separatedBy: delimiter)

        if segments.count > 2 {
            return (segments[1], Array(segments[2..<segments.count]).joined(separator: delimiter))
        } else if segments.count == 2 {
            // case "/action" or "package/action"
            let name = qualifiedName.hasPrefix(delimiter) ? segments[1] : segments.joined(separator: delimiter)
            return (defaultNamespace, name)
        } else {
            return (defaultNamespace, segments[0])
        }
    }

}

enum WhiskError: LocalizedError {
    case invalidURIPath
    case generic(Error)
    case invalidURL
    case invalidLogin
    case invalidJSON(Error)
    case invalidParams(Error)
    case jsonIsNotDictionary
    case noData
    
    var errorDescription: String {
        switch self {
        case .noData:
            return ""
        case .generic(let error):
            return error.localizedDescription
        case .invalidURL:
            return "Invalid URL"
        case .invalidJSON(let error):
            return "Error creating json from response: \(error)"
        case .jsonIsNotDictionary:
            return " response from server is not a dictionary"
        case .invalidURIPath:
            return "Error encoding uri path to make openwhisk REST call."
        case .invalidParams(let error):
            return "Got error creating params body: \(error)"
        case .invalidLogin:
            return "Invalid __OW_API_KEY"
        }
    }
    
    var body: [String: String] {
        return ["error": errorDescription]
    }
}

extension URLSession {
    
    // The async version of it, it's not supported
    // See: https://github.com/apple/swift-corelibs-foundation/blob/main/Docs/Status.md#entities
    
    func asyncWhiskData(with request: URLRequest) async throws -> Data {
        let taskResult = await withCheckedContinuation { continuation in
            self.dataTask(with: request) { data, response, error in
                continuation.resume(returning: (data, response, error))
            }.resume()
        }
        if let error = taskResult.2 {
            throw WhiskError.generic(error)
        }
        guard let data = taskResult.0 else {
            throw WhiskError.noData
        }
        return data
    }
}
