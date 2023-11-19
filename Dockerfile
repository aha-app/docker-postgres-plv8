# Based on https://github.com/clkao/docker-postgres-plv8/blob/bd49ae/10-2/Dockerfile
FROM postgres:14.7

# RDS for Postgres 14.X only supports PLV8 2.3.15, but we can't get that version to build.
ENV PLV8_VERSION=3.1.2
ENV PLV8_SHASUM="4988089380e5f79f7315193dbd4df334da9899caf7ef78ed1ea7709712327208"

RUN apt-get update
RUN apt-get install --yes --no-install-recommends\
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    git-core \
    libc++-dev \
    libc++1 \
    libc++abi-dev \
    libglib2.0-dev \
    libtinfo5 \
    ninja-build \
    pkg-config \
    postgresql-server-dev-$PG_MAJOR \
    python \
    wget

# Set the locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && update-locale LC_ALL=en_US.UTF-8

COPY install_plv8.sh .
RUN bash install_plv8.sh
