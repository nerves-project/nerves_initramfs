#!/bin/sh

#
# config-to-cpio.sh <config.txt> <output.cpio[.gz|.xz]>
#
# This script packages the specified config.txt file into an
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
    echo "Please pass in a path to a config.txt"
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
cp $INPUT $WORKDIR/config.txt
(cd $WORKDIR; echo config.txt | cpio -o -H newC --owner=root:root 2>/dev/null | $COMPRESS > "$ABSOLUTE_OUTPUT")
rm $WORKDIR/config.txt
rmdir $WORKDIR

exit 0

