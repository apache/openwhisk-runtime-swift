#!/bin/bash

set -ex

# IBM Cloud Functions
#OW_CLI="bx wsk"
#OW_KIND="--docker csantanapr/action-swift-v4"


# Local OpenWhisk
OW_CLI="wsk -i"
OW_KIND="--kind swift:4"


cat helloDictionarySync.swift
echo
${OW_CLI} action update helloDictionarySync helloDictionarySync.swift ${OW_KIND}
${OW_CLI} action invoke helloDictionarySync -r -p id 42 -p name Carlos

cat helloCodableSync.swift
echo
${OW_CLI} action update helloCodableSync helloCodableSync.swift ${OW_KIND}
${OW_CLI} action invoke helloCodableSync -r -p id 42 -p name Carlos

cat helloCodableAsync.swift
echo
${OW_CLI} action update helloCodableAsync helloCodableAsync.swift ${OW_KIND}
${OW_CLI} action invoke helloCodableAsync -r -p id 42 -p name Carlos

echo