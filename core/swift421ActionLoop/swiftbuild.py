#!/usr/bin/env python3
"""Swift Action Compiler
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
"""

from __future__ import print_function
import os
import re
import sys
import codecs
import subprocess
from io import StringIO

package_swift = """// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "exec",
    dependencies: [],
    targets: [
      .target(
        name: "exec",
        dependencies: [])
    ]
)
"""
output = StringIO()

def eprint(*args, **kwargs):
    print(*args, file=output, **kwargs)

def sources(launcher, source_dir, main):
    # create Packages.swift
    packagefile = "%s/Package.swift" % source_dir
    if not os.path.isfile(packagefile):
        with codecs.open(packagefile, 'w', 'utf-8') as s:
            s.write(package_swift)

    # create Sources/Action dir
    actiondir = "%s/Sources/exec" % source_dir
    if not os.path.isdir(actiondir):
        os.makedirs(actiondir, mode=0o755)

    # copy the exec to exec.go
    # also check if it has a main in it
    src = "%s/exec" % source_dir
    dst = "%s/exec.swift" % actiondir
    if os.path.isfile(src):
        with codecs.open(src, 'r', 'utf-8') as s:
            with codecs.open(dst, 'w', 'utf-8') as d:
                body = s.read()
                d.write(body)

    # copy the launcher fixing the main
    dst = "%s/main.swift" % actiondir
    with codecs.open(dst, 'w', 'utf-8') as d:
        with codecs.open(launcher, 'r', 'utf-8') as e:
            code = e.read()
            code += "_run_main(mainFunction: %s)\n" % main
            d.write(code)

def swift_build(dir, extra_args=[]):
    base_args =  ["swift", "build", "--package-path", dir,  "-c", "release"]
    # compile...
    env = {
      "PATH": os.environ["PATH"]
    }
    p = subprocess.Popen(base_args+extra_args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=dir,
        env=env)
    (o, e) = p.communicate()
    # stdout/stderr may be either text or bytes, depending on Python
    # version, so if bytes, decode to text. Note that in Python 2
    # a string will match both types; so also skip decoding in that case
    if isinstance(o, bytes) and not isinstance(o, str):
        o = o.decode('utf-8')
    if isinstance(e, bytes) and not isinstance(e, str):
        e = e.decode('utf-8')
    return p.returncode, o, e

def build(source_dir, target_file):
    r, o, e = swift_build(source_dir)
    if e: eprint(e)
    if o: eprint(o)
    if r != 0:
        print(output.getvalue())
        return

    r, o, e = swift_build(source_dir, ["--show-bin-path"])
    if e: eprint(e)
    if r != 0:
        print(output.getvalue())
        return

    bin_file = "%s/exec" % o.strip()
    os.rename(bin_file, target_file)
    if not os.path.isfile(target_file):
        eprint("failed %s -> %s" % (bin_file, target_file))
        print(output.getvalue())
        return


def main(argv):
    if len(argv) < 4:
        print("usage: <main-function> <source-dir> <target-dir>")
        sys.exit(1)

    main = argv[1]
    source_dir = os.path.abspath(argv[2])
    target = os.path.abspath("%s/exec" % argv[3])
    launch = os.path.abspath(argv[0]+".launcher.swift")
    sources(launch, source_dir, main)
    build(source_dir, target)

if __name__ == '__main__':
    main(sys.argv)
