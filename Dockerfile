FROM debian:stable-slim AS builder

ARG BRANCH=release-4.13.0

ENV BUILD_PKGS \
    build-essential \
    autoconf \
    libevent-dev \
    libssl-dev \
    protobuf-compiler \
    protobuf-c-compiler \
    libprotobuf-c-dev \
    libfstrm-dev \
    bison \
    flex \
    curl \
    jq \
    git

    # Install dependencies
RUN apt-get update && \
    apt-get install -yqq ${BUILD_PKGS}

# Fetch source
RUN git clone https://github.com/nlnetLabs/nsd /src/nsd
WORKDIR /src/nsd
RUN git checkout -b ${BRANCH}
RUN git submodule update --init

# Build the project
RUN autoreconf --install && \
    ./configure --with-configdir=/config --localstatedir=/storage --enable-root-server && \
    make && \
    make DESTDIR=/tmp/nsd-install install

# Save result
RUN tar cvzfC /nsd.tar.gz /tmp/nsd-install usr/local config storage


FROM debian:stable-slim

# Environment
ENV RUNTIME_PKGS \
    procps \
    openssl \
    libssl3 \
    libevent-2.1 \
    libprotobuf-c1 \
    libfstrm-dev

# Copy artifacts
COPY --from=builder /nsd.tar.gz /tmp
RUN tar xvzpf /tmp/nsd.tar.gz
RUN rm -f /tmp/nsd.tar.gz

# Install dependencies and create nsd user and group
ARG UID=53
RUN apt-get update && \
    apt-get install -yqq ${RUNTIME_PKGS} && \
    rm -rf /var/lib/apt/lists/* && \
    ldconfig && \
    useradd --system --user-group -M --home /storage --uid ${UID} nsd && \
    install -d -o nsd -g nsd /config /storage && \
    chown -R nsd:nsd /config /storage

# Add default config
ADD nsd.conf /config

# Add entrypoint
ADD entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]

# Expose port
EXPOSE 53/udp
EXPOSE 53/tcp
EXPOSE 853/tcp

# Prepare shared directories
VOLUME /config
VOLUME /storage
