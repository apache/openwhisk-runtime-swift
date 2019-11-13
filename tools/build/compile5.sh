#!/bin/bash
RUNTIME="${1:?runtime image1}"
NAME="${2:?action name}"
DIR="${3?target dir}"
pushd "actions/$NAME"
zip -r ../$NAME.zip * 
popd
mkdir -p "build/$DIR"
docker run -i $RUNTIME -compile main <actions/$NAME.zip >build/$DIR/$NAME.zip
