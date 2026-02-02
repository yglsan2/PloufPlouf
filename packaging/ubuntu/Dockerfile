# Image pour construire PloufPlouf en .deb (Ubuntu 22.04).
# Usage: voir build-deb.sh à la racine de packaging/ubuntu.

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter (branche stable)
RUN git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git /opt/flutter

ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --enable-linux-desktop \
    && flutter precache --linux

WORKDIR /src

# Le projet est monté en volume ; le script build-in-docker.sh fait le build et crée le .deb
CMD ["bash", "packaging/ubuntu/build-in-docker.sh"]
