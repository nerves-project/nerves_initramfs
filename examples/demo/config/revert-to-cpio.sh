#!/bin/sh

#
# config-to-cpio.sh <nerves_initramfs.conf> <output.cpio[.gz|.xz]>
#
# This script packages the specified nerves_initramfs.conf file into an
# optionally-compressed cpio file that can be concatenated to
# nerves_initramfs.cpio.* to configure the initramfs.
#
# If you need to supply more files to the initramfs, just concatenate another
# cpio (compressed or not) onto this one. The Linux kernel's cpio extractor
# processes everything it sees and automatically handles any necessary
# decompression so long as the decompressor has been enabled.

INPUT=$1
OUTPUT=$2

if [ -z $INPUT ]; then
    echo "Please pass in a path to a configuration file"
    exit 1
fi

if [ ! -f $INPUT ]; then
    echo "Could not find '$INPUT'"
    exit 1
fi

if [ -z $OUTPUT ]; then
    OUTPUT=$INPUT.cpio
fi
ABSOLUTE_OUTPUT=$(realpath "$OUTPUT")

case "$OUTPUT" in
    *.gz) COMPRESS=gzip;;
    *.xz) COMPRESS=xz;;
    *) COMPRESS=cat;;
esac

WORKDIR=$(mktemp -d)
cp $INPUT $WORKDIR/revert.fw
(cd $WORKDIR; echo revert.fw | cpio -o -H newC --owner=root:root --reproducible --quiet | $COMPRESS > "$ABSOLUTE_OUTPUT")
rm $WORKDIR/revert.fw
rmdir $WORKDIR

exit 0

