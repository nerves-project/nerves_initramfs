#!/bin/sh

set -e

# The default configurations only need init to be in the archive so
# create the rootfs.cpio manually to only include it.
mkdir -p "$BINARIES_DIR"
cd "$TARGET_DIR" && echo init | cpio -o -H newC --owner=root:root > "$BINARIES_DIR/rootfs.cpio"

cd "$BINARIES_DIR" &&
    (
        gzip -k rootfs.cpio
        xz -k rootfs.cpio
    )

