# nerves_initramfs

This project creates a tiny
[initramfs](https://en.wikipedia.org/wiki/Initial_ramdisk) that supports
cross-platform failure recovery and non-trivial root filesystem setups on
devices using Nerves.

The way it works is this:

1. The device's bootloader (U-Boot, Barebox, RPi, grub, etc.) boots the
   platform-specific Linux kernel and the initramfs from this project
2. The `init` process provided by this project handles any recovery tasks, and
   then mounts the real root filesystem, and runs the real `init` process
   (`erlinit` for Nerves)

This project is focused on recovery and root filesystem mounts. No
other functionality is likely to be added to this project to keep it small,
fast, and easy to audit.

Failure recovery at this level means that if a Nerves device fails
catastrophically after the Linux kernel starts, code here can revert devices to
previous firmware or start recovery mechanisms. This project does not protect
against Linux kernel initialization crashes. This is a tradeoff to avoid
maintaining an implementation for every bootloader where this logic is time
consuming to verify. You can, of course, transition away from this code as
needed.

Root filesystem mount functionality is handled here as well since the initramfs
is typically where this feature lives for when the root filesystem is encrypted.
Additionally, if the root filesystem fails to decrypt, the recovery mechanisms
described previously can be triggered.

## Boot configuration

A simple configuration language is provided for handling the boot process.  The
main construct is a rule. Rules are triggered by a condition and provide actions
to run. Rules are evaluated sequentially through the configuration file.  Here's
an example:

```config
boot.a && a.valid -> { rootfs.path="/dev/mmcblk0p2"; boot(); }
```

A configuration file will contain a list of rules that define the logic for
failing back to known good images or starting recovery.

The configuration file supports variable assignments and calls to functions.

The following variables have special meanings:

Variable           | Description
-------------------|-------------
rootfs.fstype      | Root filesystem time. Defaults to "squashfs"
rootfs.path        | Root filesystem path. Defaults to "/dev/mmcblk0p2"
rootfs.encrypted   | True if the filesystem is encrypted. Defaults to `false`
rootfs.cipher      | The cipher used to encrypt the filesystem. For example, "aes-cbc-plain"
rootfs.secret      | The secret key as hex digits
uboot_env.path     | The location for U-Boot environment data. Defaults to "/dev/mmcblk0"
uboot_env.loaded   | True if the U-Boot environment block has been loaded.
uboot_env.modified | True if something has modified the U-Boot block and it differs from what's on disk
uboot_env.start    | The block offset of the U-Boot environment. (512 byte blocks)
uboot_env.count    | The number of blocks in the environment. Defaults to 256.
run_repl           | True to run a REPL before booting. This is useful for debug. Defaults to `false`

Some functions are supported:

Function           | Description
-------------------|-------------
info(...)          | Prints any arguments passed to it
help()             | Print out help when running in the REPL
vars()             | Print out all known variables and their values
loadenv()          | Load a U-Boot environment block. Set up `uboot_env.path`, `uboot_env.start` and `uboot_env.count` first.
env()              | Print out all loaded U-Boot variables
setenv(key, value) | Set a U-Boot variable. It is not saved until you call `saveenv()
getenv(key)        | Get the value of a U-Boot variable
saveenv()          | Save all U-Boot variables back to storage

## Building

Users should prefer to use pre-built releases. To build your own, you will need
to use Linux and install the [Buildroot required
packages](https://buildroot.org/downloads/manual/manual.html#requirement).

Change to the `builder` directory and run `./build-all.sh` to build for all
platforms.

If you're just building for one platform, run the following:

```sh
./create-build.sh configs/nerves_initramfs_armel_defconfig o/armel
cd o/armel
make
```

The `initramfs` images will be in the `images` directory. You can also run `make
menuconfig` to enable other applications and libraries that may be useful for
your particular setup.

## Linux kernel configuration

The following strings must be in your kernel configuration:

* `CONFIG_BLK_DEV_INITRD=y`
* `CONFIG_RD_<compression>=y` - gzip compression is enabled by default, but if
  you want lz4, for example, you'll need to enable it.

To mount encrypted filesystems, you'll need these additional configuration strings:

* `CONFIG_BLK_DEV_LOOP=y`
* `CONFIG_MD=y`
* `CONFIG_BLK_DEV_DM=y`
* `CONFIG_DM_CRYPT=y` - Only `dm-crypt` is supported. `cryptoloop` and
  `loop-aes` are not supported.
* `CONFIG_CRYPTO_USER=y`
* `CONFIG_CRYPTO_USER_API_HASH=y`
* `CONFIG_CRYPTO_USER_API_SKCIPHER=y`
* `CONFIG_CRYPTO_AES=y` - Make sure to enable the cryptographic algorithms that
  you're using. Hardware acceleration options may exist as well.

## Raspberry Pi configuration

The Raspberry Pi's bootloader supports loading `initramfs` images off the DOS
partition that contains the Linux kernel. Copy the ARM-architecture release to
the DOS partition (in Nerves, you can do this manually or edit the `fwup.conf`
to automate). Since gzip compression is pretty much always enabled in Linux
kernels, the `initramfs.gz` is safe to use. Add the following line to
`config.txt`:

```config
initramfs initramfs.gz followkernel
```

See the [official config.txt boot
documentation](https://www.raspberrypi.org/documentation/configuration/config-txt/boot.md)
for more information.

## U-boot configuration

## Grub configuration

## Mounting an encrypted file system

This project mounts encrypted file systems by using the Linux kernel's
`dm-crypt` module. As such, the web contains a lot of information on this
feature. The main difference, though, is that devices using this project are
expected to be unattended. In other words, a human can not enter a password when
the device boots. This ends up simplifying the options that can be used, but the
handling of the secret can become a major issue.

Storing the secret securely depends on your hardware and your needs. It is
expected that some projects will need to fork this repository to access their
secrets. The examples shown here are meant to be informative on the process, but
they are not secure. They are probably more accurately referred to as ways to
obfuscate the root filesystem.

Here's the general idea:

1. Create your root filesystem as normal
2. Write the filesystem to the destination media. If using a MicroSD card, this
   could be done by mounting it on a Linux PC using `dm-crypt` and writing the
   root filesystem via that. `fwup` also supports encryption.
3. Make sure that your device's Linux kernel supports the chosen encryption
   algorithms
4. Configure this project with how to find or generate the secret key

Here's an example configuration file with the secret key stored as plain text:

```config
rootfs.encrypted = true
rootfs.cipher = "aes-cbc-plain"
rootfs.secret = "8e9c0780fd7f5d00c18a30812fe960cfce71f6074dd9cded6aab2897568cc856"
```

This is illustrative, but obviously quite insecure. The current route to
obtaining the secret key is to edit the C code to this project to integrate it
with platform-specific way of keeping or hiding secrets. It is hoped that
alternatives can be shared in the future.

