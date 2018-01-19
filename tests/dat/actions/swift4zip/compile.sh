#!/bin/bash
set -e

if [ -z "$1" ] ; then
    echo 'Error: Missing action name'
    exit 1
fi
RUNTIME="action-swift-v4"

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
cp /owexec/actions/$1/Sources/*.swift /swift4Action/spm-build/Sources/Action/

# action file can be either {action name}.swift or main.swift
ls /swift4Action/spm-build/Sources/Action/
if [ -f \"/swift4Action/spm-build/Sources/Action/$1.swift\" ] ; then
    echo 'renaming $1.swift to main.swift'
    mv \"/swift4Action/spm-build/Sources/Action/$1.swift\" /swift4Action/spm-build/Sources/Action/main.swift
fi
# Add in the OW specific bits
cat /swift4Action/epilogue.swift >> /swift4Action/spm-build/Sources/Action/main.swift
echo '_run_main(mainFunction:main)' >> /swift4Action/spm-build/Sources/Action/main.swift

echo \"Compiling $1...\"
cd /swift4Action/spm-build
if [ -f /owexec/actions/$1/Package.swift ] ; then
    cp /owexec/actions/$1/Package.swift /swift4Action/spm-build/
    echo 'running swift build'
    # we have our own Package.swift, do a full compile
    swift build ${BUILD_FLAGS} -c release
else
    echo 'Running swiftbuildandlink.sh'
    # we are using the stock Package.swift
    /swift4Action/spm-build/swiftbuildandlink.sh
fi


echo 'Creating archive $1.zip...'
mkdir -p /owexec/build
# cd /swift4Action/spm-build
zip \"/owexec/build/$1.zip\" .build/release/Action /owexec/compile.sh

"