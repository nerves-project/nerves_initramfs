#!/bin/bash

configs=$(find ./configs -name "*_defconfig")

for config in $configs; do
    ./build-one.sh $config
done

