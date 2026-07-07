#!/bin/bash
# Script to build Samsung SM8250 (S20 FE) kernel with Podman
# Powered by Antigravity

set -e

IMAGE_NAME="sm8250-kernel-builder"
WORKSPACE_DIR="$(pwd)"

# 0. Check if boot.img exists in the project root
if [ ! -f "$WORKSPACE_DIR/boot.img" ]; then
    echo "================================================================="
    echo " ERROR: 'boot.img' was not found in the project root directory!"
    echo " Please copy the stock boot.img to '$WORKSPACE_DIR/boot.img'"
    echo " and run the script again."
    echo "================================================================="
    exit 1
fi

# 1. Build the Podman container image if it does not exist
# We force rebuild the image if it doesn't contain magiskboot
if ! podman image exists "$IMAGE_NAME"; then
    echo "[*] Podman image '$IMAGE_NAME' not found. Building it..."
    podman build -t "$IMAGE_NAME" -f Dockerfile .
else
    echo "[*] Podman image '$IMAGE_NAME' already exists. Rebuilding to apply Dockerfile updates..."
    podman build -t "$IMAGE_NAME" -f Dockerfile .
fi

# 2. Merge configuration files
# This combines the base Kona defconfig with Samsung common configs and S20 FE (r8q) specific configs
echo "[*] Merging kernel configurations..."
podman run --rm \
    -v "$WORKSPACE_DIR:/src:z" \
    -w /src \
    -e ARCH=arm64 \
    -e SUBARCH=arm64 \
    -e LLVM=1 \
    -e CROSS_COMPILE=aarch64-linux-gnu- \
    -e CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    "$IMAGE_NAME" \
    bash scripts/kconfig/merge_config.sh \
         arch/arm64/configs/vendor/kona_defconfig \
         arch/arm64/configs/vendor/samsung/kona-sec-common.config \
         arch/arm64/configs/vendor/samsung/r8q.config

# 3. Build the kernel
# Compiles the kernel (Image), device tree blobs (dtbs) and modules
echo "[*] Compiling kernel..."
podman run --rm \
    -v "$WORKSPACE_DIR:/src:z" \
    -w /src \
    -e ARCH=arm64 \
    -e SUBARCH=arm64 \
    -e LLVM=1 \
    -e CROSS_COMPILE=aarch64-linux-gnu- \
    -e CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    -e KBUILD_BUILD_USER="crashunix" \
    -e KBUILD_BUILD_HOST="github.com/crashunix" \
    "$IMAGE_NAME" \
    bash -c "make -j\$(nproc) Image dtbs modules"

# 4. Repack the boot.img with the new kernel
echo "[*] Unpacking boot.img and patching kernel..."
podman run --rm \
    -v "$WORKSPACE_DIR:/src:z" \
    -w /src \
    "$IMAGE_NAME" \
    bash -c "mkdir -p repack_tmp && cp boot.img repack_tmp/ && cp arch/arm64/boot/Image repack_tmp/ && cd repack_tmp && magiskboot unpack boot.img && cp Image kernel && magiskboot repack boot.img boot-patched.img && cp boot-patched.img ../ && cd .. && rm -rf repack_tmp"

echo "[*] Build and repack completed successfully!"
echo "    Patched Boot Image:  boot-patched.img"
echo "    Kernel Image:        arch/arm64/boot/Image"
echo "    Device Tree Blobs:   arch/arm64/boot/dts/vendor/qcom/"
