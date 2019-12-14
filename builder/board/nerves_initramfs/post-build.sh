#!/bin/sh

set -e

# The default configurations only need init to be in the archive so
# create the rootfs.cpio manually to only include it.
mkdir -p "$BINARIES_DIR"
cd "$TARGET_DIR" && echo init | cpio -o -H newC --owner=root:root --reproducible --quiet > "$BINARIES_DIR/rootfs.cpio"

# Notes on compressor options:
#
# 1. -9 -> max compression
# 2. -f -> force
# 3. -k -> keep rootfs.cpio
# 4. xz -C crc32 -> Linux kernel doesn't seem to support the default check (crc64)
# 5. gzip -n -> Don't store original filename
cd "$BINARIES_DIR" &&
    (
        gzip -9 -n -f -k rootfs.cpio
        xz -9 -C crc32 -f -k rootfs.cpio
    )

