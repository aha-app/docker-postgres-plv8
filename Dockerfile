FROM postgres:14.1

ENV PLV8_VERSION=3.1.2
ENV PLV8_SHASUM="4988089380e5f79f7315193dbd4df334da9899caf7ef78ed1ea7709712327208"

# Based on https://github.com/clkao/docker-postgres-plv8/blob/bd49ae/10-2/Dockerfile
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

# We need binutil version >= 2.38 due to a bug that prevents plv8 from compiling. This can be removed once the Debian stable repo catches up.
COPY testing.list /etc/apt/sources.list.d/
RUN echo "APT::Default-Release \"stable\";" > /etc/apt/apt.conf.d/default-release
RUN apt-get update
RUN apt-get install --yes --no-install-recommends --target-release testing binutils

COPY install_plv8.sh .
RUN bash install_plv8.sh
