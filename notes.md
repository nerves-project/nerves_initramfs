# Notes

```strace
makedev(0xfe, 0), name="my_crypt", uuid="CRYPT-PLAIN-my_crypt", target_count=0, open_count=0, event_nr=0, flags=DM_EXISTS_FLAG}) = 0
ioctl(5, DM_TABLE_LOAD, {version=4.0.0, data_size=16384, data_start=312, name="my_crypt", target_count=1, flags=DM_EXISTS_FLAG|DM_SECURE_DATA_FLAG, {sector_start=0, length=289044, target_type="crypt", string="aes-cbc-plain 8e9c0780fd7f5d00c18a30812fe960cfce71f6074dd9cded6aab2897568cc856 0 /dev/loop0 0"}} => {version=4.39.0, data_size=305, data_start=312, dev=makedev(0xfe, 0), name="my_crypt", uuid="CRYPT-PLAIN-my_crypt", target_count=0, open_count=0, event_nr=0, flags=DM_EXISTS_FLAG|DM_INACTIVE_PRESENT_FLAG}) = 0

ioctl(5, DM_DEV_SUSPEND, {version=4.0.0, data_size=16384, name="my_crypt", event_nr=4194304, flags=DM_EXISTS_FLAG|DM_SECURE_DATA_FLAG} => {version=4.39.0, data_size=305, dev=makedev(0xfe, 0), name="my_crypt", uuid="CRYPT-PLAIN-my_crypt", target_count=1, open_count=0, event_nr=0, flags=DM_EXISTS_FLAG|DM_ACTIVE_PRESENT_FLAG|DM_UEVENT_GENERATED_FLAG}) = 0
stat64("/dev/mapper/my_crypt", 0x7eaf1768) = -1 ENOENT (No such file or directory)

mount("/dev/mapper/my_crypt", "/mnt", "squashfs", MS_SILENT, NULL) = 0

```

## Todo

1. Automate ARM build
1. Figure out how to get secret key
1. Post release products to GitHub releases w/ sha256
1. Port to SmartRent Hub
1. CI
1. Clean up ugly device mapper code
1. More docs
1. Trim more code? I.e., make easier to audit that we know all code that's involved.
1. Automate builds for other platforms
1. Test out xz compressed initramfs
1. Clean up initramfs directories properly
1. Clean up Buildroot putting extra directories in the initramfs (what's up with
   /usr)
