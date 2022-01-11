FROM ubuntu:bionic-20220105 AS base

# Basic dependencies that will be included in final image
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
RUN apt-get update \
    && apt-get install -y \
        apt-transport-https \
        gnupg \
        gosu \
        software-properties-common \
        tzdata

# Install postgres
ENV PG_MAJOR=10
ADD postgres.pub /tmp/postgres.pub
RUN cat /tmp/postgres.pub | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-$PG_MAJOR
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

ENV PLV8_VERSION=3.1.0
# For compatibility with arm64, we need to download source from a specific commit,
# instead of using the tarball for a stable release. See:
# https://github.com/plv8/plv8/issues/444
# https://github.com/JerrySievert/plv8/tree/v3.1
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
    && strip /usr/lib/postgresql/$PG_MAJOR/lib/plv8-$PLV8_VERSION.so
    # && apt-get clean \
    # && apt-get remove -y $buildDependencies \
    # && apt-get autoremove -y \
    # && rm -rf /tmp/build /var/lib/apt/lists/*

ENV PGDATA=/var/lib/postgresql/data
# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /usr/local/bin/
RUN mkdir /docker-entrypoint-initdb.d
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
