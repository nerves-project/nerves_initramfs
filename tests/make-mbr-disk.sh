#!/bin/sh

set -e

output=mbr-disk.img

linux_type=0x83
fat32_type=0x0c
disk_id=0x3fc3e2d4

# Boot partition offset and size, in 512-byte sectors
boot_part_start=64
boot_part_size=64

# Rootfs partition offset and size, in 512-byte sectors
root_part_start=$(( boot_part_start + boot_part_size ))
root_part_size=128

# App partition offset and size, in 512-byte sectors
app_part_start=$(( root_part_start + root_part_size ))
app_part_size=64

gpt_size=33

first_lba=$(( 1 + gpt_size ))
last_lba=$(( app_part_start + app_part_size ))

# Disk image size in 512-byte sectors
image_size=$(( last_lba + gpt_size + 1 ))

primary_gpt_lba=0
secondary_gpt_lba=$(( image_size - gpt_size ))

rm -f $output
dd if=/dev/zero of=$output bs=512 count=0 seek=$image_size 2>/dev/null

sfdisk $output <<EOF
label: dos
label-id: $disk_id
device: /dev/nothing0
unit: sectors
first-lba: $first_lba
last-lba: $last_lba

/dev/nothing0p1 : start=$boot_part_start,  size=$boot_part_size,  type=$fat32_type
/dev/nothing0p2 : start=$root_part_start, size=$root_part_size, type=$linux_type
EOF


