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

# Dockerfile for swift actions, overrides and extends ActionRunner from actionProxy
# This Dockerfile is partially based on: https://github.com/IBM-Swift/swift-ubuntu-docker/blob/master/swift-development/Dockerfile
FROM ibmcom/swift-ubuntu:3.1.1

# Set WORKDIR
WORKDIR /

# Upgrade and install basic Python dependencies
RUN apt-get -y update \
 && apt-get -y install --fix-missing python2.7 python-gevent python-flask zip

# Add the action proxy
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-docker/dockerskeleton%401.3.3/core/actionProxy/actionproxy.py /actionProxy/actionproxy.py

# Add files needed to build and run action
RUN mkdir -p /swift3Action
ADD epilogue.swift /swift3Action
ADD buildandrecord.py /swift3Action
ADD swift3runner.py /swift3Action
ADD spm-build /swift3Action/spm-build


# Build kitura net
RUN touch /swift3Action/spm-build/main.swift
RUN python /swift3Action/buildandrecord.py && rm /swift3Action/spm-build/.build/release/Action
#RUN cd /swift3Action/spm-build; swift build -v -c release; rm /swift3Action/spm-build/.build/release/Action
ENV FLASK_PROXY_PORT 8080

CMD ["/bin/bash", "-c", "cd /swift3Action && PYTHONIOENCODING='utf-8' python -u swift3runner.py"]
