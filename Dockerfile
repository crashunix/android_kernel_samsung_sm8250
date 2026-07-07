FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    zlib1g-dev \
    cpio \
    git \
    lld \
    llvm \
    clang \
    curl \
    zip \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabi \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

CMD ["/bin/bash"]