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
OW_RUNTIME?=$(OW_USER)/action-swift-v5.7
OW_COMPILER?=$(OW_USER)/action-swift-v5.7
WSK?=wsk -i
MAIN=main
PACKAGE=test
SRCS=HelloSwift5/Sources/$(MAIN).swift HelloSwift5/Package.swift
NAME=swift-$(MAIN)-zip
BINZIP=$(MAIN)-bin.zip
SRCZIP=$(MAIN)-src.zip

deploy: package.done $(BINZIP)
	$(WSK) action update $(PACKAGE)/$(NAME) $(BINZIP) --main $(MAIN) --docker $(OW_RUNTIME)

devel: package.done $(SRCZIP)
	$(WSK) action update $(PACKAGE)/$(NAME) $(SRCZIP) --main $(MAIN) --docker $(OW_COMPILER)

$(BINZIP): $(SRCS)
	cd HelloSwift5 ; zip - -r * | docker run -i $(OW_COMPILER) -compile $(MAIN) >../$(BINZIP)

$(SRCZIP): $(SRCS)
	cd HelloSwift5 ; zip ../$(SRCZIP) -r *

clean:
	-$(WSK) action delete $(PACKAGE)/$(NAME)
	-rm  $(BINZIP) $(SRCZIP) package.done test.json

test: test.json
	$(WSK) action invoke test/$(NAME) -r
	$(WSK) action invoke test/$(NAME) -P test.json -r

test.json:
	echo '{ "name": "Mike" }' >test.json

package.done:
	$(WSK) package update $(PACKAGE)
	touch package.done

.PHONY: deploy devel test clean
