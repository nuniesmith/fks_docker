# Shared Builder Base Image for FKS Services
# This image contains common build dependencies that multiple services need:
# - TA-Lib C library (compiled)
# - Common build tools (gcc, g++, make, cmake, etc.)
# - Python build dependencies
#
# Usage:
#   docker build -t nuniesmith/fks:builder-base -f docker-base/Dockerfile.builder .
#   docker push nuniesmith/fks:builder-base
#
# Then services can use: FROM nuniesmith/fks:builder-base AS builder

FROM python:3.12-slim AS builder-base

WORKDIR /app

# Install all common build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    gfortran \
    make \
    wget \
    curl \
    cmake \
    git \
    pkg-config \
    libffi-dev \
    libssl-dev \
    build-essential \
    autoconf \
    automake \
    libtool \
    libc-bin \
    file \
    binutils \
    libopenblas-dev \
    liblapack-dev \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Upgrade pip, setuptools, and wheel
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --upgrade pip setuptools wheel

# Install TA-Lib C library (compiled and ready to use)
# This is the most time-consuming part, so we do it once in the base image
RUN set -e; \
    echo "=== Downloading TA-Lib ==="; \
    TA_LIB_DOWNLOADED=0; \
    if wget -q --timeout=30 --tries=2 -O /tmp/ta-lib.tar.gz https://github.com/TA-Lib/ta-lib/archive/refs/tags/v0.4.0.tar.gz 2>&1; then \
        echo "Downloaded from GitHub mirror"; \
        TA_LIB_DOWNLOADED=1; \
        TA_LIB_DIR="ta-lib-0.4.0"; \
    elif wget -q --timeout=30 --tries=2 -O /tmp/ta-lib.tar.gz http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz 2>&1; then \
        echo "Downloaded from SourceForge primary"; \
        TA_LIB_DOWNLOADED=1; \
        TA_LIB_DIR="ta-lib"; \
    elif curl -f -L --connect-timeout 30 --max-time 120 -o /tmp/ta-lib.tar.gz https://sourceforge.net/projects/ta-lib/files/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz/download 2>&1; then \
        echo "Downloaded from SourceForge via curl"; \
        TA_LIB_DOWNLOADED=1; \
        TA_LIB_DIR="ta-lib"; \
    fi; \
    if [ "$TA_LIB_DOWNLOADED" -eq 0 ]; then \
        echo "ERROR: All download methods failed"; \
        exit 1; \
    fi; \
    echo "=== Extracting TA-Lib ==="; \
    tar -xzf /tmp/ta-lib.tar.gz -C /tmp && rm -f /tmp/ta-lib.tar.gz; \
    cd /tmp/$TA_LIB_DIR; \
    echo "=== Configuring TA-Lib ==="; \
    if [ -f configure ]; then \
        chmod +x configure; \
    elif [ -f configure.ac ] || [ -f configure.in ]; then \
        autoreconf -fvi 2>&1 || ([ -f autogen.sh ] && chmod +x autogen.sh && ./autogen.sh 2>&1 || true); \
        if [ -f configure ]; then chmod +x configure; else exit 1; fi; \
    else exit 1; fi; \
    ./configure --prefix=/usr > /tmp/configure.log 2>&1 || (cat /tmp/configure.log && exit 1); \
    echo "=== Building TA-Lib ==="; \
    make -j1 > /tmp/make.log 2>&1 || (tail -100 /tmp/make.log && exit 1); \
    echo "=== Installing TA-Lib ==="; \
    make install > /tmp/install.log 2>&1 || (cat /tmp/install.log && exit 1); \
    cd /; \
    rm -rf /tmp/$TA_LIB_DIR /tmp/*.log /tmp/ta-lib*; \
    ldconfig; \
    find /tmp -type f \( -name "*.o" -o -name "*.a" -o -name "*.log" \) 2>/dev/null | xargs rm -f || true; \
    echo "=== TA-Lib installation complete ==="

# Verify TA-Lib installation
RUN ldconfig && \
    ls -la /usr/lib/libta_lib.so* || echo "Warning: TA-Lib libraries not found"

# Label the image
LABEL maintainer="FKS Team" \
      description="Shared builder base image with TA-Lib and build tools" \
      version="1.0.0"

