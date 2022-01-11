FROM ubuntu:bionic-20220105 AS base

# Basic dependencies for package installation
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
RUN apt-get update \
    && apt-get install -y \
        apt-transport-https \
        gnupg \
        software-properties-common \
        tzdata

# Install postgres
ENV PG_MAJOR=10
ADD postgres.pub /tmp/postgres.pub
RUN cat /tmp/postgres.pub | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-$PG_MAJOR

# Builds plv8 from source.
# For compatibility with arm64, we need to install from a specific commit,
# not the tarball for a stable release. See:
# https://github.com/plv8/plv8/issues/444
# https://github.com/JerrySievert/plv8/tree/v3.1
ENV PLV8_VERSION=3.1.0
ARG PLV8_REPO="https://github.com/JerrySievert/plv8" \
    PLV8_REF=9937643f8877c89acc0f0af155168fa2580bd42e

RUN buildDependencies=" \
        build-essential \
        ca-certificates \
        git-core \
        libglib2.0-dev \
        libtinfo5 \
        ninja-build \
        pkg-config \
        postgresql-server-dev-$PG_MAJOR \
        python3 \
        wget" \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get upgrade -y libstdc++6 \
    && apt-get install -y $buildDependencies \
    && mkdir -p /tmp/build \
    && git clone $PLV8_REPO /tmp/build/plv8 \
    && cd /tmp/build/plv8 \
    && git checkout $PLV8_REF \
    && make install \
    && strip /usr/lib/postgresql/$PG_MAJOR/lib/plv8-$PLV8_VERSION.so \
    && apt-get clean \
    # && apt-get remove -y $buildDependencies \
    # && apt-get autoremove -y \
    && rm -rf /tmp/build /var/lib/apt/lists/*

# RUN buildDependencies="build-essential \
#      ca-certificates \
#      curl \
#      wget \
#      git-core \
#      python \
#      gpp \
#      cpp \
#      pkg-config \
#      apt-transport-https \
#      cmake \
#      libc++-dev \
#      libc++abi-dev \
#      postgresql-server-dev-$PG_MAJOR" \
#    && apt-get update \
#    && apt-get install -y --no-install-recommends $buildDependencies \
#    && mkdir -p /tmp/build \
#    && git clone https://github.com/JerrySievert/plv8 /tmp/build/plv8 \
#    && cd /tmp/build/plv8 \
#    && git checkout v3.1

# ENV PLV8_VERSION=3.1 \
#     PLV8_SHA=""

# # Based on https://github.com/clkao/docker-postgres-plv8/blob/bd49ae/10-2/Dockerfile
# RUN buildDependencies="build-essential \
#     ca-certificates \
#     curl \
#     git-core \
#     python \
#     gpp \
#     cpp \
#     pkg-config \
#     apt-transport-https \
#     cmake \
#     libc++-dev \
#     postgresql-server-dev-$PG_MAJOR" \
#     runtimeDependencies="libc++1" \
#   && apt-get update \
#   && apt-get install -y --no-install-recommends ${buildDependencies} ${runtimeDependencies} \
#   && mkdir -p /tmp/build \
#   && curl -o /tmp/build/v$PLV8_VERSION.tar.gz -SL "https://github.com/plv8/plv8/archive/v${PLV8_VERSION}.tar.gz" \
#   && cd /tmp/build \
#   && echo $PLV8_SHASUM v$PLV8_VERSION.tar.gz | sha256sum -c \
#   && tar -xzf /tmp/build/v$PLV8_VERSION.tar.gz -C /tmp/build/ \
#   && cd /tmp/build/plv8-$PLV8_VERSION \
#   && make static \
#   && make install \
#   && strip /usr/lib/postgresql/${PG_MAJOR}/lib/plv8-${PLV8_VERSION}.so \
#   && rm -rf /root/.vpython_cipd_cache /root/.vpython-root \
#   && apt-get clean \
#   && apt-get remove -y ${buildDependencies} \
#   && apt-get autoremove -y \
#   && rm -rf /tmp/build /var/lib/apt/lists/*
