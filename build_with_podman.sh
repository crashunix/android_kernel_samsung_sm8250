#!/bin/bash
# Script to build Samsung SM8250 (S20 FE) kernel with Podman
# Powered by Antigravity

set -e

IMAGE_NAME="sm8250-kernel-builder"
WORKSPACE_DIR="$(pwd)"

# 1. Build the Podman container image if it does not exist
if ! podman image exists "$IMAGE_NAME"; then
    echo "[*] Podman image '$IMAGE_NAME' not found. Building it..."
    podman build -t "$IMAGE_NAME" -f Dockerfile .
else
    echo "[*] Podman image '$IMAGE_NAME' already exists."
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
    "$IMAGE_NAME" \
    bash -c "make -j\$(nproc) Image dtbs modules"

echo "[*] Build completed successfully!"
echo "    Kernel Image is at: arch/arm64/boot/Image"
echo "    Device Tree Blobs are in: arch/arm64/boot/dts/vendor/qcom/"
