#!/bin/bash
set -e

mkdir /tmp/build
cd /tmp/build
curl -o v$PLV8_VERSION.tar.gz -SL "https://github.com/plv8/plv8/archive/v${PLV8_VERSION}.tar.gz"
echo $PLV8_SHASUM v$PLV8_VERSION.tar.gz | sha256sum -c

tar -xzf v$PLV8_VERSION.tar.gz
cd plv8-$PLV8_VERSION

make
make install

rm -rf /tmp/build /root/.vpython_cipd_cache /root/.vpython-root
