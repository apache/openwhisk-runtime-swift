# Apache OpenWhisk runtimes for swift
[![Build Status](https://travis-ci.org/apache/incubator-openwhisk-runtime-swift.svg?branch=master)](https://travis-ci.org/apache/incubator-openwhisk-runtime-swift)


## Play with Swift 4 and Codable

### Codable Async
Create hello.swift with Codable interface Aysnc:
```swift
// Domain model/entity
struct Employee: Codable {
  let id: Int
  let name: String
}
// codable main async function
func main(input: Employee, respondWith: (Employee?, Error?) -> Void) -> Void {
    respondWith(input, nil)
}
```

Create docker action for swift4
```
bx wsk action update swift4 hello.swift --docker csantanapr/action-swift-v4
```
Invoke the Action
```
bx wsk action invoke swift4 -b
```

### Codable Sync
You can also return a Codable Sync
```swift
// codable main sync function
func main(input: Employee) -> Employee {
    return input
}
```

### Dictionary sync
The traditional support for dictionary still works:
```swift
func main(args: [String:Any]) -> [String:Any] {
    if let name = args["name"] as? String {
        return [ "greeting" : "Hello \(name)!" ]
    } else {
        return [ "greeting" : "Hello swif4!" ]
    }
}
```

### Packaging an action as a Swift executable

When you create an OpenWhisk Swift action with a Swift source file, it has to be compiled into a binary before the action is run. Once done, subsequent calls to the action are much faster until the container holding your action is purged. This delay is known as the cold-start delay.

To avoid the cold-start delay, you can compile your Swift file into a binary and then upload to OpenWhisk in a zip file. As you need the OpenWhisk scaffolding, the easiest way to create the binary is to build it within the same environment as it will be run in. These are the steps:

- Run an interactive Swift action container.
  ```
  docker run --rm -it -v "$(pwd):/owexec" csantanapr/action-swift-v4 bash
  ```
  This puts you in a bash shell within the Docker container.

- Copy the source code and prepare to build it.
  ```
  cp /owexec/hello.swift /swift4Action/spm-build/Sources/Action/main.swift
  ```
  ```
  cat /swift4Action/epilogue.swift >> /swift4Action/spm-build/Sources/Action/main.swift
  ```
  ```
  echo '_run_main(mainFunction:main)' >> /swift4Action/spm-build/main.swift
  ```
  Copy any additional source files to `/swift4Action/spm-build/`


- (Optional) Create the `Package.swift` file to add dependencies.
```swift
// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Action",
    products: [
      .executable(
        name: "Action",
        targets:  ["Action"]
      )
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura-net.git", .upToNextMajor(from: "1.7.19")),
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .upToNextMajor(from: "17.0.0")),
        .package(url: "https://github.com/watson-developer-cloud/swift-sdk.git", .upToNextMajor(from: "0.19.0"))
    ],
    targets: [
      .target(
        name: "Action",
        dependencies: [
          "KituraNet",
          "SwiftyJSON",
          "AlchemyDataNewsV1",
          "AlchemyLanguageV1",
          "AlchemyVisionV1",
          "ConversationV1",
          "DialogV1",
          "DiscoveryV1",
          "DocumentConversionV1",
          "LanguageTranslatorV2",
          "NaturalLanguageClassifierV1",
          "NaturalLanguageUnderstandingV1",
          "PersonalityInsightsV2",
          "PersonalityInsightsV3",
          "RelationshipExtractionV1Beta",
          "RetrieveAndRankV1",
          "ToneAnalyzerV3",
          "TradeoffAnalyticsV1",
          "VisualRecognitionV3"
          ]
      )
    ]
)
```
  As you can see this example adds `watson-developer-cloud` dependencies.
  Notice that `CCurl`, `Kitura-net` and `SwiftyJSON` are provided in the standard Swift action
and so you should include them in your own `Package.swift`.

- Copy Package.swift to spm-build directory
  ```
  cp /owexec/Package.swift /swift4Action/spm-build/Package.swift
  ```

- Change to the spm-build directory.
  ```
  cd /swift4Action/spm-build
  ```

- Compile your Swift Action.
  ```
  swift build -c release
  ```

- Create the zip archive.
  ```
  zip /owexec/hello.zip .build/release/Action
  ```

- Exit the Docker container.
  ```
  exit
  ```

  This has created hello.zip in the same directory as hello.swift.

- Upload it to OpenWhisk with the action name helloSwifty:
  ```
  wsk action update helloSwiftly hello.zip csantanapr/action-swift-v4
  ```

- To check how much faster it is, run
  ```
  wsk action invoke helloSwiftly --blocking
  ```

### Building the Swift4 Image
```
./gradlew core:swift4Action:distDocker
```
This will produce the image `whisk/action-swift-v4`

Build and Push image
```
docker login
./gradlew core:swift4Action:distDocker -PdockerImagePrefix=$prefix-user -PdockerRegistry=docker.io 
```


### Using Swift 3.1.1
To use as a docker action
```
wsk action update myAction myAction.swift --docker openwhisk/action-swift-v3.1.1:1.0.0
```
This works on any deployment of Apache OpenWhisk

### To use on deployment that contains the rutime as a kind
To use as a kind action
```
wsk action update myAction myAction.swift --kind swift:3.1.1
```

### Local development
```
./gradlew core:swiftAction:distDocker
```
This will produce the image `whisk/action-swift-v3.1.1`

Build and Push image
```
docker login
./gradlew core:swiftAction:distDocker -PdockerImagePrefix=$prefix-user -PdockerRegistry=docker.io 
```

Deploy OpenWhisk using ansible environment that contains the kind `swift:3.1.1`
Assuming you have OpenWhisk already deploy localy and `OPENWHISK_HOME` pointing to root directory of OpenWhisk core repository.

Set `ROOTDIR` to the root directory of this repository.

Redeploy OpenWhisk
```
cd $OPENWHISK_HOME/ansible
ANSIBLE_CMD="ansible-playbook -i ${ROOTDIR}/ansible/environments/local"
$ANSIBLE_CMD setup.yml
$ANSIBLE_CMD couchdb.yml
$ANSIBLE_CMD initdb.yml
$ANSIBLE_CMD wipe.yml
$ANSIBLE_CMD openwhisk.yml
```

Or you can use `wskdev` and create a soft link to the target ansible environment, for example:
```
ln -s ${ROOTDIR}/ansible/environments/local ${OPENWHISK_HOME}/ansible/environments/local-swift
wskdev fresh -t local-swift
```

To use as docker action push to your own dockerhub account
```
docker tag whisk/swift8action $user_prefix/action-swift-v3.1.1
docker push $user_prefix/action-swift-v3.1.1
```
Then create the action using your the image from dockerhub
```
wsk action update myAction myAction.swift --docker $user_prefix/action-swift-v3.1.1
```
The `$user_prefix` is usually your dockerhub user id.



# License
[Apache 2.0](LICENSE.txt)


