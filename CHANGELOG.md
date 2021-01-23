# Changelog

## v0.5.0

* New features
  * Added nerves_initramfs support for `aarch64` targets.
  * buildroot 2020.11.1
  * fwup v1.8.3

## v0.4.0

* New features
  * Add `file-to-cpio.sh` helper script to release so that systems using
    `nerves_initramfs` don't need to maintain a copy.
  * fwup v1.7.0

## v0.3.3

* New features
  * Change Linux command line override format to actually work. New format is
    to pass `--` and then `key` or `key=value` parameters. For example,
    `-- rootfs.path=/dev/sda2 run_repl`
  * Create /dev/rootdisk symlinks - These are used various places to generically
    refer to the boot block device. Creating them here is more reliable than
    other locations since the symlinks are based on the nerves_initramfs
    configuration rather than trying to derive them from mount information.
  * Buildroot 2020.02
  * fwup v1.5.2 - footprint reductions

* Bug fixes
  * Fix block calculation for call to device mapper

## v0.3.2

* New features
  * Add a readfile() function

* Bug fixes
  * Fix static build of init

## v0.3.1

* New features
  * Print out version on start
  * Support debug builds. Debug initramfs cpio images can be concatenated onto
    the ones in use to "turn on" debug prints.
  * Rename info() to print() since that's what the function does

* Bug fixes
  * Fix bug where uboot environment reads would not wait for the target disk to
    enumerate
  * Fix issue where UUIDs were case sensitive on the hex digits

## v0.3.0

* New features
  * Support probing disks by UUID (as well as partitions)
  * New commands: ls(), sleep(), reboot(), poweroff(), fwup_revert()

* Bug fixes
  * Fix U-Boot environment block reading/writing
  * Clean up all files before switching the rootfs
  * Various script language fixes

## v0.2.0

Add GPT support and include fwup so that it's possible to revert images.

## v0.1.2

Create one tar file that has all of the release binaries.

## v0.1.1

Rename project and various fixes to the language.

## v0.1.0

Initial release
