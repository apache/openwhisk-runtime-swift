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

OW_USER?=whisk
OW_COMPILER?=$(OW_USER)/action-swift-v5.7
OUT?=../../build/swift5.7
define Build
	cd $(1); \
	docker run -i $(OW_COMPILER) -compile main <./Sources/main.swift >$(OUT)/$(1).zip
endef

define BuildWithLib
	cd $(1); \
	sed -i.bak 's/4.0/4.2/' Package.swift; \
	zip - -r Package.swift Sources/main.swift | docker run -i $(OW_COMPILER) -compile main >$(OUT)/$(1).zip; \
	mv Package.swift.bak Package.swift
endef

Swifty:
	$(call BuildWithLib,SwiftyRequest)

SwiftyCodable:
	$(call BuildWithLib,SwiftyRequestCodable)

Hello5:
	$(call Build,HelloSwift5)

HelloCodable5:
	$(call Build,HelloSwift5Codable)

Swifty5:
	$(call BuildWithLib,SwiftyRequest5)

SwiftyCodable5:
	$(call BuildWithLib,SwiftyRequestCodable5)

SwiftyCodable57:
	$(call BuildWithLib,SwiftyRequestCodable57)

all: Hello HelloCodable Swifty SwiftyCodable Hello5 HelloCodable5 Swifty5 SwiftyCodable5

.PHONY: Hello HelloCodable Swifty SwiftyCodable Hello5 HelloCodable5 Swifty5 SwiftyCodable5
