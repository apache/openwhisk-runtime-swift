#!/bin/bash
set -e

if [ -z "$1" ] ; then
    echo 'Error: Missing action name'
    exit 1
fi
RUNTIME="action-swift-v3.1.1"

BUILD_FLAGS="-v"
if [ -n "$3" ] ; then
    BUILD_FLAGS=${2}
fi

echo "Using runtime $RUNTIME to compile swift"
docker run --rm --name=compile-ow-swift -it -v "$(pwd):/owexec" $RUNTIME bash -ex -c "

if [ -f \"/owexec/build/$1.zip\" ] ; then
    rm \"/owexec/build/$1.zip\"
fi

echo 'Setting up build...'
cp /owexec/actions/$1/Sources/*.swift /swift3Action/spm-build/

# action file can be either {action name}.swift or main.swift
if [ -f \"/swift3Action/spm-build/$1.swift\" ] ; then
    mv \"/swift3Action/spm-build/$1.swift\" /swift3Action/spm-build/main.swift
fi
# Add in the OW specific bits
cat /swift3Action/epilogue.swift >> /swift3Action/spm-build/main.swift
echo '_run_main(mainFunction:main)' >> /swift3Action/spm-build/main.swift

echo \"Compiling $1...\"
cd /swift3Action/spm-build
if [ -f /owexec/actions/$1/Package.swift ] ; then
    cp /owexec/actions/$1/Package.swift /swift3Action/spm-build/
    echo 'running swift build'
    # we have our own Package.swift, do a full compile
    swift build ${BUILD_FLAGS} -c release
else
    echo 'Running swiftbuildandlink.sh'
    # we are using the stock Package.swift
    /swift3Action/spm-build/swiftbuildandlink.sh
fi


echo 'Creating archive $1.zip...'
mkdir -p /owexec/build
# cd /swift3Action/spm-build
zip \"/owexec/build/$1.zip\" .build/release/Action

"