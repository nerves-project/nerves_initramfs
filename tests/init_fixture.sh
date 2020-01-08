#!/bin/bash

# Required variables
#
# $WORK
# $INIT
# $TESTS_DIR

mkdir -p "$WORK/dev"
ln -s "$INIT" "$WORK/init"
mkdir -p "$WORK/sbin"
mkdir -p "$WORK/usr/bin"
ln -s "$TESTS_DIR/fake_init" "$WORK/sbin/init"
ln -s "$TESTS_DIR/fake_fwup" "$WORK/usr/bin/fwup"
ln -s "$TESTS_DIR/fake_boardid" "$WORK/usr/bin/boardid"
ln -s "$TESTS_DIR/fake_faulty_program" "$WORK/usr/bin/faulty_program"

# Create the device containing a root filesystem
dd if=/dev/zero of="$WORK/dev/mmcblk0p2" bs=512 count=0 seek=1024 2>/dev/null
ln -s /dev/null "$WORK/dev/null"

# Fake active console
real_tty="$(tty)"
ln -s "$real_tty" "$WORK/dev/ttyF1"
ln -s "$real_tty" "$WORK/dev/ttyAMA0"
ln -s "$real_tty" "$WORK/dev/tty1"

# Loop and dm-crypt
mkdir -p "$WORK/dev/mapper"
touch "$WORK/dev/mapper/control"
touch "$WORK/dev/loop0"

# "Block" devices
mkdir -p "$WORK/sys/block"
touch "$WORK/sys/block/mmcblk0"
touch "$WORK/sys/block/sda"
ln -s "$TESTS_DIR/gpt-disk.img" "$WORK/dev/mmcblk0"
touch "$WORK/dev/mmcblk0p1"
touch "$WORK/dev/mmcblk0p2"
touch "$WORK/dev/mmcblk0p5"
ln -s "$TESTS_DIR/mbr-disk.img" "$WORK/dev/sda"
touch "$WORK/dev/sda1"
touch "$WORK/dev/sda2"
