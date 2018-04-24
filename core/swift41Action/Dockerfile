#
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.  The ASF licenses this file to you
# under the Apache License, Version 2.0 (the # "License"); you may not use this
# file except in compliance with the License.  You may obtain a copy of the License
# at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#

# TODO Replace this dockerfile and extend from official image when 4.1 is released
FROM ibmcom/ubuntu:14.04
LABEL Description="Linux Ubuntu 14.04 image with the Swift binaries and tools."

USER root

# Set environment variables for image
# Using git hash https://github.com/apple/swift/commit/f01501c324876fc07820dc28923d7088fb7af847
ENV SWIFT_SNAPSHOT swift-4.1-RELEASE
ENV SWIFT_SNAPSHOT_LOWERCASE swift-4.1-release
ENV UBUNTU_VERSION ubuntu14.04
ENV UBUNTU_VERSION_NO_DOTS ubuntu1404
ENV WORK_DIR /

# Set WORKDIR
WORKDIR ${WORK_DIR}

# Linux OS utils and libraries and set clang 3.8 as default
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
  build-essential \
  clang-3.8 \
  git \
  libpython2.7 \
  libicu-dev \
  wget \
  libcurl4-openssl-dev \
  vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && update-alternatives --quiet --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100 \
  && update-alternatives --quiet --install /usr/bin/clang clang /usr/bin/clang-3.8 100 \
  && echo "set -o vi" >> /root/.bashrc

# Install Swift compiler
RUN wget https://swift.org/builds/$SWIFT_SNAPSHOT_LOWERCASE/$UBUNTU_VERSION_NO_DOTS/$SWIFT_SNAPSHOT/$SWIFT_SNAPSHOT-$UBUNTU_VERSION.tar.gz \
    https://swift.org/builds/$SWIFT_SNAPSHOT_LOWERCASE/$UBUNTU_VERSION_NO_DOTS/$SWIFT_SNAPSHOT/$SWIFT_SNAPSHOT-$UBUNTU_VERSION.tar.gz.sig \
  && gpg --keyserver hkp://pool.sks-keyservers.net \
      --recv-keys \
      '7463 A81A 4B2E EA1B 551F  FBCF D441 C977 412B 37AD' \
      '1BE1 E29A 084C B305 F397  D62A 9F59 7F4D 21A5 6D5F' \
      'A3BA FD35 56A5 9079 C068  94BD 63BC 1CFE 91D3 06C6' \
      '5E4D F843 FB06 5D7F 7E24  FBA2 EF54 30F0 71E1 B235' \
      '8513 444E 2DA3 6B7C 1659  AF4D 7638 F1FB 2B2B 08C4' \
  && gpg --keyserver hkp://pool.sks-keyservers.net --refresh-keys  \
  && gpg --verify $SWIFT_SNAPSHOT-$UBUNTU_VERSION.tar.gz.sig \
  && tar xzvf $SWIFT_SNAPSHOT-$UBUNTU_VERSION.tar.gz --strip-components=1 \
  && rm $SWIFT_SNAPSHOT-$UBUNTU_VERSION.tar.gz \
  && rm $SWIFT_SNAPSHOT-$UBUNTU_VERSION.tar.gz.sig \
  && chmod -R go+r /usr/lib/swift \
  && swift --version


# Upgrade and install basic Python dependencies
RUN apt-get -y update \
 && apt-get -y install --fix-missing python2.7 python-gevent python-flask zip

# Add the action proxy
ADD https://raw.githubusercontent.com/apache/incubator-openwhisk-runtime-docker/dockerskeleton%401.1.0/core/actionProxy/actionproxy.py /actionProxy/actionproxy.py

# Add files needed to build and run action
RUN mkdir -p /swift4Action/spm-build/Sources/Action
ADD epilogue.swift /swift4Action
ADD buildandrecord.py /swift4Action
ADD swift4runner.py /swift4Action
ADD spm-build/Package.swift /swift4Action/spm-build
ADD spm-build/_Whisk.swift /swift4Action/spm-build/Sources/Action


# Build
RUN touch /swift4Action/spm-build/Sources/Action/main.swift
RUN python /swift4Action/buildandrecord.py && rm /swift4Action/spm-build/.build/release/Action
#RUN cd /swift4Action/spm-build; swift build -v -c release; rm /swift4Action/spm-build/.build/release/Action
ENV FLASK_PROXY_PORT 8080
EXPOSE 8080

CMD ["/bin/bash", "-c", "cd /swift4Action && PYTHONIOENCODING='utf-8' python -u swift4runner.py"]
