FROM centos:7
# version 20.0

# 0) install required packages using yum
RUN yum update -y && yum install -y \
  make \
  gcc \
  gcc-c++ \
  wget \
  build-essential \
  gettext-base \
  git \
  jq \
  curl

# 1) set env (jdk)
ENV JAVA_VERSION    projdk-1.8.0_242
ENV SOURCE_PATH     /usr/local/src

ENV JAVA_HOME       /usr/local/java
ENV JRE_HOME        /usr/local/java
ENV CLASSPATH       .:$JAVA_HOME/lib/tools.jar

ENV PATH            $JAVA_HOME/bin:$PATH

# 2) copy source(jdk) to image
COPY $JAVA_VERSION.tar.gz $SOURCE_PATH/

# 3) set (jdk)symbolic link
RUN set -eux; \
    \
    cd $SOURCE_PATH; \
    #jdk 
    tar -zxvf $JAVA_VERSION.tar.gz; \
    rm -rf $JAVA_VERSION.tar.gz; \
    \
    #symbolick link
    ln -s $SOURCE_PATH/$JAVA_VERSION $JAVA_HOME; 

# 4) copy NodeSource Node.js
COPY ./nodesource.bat /tmp/
COPY ./cf-cli_6.47.2_linux_x86-64.tgz /tmp/

# 5) set NodeSource Node.js and install
RUN cat /tmp/nodesource.bat | bash -
RUN yum install -y nodejs

# 6) install yarn (package manager)
RUN npm install -g yarn

# 7) set command line client for Cloud Foundry
RUN cd /usr/local/bin && \
  mv /tmp/cf-cli_6.47.2_linux_x86-64.tgz /usr/local/bin && \
  tar zxvf cf-cli_6.47.2_linux_x86-64.tgz

# 8) make theia app directory
RUN mkdir /theia-app
ADD package.json /theia-app
WORKDIR /theia-app
# using "NODE_OPTIONS=..." to avoid out-of-memory problem in CI

# 9) set theia plugin path
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/theia-app/plugins

# 10) theia build
RUN yarn --cache-folder ./ycache && rm -rf ./ycache && \
    NODE_OPTIONS="--max_old_space_size=8192" yarn theia build ; \
    yarn theia download:plugins

# 11) add extra plugin
ADD plugins/*.vsix /theia-app/plugins/

ENTRYPOINT [ "yarn",  "theia", "start", "--hostname=0.0.0.0", "/home/project" ]
EXPOSE 3000

