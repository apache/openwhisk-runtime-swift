#!/bin/bash
set -e

../../tools/build/compile.sh  HelloSwift3 swift:3.1.1 "-v"

../../tools/build/compile.sh  HelloSwift4 swift:4.1 "-v"
../../tools/build/compile.sh  SwiftyRequest swift:4.1 "-v"
../../tools/build/compile.sh  SwiftyRequestCodable swift:4.1 "-v"
../../tools/build/compile.sh  HelloSwift4Codable swift:4.1 "-v"
