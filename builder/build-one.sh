#!/bin/bash

# configs/xyz_defconfig
config="$1"

echo "Creating $config..."
./create-build.sh $config
if [[ $? != 0 ]]; then
    echo "--> './create-build.sh $config' failed!"
    exit 1
fi

base=$(basename -s _defconfig $config)

echo "Building $base..."

# Make sure that local build products don't affect these builds.
rm -f ../src/*.o

# If rebuilding, force a rebuild of nerves_initramfs.
rm -fr "o/$base/build/nerves_initramfs"

make -C o/$base
if [[ $? != 0 ]]; then
    echo "--> 'Building $base' failed!"
    exit 1
fi

cp "o/$base/images/rootfs.cpio.gz" "../$base.gz"
cp "o/$base/images/rootfs.cpio.xz" "../$base.xz"

