#!/bin/bash

configs=$(find ./configs -name "*_defconfig")

# Make sure that local build products don't affect these builds.
rm -f ../src/*.o

# Configure everything
for config in $configs; do
    echo "Creating $config..."
    ./create-build.sh $config
    if [[ $? != 0 ]]; then
        echo "--> './create-build.sh $config' failed!"
        exit 1
    fi
done

# Build everything
for config in $configs; do
    base=$(basename -s _defconfig $config)

    echo "Building $base..."

    # If rebuilding, force a rebuild of rootfs_mounter and undo the prune of /usr/lib
    # that breaks the os-release copy script.
    mkdir -p o/$base/target/usr/lib
    rm -fr o/$base/build/rootfs_mounter
    make -C o/$base
    if [[ $? != 0 ]]; then
        echo "--> 'Building $base' failed!"
        exit 1
    fi
done

