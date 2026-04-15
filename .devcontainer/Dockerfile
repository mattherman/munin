FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG JANET_VERSION=1.36.0

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Janet (build from source to support both x64 and arm64)
RUN git clone --depth 1 --branch v${JANET_VERSION} https://github.com/janet-lang/janet.git /tmp/janet \
    && cd /tmp/janet \
    && make \
    && make install \
    && rm -rf /tmp/janet

# Install jpm (Janet Package Manager)
RUN git clone --depth 1 https://github.com/janet-lang/jpm.git /tmp/jpm \
    && cd /tmp/jpm \
    && janet bootstrap.janet \
    && rm -rf /tmp/jpm

# Give vscode user write access to janet lib directory for jpm package caching
RUN chown -R vscode:vscode /usr/local/lib/janet

# Verify installation
RUN janet -v && jpm help
