<!--
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
-->

# Apache OpenWhisk runtimes for swift
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
[![Continuous Integration](https://github.com/apache/openwhisk-runtime-swift/actions/workflows/ci.yaml/badge.svg)](https://github.com/apache/openwhisk-runtime-swift/actions/workflows/ci.yaml)

## Changelogs
- [Swift 5.1   CHANGELOG.md](core/swift51Action/CHANGELOG.md)
- [Swift 5.3   CHANGELOG.md](core/swift53Action/CHANGELOG.md)
- [Swift 5.4   CHANGELOG.md](core/swift54Action/CHANGELOG.md)
- [Swift 5.7   CHANGELOG.md](core/swift57Action/CHANGELOG.md)

## Quick Swift Action
### Simple swift action hello.swift
The traditional support for the dictionary still works:
```swift
import Foundation

func main(args: Any) -> Any {
    let dict = args as! [String:Any]
    if let name = dict["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello stranger!" ]
    }
}
```

For the return result, not only support `dictionary`, but also support `array`

So a very simple `hello array` function would be:

```swift
func main(args: Any) -> Any {
    var arr = ["a", "b"]
    return arr
}
```

And support array result for sequence action as well, the first action's array result can be used as next action's input parameter.

So the function can be:

```swift
 func main(args: Any) -> Any {
     return args
 }
```
When invoking the above action, we can pass an array object as the input parameter.

## Swift 5.x support

Some examples of using Codable In and Out
### Codable style function signature
Create file `helloCodableAsync.swift`
```swift

import Foundation

// Domain model/entity
struct Employee: Codable {
  let id: Int?
  let name: String?
}
// codable main function
func main(input: Employee, respondWith: (Employee?, Error?) -> Void) -> Void {
    // For simplicity, just passing same Employee instance forward
    respondWith(input, nil)
}
```
```bash
wsk action update helloCodableAsync helloCodableAsync.swift swift:5.1
```
```bash
ok: updated action helloCodableAsync
```
```bash
wsk action invoke helloCodableAsync -r -p id 73 -p name Andrea
```
```json
{
    "id": 73,
    "name": "Andrea"
}
```

### Codable Error Handling
Create file `helloCodableAsync.swift`
```swift

import Foundation

struct Employee: Codable {
    let id: Int?
    let name: String?
}
enum VendingMachineError: Error {
    case invalidSelection
    case insufficientFunds(coinsNeeded: Int)
    case outOfStock
}
func main(input: Employee, respondWith: (Employee?, Error?) -> Void) -> Void {
    // Return real error
    do {
        throw VendingMachineError.insufficientFunds(coinsNeeded: 5)
    } catch {
        respondWith(nil, error)
    }
}
```
```bash
wsk action update helloCodableError helloCodableError.swift swift:5.1
```
```bash
ok: updated action helloCodableError
```
```bash
wsk action invoke helloCodableError -b -p id 51 -p name Carlos
```
```json
{
  "name": "helloCodableError",
  "response": {
    "result": {
      "error": "insufficientFunds(5)"
    },
    "status": "application error",
    "success": false
  }
}
```

## Packaging an action as a Swift executable using Swift 5.x

When you create an OpenWhisk Swift action with a Swift source file, it has to be compiled into a binary before the action is run. Once done, subsequent calls to the action are much faster until the container holding your action is purged. This delay is known as the cold-start delay.

To avoid the cold-start delay, you can compile your Swift file into a binary and then upload to OpenWhisk in a zip file. As you need the OpenWhisk scaffolding, the easiest way to create the binary is to build it within the same environment as it will be run in.

### Compiling Swift 5.x

### Compiling Swift 5.x single file

Use the docker container and pass the single source file as stdin.
Pass the name of the method to the flag `-compile`
```bash
docker run -i openwhisk/action-swift-v5.1 -compile main <main.swift >../action.zip
```

### Compiling Swift 5.1 multiple files with dependencies
Use the docker container and pass a zip archive containing a `Package.swift` and source files a main source file in the location `Sources/main.swift`.
```bash
zip - -r * | docker run -i openwhisk/action-swift-v5.1 -compile main >../action.zip
```

For more build examples see [here](./examples/)

# Swift 5.7

In addition to previous ways of defining an action is now possible to use throwing async/await inside the action.

### Async throwing Action with Any Input and Any Output

```swift
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

### Async throwing Action with a Codable Input and a Codable Output

```swift
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

### Async throwing Action with Codable Output

```swift
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


### Example of an async throwing Action with a Codable Input and a Codable Output

In the following example, the main action decodes the URL from `AnInput`, downloads the content from the URL, decodes the JSON and returns the `response` in `AnOutput`.
In case of failure, the runtime will return an error.

```swift
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
```

The full swift package is [here](/tests/dat/actions/SwiftyRequestAsyncCodable57/).

Note that the package of this action contains a dependency from `AsynHTTPClient`, in such case, it's preferred to build the action.

```shell
zip - -r * | docker run -i openwhisk/action-swift-v5.7 -compile main >../action.zip
```
