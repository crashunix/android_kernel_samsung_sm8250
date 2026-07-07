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
    unzip \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabi \
    && rm -rf /var/lib/apt/lists/*

# Install magiskboot for repacking boot.img
RUN curl -L -o /tmp/magisk.apk https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk && \
    unzip -p /tmp/magisk.apk lib/x86_64/libmagiskboot.so > /usr/local/bin/magiskboot && \
    chmod +x /usr/local/bin/magiskboot && \
    rm /tmp/magisk.apk

WORKDIR /src

CMD ["/bin/bash"]