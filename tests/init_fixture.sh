#!/bin/bash

# Required variables
#
# $WORK
# $TEST_ROOTFS
# $INIT
# $TESTS_DIR

mkdir -p "$TEST_ROOTFS/dev"
ln -s "$INIT" "$TEST_ROOTFS/init"
mkdir -p "$TEST_ROOTFS/usr/bin"
ln -s "$TESTS_DIR/fake_fwup" "$TEST_ROOTFS/usr/bin/fwup"
ln -s "$TESTS_DIR/fake_boardid" "$TEST_ROOTFS/usr/bin/boardid"
ln -s "$TESTS_DIR/fake_faulty_program" "$TEST_ROOTFS/usr/bin/faulty_program"

# Create the device containing a root filesystem
dd if=/dev/zero of="$TEST_ROOTFS/dev/mmcblk0p2" bs=512 count=0 seek=1024 2>/dev/null
ln -s /dev/null "$TEST_ROOTFS/dev/null"

# Fake active console
real_tty="$(tty)"
ln -s "$real_tty" "$TEST_ROOTFS/dev/ttyF1"
ln -s "$real_tty" "$TEST_ROOTFS/dev/ttyAMA0"
ln -s "$real_tty" "$TEST_ROOTFS/dev/tty1"

# Loop and dm-crypt
mkdir -p "$TEST_ROOTFS/dev/mapper"
touch "$TEST_ROOTFS/dev/mapper/control"
touch "$TEST_ROOTFS/dev/loop0"

# "Block" devices
mkdir -p "$TEST_ROOTFS/sys/block"
touch "$TEST_ROOTFS/sys/block/mmcblk0"
touch "$TEST_ROOTFS/sys/block/sda"
ln -s "$TESTS_DIR/gpt-disk.img" "$TEST_ROOTFS/dev/mmcblk0"
touch "$TEST_ROOTFS/dev/mmcblk0p1"
touch "$TEST_ROOTFS/dev/mmcblk0p2"
touch "$TEST_ROOTFS/dev/mmcblk0p5"
ln -s "$TESTS_DIR/mbr-disk.img" "$TEST_ROOTFS/dev/sda"
touch "$TEST_ROOTFS/dev/sda1"
touch "$TEST_ROOTFS/dev/sda2"

# The next init
mkdir -p "$TEST_ROOTFS/mnt/sbin"
ln -s "$TESTS_DIR/fake_init" "$TEST_ROOTFS/mnt/sbin/init"
