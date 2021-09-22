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
[![Build Status](https://travis-ci.com/apache/openwhisk-runtime-swift.svg?branch=master)](https://travis-ci.com/apache/openwhisk-runtime-swift)


## Changelogs
- [Swift 5.1   CHANGELOG.md](core/swift51Action/CHANGELOG.md)
- [Swift 5.3   CHANGELOG.md](core/swift53Action/CHANGELOG.md)
- [Swift 5.4   CHANGELOG.md](core/swift54Action/CHANGELOG.md)

## Quick Swift Action
### Simple swift action hello.swift
The traditional support for the dictionary still works:
```swift
import Foundation

func main(args: [String:Any]) -> [String:Any] {
    if let name = args["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello stranger!" ]
    }
}
```

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
```
wsk action update helloCodableAsync helloCodableAsync.swift swift:5.1
```
```
ok: updated action helloCodableAsync
```
```
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
```
wsk action update helloCodableError helloCodableError.swift swift:5.1
```
```
ok: updated action helloCodableError
```
```
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
```
docker run -i openwhisk/action-swift-v5.1 -compile main <main.swift >../action.zip
```

### Compiling Swift 5.1 multiple files with dependencies
Use the docker container and pass a zip archive containing a `Package.swift` and source files a main source file in the location `Sources/main.swift`.
```
zip - -r * | docker run -i openwhisk/action-swift-v5.1 -compile main >../action.zip
```

For more build examples see [here](./examples/)
