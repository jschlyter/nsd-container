FROM debian:bookworm-slim

ENV BUILD_PKGS \
    build-essential \
    autoconf \
    libevent-dev \
    libssl-dev \
    bison \
    flex \
    curl \
    jq

# Install dependencies
RUN apt-get update && \
    apt-get install -yqq ${BUILD_PKGS}

# Fetch source
WORKDIR /nsd-src
RUN curl -L `curl -s https://api.github.com/repos/nlnetlabs/nsd/releases/latest | jq -r .tarball_url` | tar --strip-components 1 -xzf -

# Build the project
RUN autoreconf --install && \
    ./configure --with-configdir=/config --localstatedir=/storage && \
    make && \
    make DESTDIR=/tmp/nsd-install install

# Save result
RUN tar cvzfC /nsd.tar.gz /tmp/nsd-install usr/local config storage


FROM debian:bookworm-slim

# Environment
ENV RUNTIME_PKGS \
    procps \
    openssl \
    libssl3 \
    libevent-2.1

# Copy artifacts
COPY --from=0 /nsd.tar.gz /tmp
RUN tar xvzpf /tmp/nsd.tar.gz
RUN rm -f /tmp/nsd.tar.gz

# Install dependencies and create nsd user and group
ARG UID=53
RUN apt-get update && \
    apt-get install -yqq ${RUNTIME_PKGS} && \
    rm -rf /var/lib/apt/lists/* && \
    ldconfig && \
    adduser --quiet --system --group --no-create-home --home /storage --uid=${UID} nsd && \
    install -d -o nsd -g nsd /config /storage && \
    chown -R nsd:nsd /config /storage

# Add default config
ADD nsd.conf /config

# Add entrypoint
ADD entrypoint.sh /
ENTRYPOINT bash /entrypoint.sh

# Expose port
EXPOSE 53/UDP
EXPOSE 53/TCP

# Prepare shared directories
VOLUME /config
VOLUME /storage
