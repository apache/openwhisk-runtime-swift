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

import AsyncHTTPClient
import Foundation
import _Concurrency
import NIOCore
import NIOFoundationCompat

enum RequestError: Error {
    case requestError
}
struct AnInput: Codable {
    let url: String?
}

struct AnOutput: Codable {
    let args: [String: String]
    let headers: [String: String]
    let origin: String
    let url: String
}

let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
let decoder = JSONDecoder()

func main(param: AnInput) async throws -> AnOutput {

    let echoURL = param.url ?? "https://httpbin.org/get"
    let request = HTTPClientRequest(url: echoURL)
    let response = try await httpClient.execute(request, timeout: .seconds(3))
    if response.status == .ok {
        let bytes = try await response.body.collect(upTo: 1024 * 1024) // 1 MB Buffer
        let data = Data(buffer: bytes)
        return try decoder.decode(AnOutput.self, from: data)
    } else {
        throw RequestError.requestError
    }
}
