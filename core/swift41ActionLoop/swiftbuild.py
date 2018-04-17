#!/usr/bin/python
"""Swift Action Compiler

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
"""
import os
import os.path
import glob
import sys
import subprocess
import codecs
import json
import shutil 

SRC_EPILOGUE_FILE = '/swift4Action/epilogue.swift'
DEST_SCRIPT_FILE = '/swift4Action/spm-build/Sources/Action/main.swift'
DEST_SCRIPT_SRC = '/swift4Action/spm-build/Sources/Action'
DEST_SCRIPT_DIR = '/swift4Action/spm-build'
DEST_BIN_FILE = '/swift4Action/spm-build/.build/release/Action'

BUILD_PROCESS = ['./swiftbuildandlink.sh']

def epilogue(main_function):
    # make sure there is a main.swift file
    open(DEST_SCRIPT_FILE, 'a').close()

    with codecs.open(DEST_SCRIPT_FILE, 'a', 'utf-8') as fp:
        os.chdir(DEST_SCRIPT_DIR)
        for file in glob.glob("*.swift"):
            if file not in ["Package.swift", "main.swift", "_WhiskJSONUtils.swift", "_Whisk.swift"]:
                print("concat "+file)
                with codecs.open(file, 'r', 'utf-8') as f:
                    fp.write(f.read())
        with codecs.open(SRC_EPILOGUE_FILE, 'r', 'utf-8') as ep:
            print("concat "+SRC_EPILOGUE_FILE)
            fp.write(ep.read())

        fp.write('_run_main(mainFunction: %s)\n' % main_function)

def build():

    p = subprocess.Popen(
        BUILD_PROCESS,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=DEST_SCRIPT_DIR)

    # run the process and wait until it completes.
    # stdout/stderr will not be None because we passed PIPEs to Popen
    (o, e) = p.communicate()

    # stdout/stderr may be either text or bytes, depending on Python
    # version, so if bytes, decode to text. Note that in Python 2
    # a string will match both types; so also skip decoding in that case
    if isinstance(o, bytes) and not isinstance(o, str):
        o = o.decode('utf-8')
    if isinstance(e, bytes) and not isinstance(e, str):
        e = e.decode('utf-8')

    if o:
        sys.stdout.write(o)
        sys.stdout.flush()

    if e:
        sys.stderr.write(e)
        sys.stderr.flush()


def collect(source):
    # copy file
    if os.path.isfile(source):
      print "copying "+source
      shutil.copyfile(source, DEST_SCRIPT_FILE)
      return os.path.dirname(source)

    # collect sources in a single main
    if os.path.isdir(source):
        with codecs.open(DEST_SCRIPT_FILE, 'a', 'utf-8') as fp:
            for file in glob.glob(source+"/*.swift"):
                print "contact "+file
                with codecs.open(file, 'r', 'utf-8') as f:
                    fp.write(f.read())
        return source
    
    print "cannot read "+source
    sys.exit(1)

def main(argv):
    if len(argv) == 1:
        print("usage: <source< [<main>] [<target>]\n<main> defaults to 'main'\n<target> must be a dir\n")
        sys.exit(1)

    # collect args
    source = argv[1]
    main = "main"
    target = ""
    if len(argv) > 2:
        main = argv[2]  
    if len(argv) > 3:
        target = argv[3]  

  
    # build
    sourcedir = collect(source)
    os.chdir(DEST_SCRIPT_DIR)
    epilogue(main)
    build()
    
    # copy to target
    if target != "" and os.path.isdir(target):
        dest = target+ "/" + main
    else:
        dest = sourcedir + "/" + main
    
    shutil.copyfile(DEST_BIN_FILE, dest)
    os.chmod(dest, 0o755)

if __name__ == '__main__':
    main(sys.argv)
