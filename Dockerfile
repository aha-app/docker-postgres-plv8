FROM ubuntu:focal-20220105 AS base

# This file borrows from https://github.com/docker-library/postgres/blob/master/10/bullseye/Dockerfile
# since this image is intended to be a drop-in replacement. We must use ubuntu instead of debian to support
# building plv8 on arm64 (for the time being). See https://github.com/plv8/plv8/issues/444 for details

# Basic dependencies for package installation
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        gnupg \
        gosu \
        libtinfo5 \
        software-properties-common \
        tzdata && \
    rm -rf /var/lib/apt/lists/*

# explicitly set user/group IDs
RUN set -eux; \
    groupadd -r postgres --gid=999; \
    useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres; \
    mkdir -p /var/lib/postgresql; \
    chown -R postgres:postgres /var/lib/postgresql

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends locales && rm -rf /var/lib/apt/lists/*; \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install postgres
ARG PG_MAJOR
ADD postgres.pub /tmp/postgres.pub
RUN cat /tmp/postgres.pub | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-$PG_MAJOR && \
    rm -rf /var/lib/apt/lists/*
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin \
    PJ_MAJOR=$PJ_MAJOR

# For compatibility with arm64, we need to download source from a specific commit,
# instead of downloading the tarball for a stable release
ARG PLV8_REPO \
    PLV8_REF \
    PLV8_VERSION
ENV PLV8_VERSION=$PLV8_VERSION

RUN buildDependencies=" \
        build-essential \
        ca-certificates \
        git-core \
        libglib2.0-dev \
        ninja-build \
        pkg-config \
        postgresql-server-dev-$PG_MAJOR \
        python3 \
        wget" && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get upgrade -y --no-install-recommends libstdc++6 && \
    apt-get install -y --no-install-recommends $buildDependencies && \
    mkdir -p /tmp/build && \
    git clone $PLV8_REPO /tmp/build/plv8 && \
    cd /tmp/build/plv8 && \
    git checkout $PLV8_REF && \
    make install && \
    strip /usr/lib/postgresql/$PG_MAJOR/lib/plv8-$PLV8_VERSION.so && \
    apt-get clean && \
    apt-get remove -y $buildDependencies && \
    apt-get autoremove -y && \
    rm -rf /tmp/build /var/lib/apt/lists/*

# make the sample config easier to munge (and "correct by default")
RUN set -eux; \
    dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; \
    cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; \
    ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; \
    sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
    grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 2777 /var/run/postgresql

ENV PGDATA=/var/lib/postgresql/data
# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /usr/local/bin/
RUN mkdir /docker-entrypoint-initdb.d
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
