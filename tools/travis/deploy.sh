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

# HACK -- DO NOT MERGE!
# set -ex
set -x
# END HACK -- DO NOT MERGE!

# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../.."
WHISKDIR="$ROOTDIR/../openwhisk"
RUNTIMES_MANIFEST="$ROOTDIR/ansible/files/runtimes.json"

export OPENWHISK_HOME=$WHISKDIR

# Deploy OpenWhisk
cd $WHISKDIR/ansible
ANSIBLE_CMD="ansible-playbook -i environments/local -e runtimes_manifest=$RUNTIMES_MANIFEST -e docker_image_prefix=openwhisk -e docker_image_tag=nightly -e controller_protocol=http"
$ANSIBLE_CMD setup.yml
$ANSIBLE_CMD prereq.yml
$ANSIBLE_CMD couchdb.yml
$ANSIBLE_CMD initdb.yml
$ANSIBLE_CMD wipe.yml
$ANSIBLE_CMD openwhisk.yml -e cli_installation_mode=remote
# HACK -- DO NOT MERGE
docker ps
find /var/tmp -name "*controller0*"
find /var/tmp -name controller0_logs.log -exec cat {} \;

ls "$WHISKDIR/logs"
cat "$WHISKDIR/logs/*"
exit 1
# END HACK
$ANSIBLE_CMD properties.yml
$ANSIBLE_CMD apigateway.yml
$ANSIBLE_CMD routemgmt.yml

docker images
docker ps

cat $WHISKDIR/whisk.properties
curl -s -k https://172.17.0.1 | jq .
curl -s -k https://172.17.0.1/api/v1 | jq .

#Deployment
WHISK_APIHOST="172.17.0.1"
WHISK_AUTH=`cat ${WHISKDIR}/ansible/files/auth.guest`
WHISK_CLI="${WHISKDIR}/bin/wsk -i"

${WHISK_CLI} property set --apihost ${WHISK_APIHOST} --auth ${WHISK_AUTH}
${WHISK_CLI} property get
