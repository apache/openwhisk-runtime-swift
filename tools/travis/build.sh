#!/bin/bash
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

set -ex

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
WHISKDIR="$ROOTDIR/../openwhisk"
UTILDIR="$ROOTDIR/../openwhisk-utilities"

export OPENWHISK_HOME=$WHISKDIR

IMAGE_PREFIX="testing"

# run scancode using the ASF Release configuration
cd $UTILDIR
scancode/scanCode.py --config scancode/ASF-Release.cfg $ROOTDIR

# Build OpenWhisk
cd $WHISKDIR

#pull down images
docker pull openwhisk/controller:nightly
docker tag openwhisk/controller:nightly ${IMAGE_PREFIX}/controller
docker pull openwhisk/invoker:nightly
docker tag openwhisk/invoker:nightly ${IMAGE_PREFIX}/invoker
docker pull openwhisk/nodejs6action:nightly
docker tag openwhisk/nodejs6action:nightly nodejs6action

TERM=dumb ./gradlew install

# install new version docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
docker version

# Build runtime
cd $ROOTDIR
TERM=dumb ./gradlew \
:core:swift42Action:distDocker \
:core:swift51Action:distDocker \
:core:swift53Action:distDocker \
-PdockerImagePrefix=${IMAGE_PREFIX}

# Compile test files
cd $ROOTDIR/tests/dat
sh build.sh
