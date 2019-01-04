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
FROM openwhisk/actionloop as builder

FROM swift:4.2

RUN rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get update \
	&& apt-get install -y --no-install-recommends locales python3 vim \
	&& rm -rf /var/lib/apt/lists/* \
	&& locale-gen en_US.UTF-8

ENV LANG="en_US.UTF-8" \
	LANGUAGE="en_US:en" \
	LC_ALL="en_US.UTF-8"

RUN mkdir -p /swiftAction
WORKDIR /swiftAction


COPY --from=builder /bin/proxy /bin/proxy
ADD swiftbuild.py /bin/compile
ADD swiftbuild.py.launcher.swift /bin/compile.launcher.swift
COPY _Whisk.swift /swiftAction/Sources/
COPY Package.swift /swiftAction/
COPY buildandrecord.py /swiftAction/
COPY main.swift /swiftAction/Sources/
RUN swift build -c release; \
touch /swiftAction/Sources/main.swift; \
rm /swiftAction/.build/release/Action; \
/swiftAction/buildandrecord.py


ENV OW_COMPILER=/bin/compile
ENTRYPOINT [ "/bin/proxy" ]
