# Dockerfile for swift actions, overrides and extends ActionRunner from actionProxy
# This Dockerfile is partially based on: https://github.com/IBM-Swift/swift-ubuntu-docker/blob/master/swift-development/Dockerfile
FROM ibmcom/swift-ubuntu:4.0.3

# Set WORKDIR
WORKDIR /

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