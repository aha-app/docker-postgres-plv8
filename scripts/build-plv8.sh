#!/usr/bin/env bash

set -eux

PLV8_VERSION="3.1.0"
PLV8_REPO="https://github.com/JerrySievert/plv8"
PLV8_REF="9937643f8877c89acc0f0af155168fa2580bd42e"
PYTHON_PKG=python3

buildDependencies=" \
        build-essential \
        ca-certificates \
        git-core \
        libglib2.0-dev \
        ninja-build \
        pkg-config \
        postgresql-server-dev-$PG_MAJOR \
        $PYTHON_PKG \
        software-properties-common \
        wget"

apt-get update
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository ppa:ubuntu-toolchain-r/test
apt-get update
apt-get upgrade -y --no-install-recommends libstdc++6
apt-get install -y --no-install-recommends $buildDependencies

mkdir -p /tmp/build
git clone --no-checkout $PLV8_REPO /tmp/build/plv8-$PLV8_VERSION
cd /tmp/build/plv8-$PLV8_VERSION
git checkout $PLV8_REF
make install

strip /usr/lib/postgresql/$PG_MAJOR/lib/plv8-$PLV8_VERSION.so
apt-get clean
apt-get remove -y $buildDependencies
apt-get autoremove -y
rm -rf /tmp/build /var/lib/apt/lists/*
