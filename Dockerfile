ARG ARCH=amd64
ARG NODE_VERSION=17.6
ARG OS=buster-slim

#### Stage BASE ########################################################################################################
FROM ${ARCH}/node:${NODE_VERSION}-${OS} AS base


# Install tools, create Node-RED app and data dir, add user and set rights
RUN set -ex && \
    apt-get update && apt-get install -y \
        bash \
        tzdata \
        curl \
        nano \
        wget \
        git \
        unzip \ 
        openssl \
        openssh-client \
        ca-certificates && \
    mkdir -p /usr/src/node-red /data && \
    deluser --remove-home node && \
    # adduser --home /usr/src/node-red --disabled-password --no-create-home node-red --uid 1000 && \
    useradd --home-dir /usr/src/node-red --uid 1000 node-red && \
    chown -R node-red:root /data && chmod -R g+rwX /data && \
    chown -R node-red:root /usr/src/node-red && chmod -R g+rwX /usr/src/node-red
    # chown -R node-red:node-red /data && \
    # chown -R node-red:node-red /usr/src/node-red

# Set work directory
WORKDIR /usr/src/node-red

# Setup SSH known_hosts file
# COPY known_hosts.sh .
# RUN ./known_hosts.sh /etc/ssh/ssh_known_hosts && rm /usr/src/node-red/known_hosts.sh

# package.json contains Node-RED NPM module and node dependencies
COPY package.json .
COPY index.js .
COPY flows.json /data
COPY flows.json .

#### Stage BUILD #######################################################################################################
FROM base AS build

# Install Build tools
RUN apt-get update && apt-get install -y build-essential python && \
    npm install --unsafe-perm --no-update-notifier --no-fund --only=production && \
    npm uninstall node-red-node-gpio && \
    cp -R node_modules prod_node_modules

#### Stage RELEASE #####################################################################################################
FROM base AS RELEASE
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG NODE_RED_VERSION
ARG ARCH
ARG TAG_SUFFIX=default

LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile=".docker/Dockerfile.debian" \
    org.label-schema.license="Apache-2.0" \
    org.label-schema.name="Autana-API-Gateway" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="API Gateway for Appwrite" \
    org.label-schema.url="https://autanalabs.com" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/node-red/node-red-docker" \
    org.label-schema.arch=${ARCH} \
    authors="Gilbert Gonzalez"

COPY --from=build /usr/src/node-red/prod_node_modules ./node_modules

# Chown, install devtools & Clean up
RUN chown -R node-red:root /usr/src/node-red && \
    apt-get update && apt-get install -y build-essential python-dev python3 && \
    rm -r /tmp/*

USER node-red

# Env variables
ENV NODE_RED_VERSION=$NODE_RED_VERSION \
    NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules \
    PATH=/usr/src/node-red/node_modules/.bin:${PATH} \
    FLOWS=flows.json \
    AWS_PATH=/usr/local/aws-cli/v2/current/dist/aws \
    NPM_PATH=/usr/local/lib/node_modules/npm/bin/npm-cli.js \
    NODE_PATH=/usr/local/bin/node \
    RUNNER_PATH=/usr/src/node-red/runner

# ENV NODE_RED_ENABLE_SAFE_MODE=true    # Uncomment to enable safe start mode (flows not running)
# ENV NODE_RED_ENABLE_PROJECTS=true     # Uncomment to enable projects option

# Expose the listening port of node-red
EXPOSE 80

# Add a healthcheck (default every 30 secs)
# HEALTHCHECK CMD curl http://localhost:1880/ || exit 1

ENTRYPOINT ["npm", "start", "--cache", "/data/.npm", "--", "--userDir", "/data"]
