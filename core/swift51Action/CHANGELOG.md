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

# Apache OpenWhisk Swift 5.1 Runtime Container

## 1.19.0
 - Upgrade to gradle 6.9.3 (#166)
 - Update go proxy to 1.23@1.25.0 (#165)
 - Update scalafmt plugin version to fix build break (#164)
 - Update async-http-client from 1.13.1 to 1.13.2.

## 1.18.0
 - Build go proxy from runtime-go 1.22.0 (#155)
 - Add Support for Swift 5.7 (#153)
 - Support array result include sequence action (#150)
 - Update to Gradle 6 (#151)
 - Remove Swift 4 support (#145)

## 1.17.0
- Build actionloop from 1.16@1.18.0 (#143)
- Resolve akka versions explicitly. (#141, #139)

## 1.16.0
  - Use 1.17.0 release of openwhisk-runtime-go

## 1.15.0
  - Update Swift 5.1 image to Swift 5.1.5 (#120)
  - Move from golang:1.12 to golang:1.15 to build the runtime proxy (#121)
  - Build proxy from openwhisk-runtime-go 1.16.0 release (#122)

## 1.14.0
 - Initial Release
