# Changelog

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
