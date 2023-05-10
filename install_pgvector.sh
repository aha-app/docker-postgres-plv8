#!/bin/bash
set -e

mkdir /tmp/build
cd /tmp/build
curl -o v$PGVECTOR_VERSION.tar.gz -SL https://github.com/pgvector/pgvector/archive/refs/tags/v${PGVECTOR_VERSION}.tar.gz
echo $PGVECTOR_SHASUM v$PGVECTOR_VERSION.tar.gz | sha256sum -c

tar -xzf v$PGVECTOR_VERSION.tar.gz
cd pgvector-$PGVECTOR_VERSION

make
make install

rm -rf /tmp/build /root/.vpython_cipd_cache /root/.vpython-root
