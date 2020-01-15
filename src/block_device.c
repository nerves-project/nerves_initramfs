
#include "block_device.h"

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "util.h"

static struct block_device_info *alloc_blkdev()
{
    struct block_device_info *blkdev = malloc(sizeof(struct block_device_info));
    memset(blkdev, 0, sizeof(struct block_device_info));
    return blkdev;
}

static const char *p_or_np(const char *devname)
{
    // Return whether partitions are prefixed with p or not.
    //
    // Examples:
    //  sda -> sda1, sda2, ...
    //  mmcblk0 -> mmcblk0p1, mmcblk0p2, ...

    char last_char = devname[strlen(devname) - 1];
    if (last_char >= '0' && last_char <= '9')
        return "p";
    else
        return "";
}

static uint32_t from_le32(const uint8_t *buffer)
{
    return buffer[0] + (buffer[1] << 8) + (buffer[2] << 16) + (buffer[3] << 24);
}

static bool is_zeros(const uint8_t *buffer, size_t len)
{
    for (size_t i = 0; i < len; i++) {
        if (buffer[i])
            return false;
    }
    return true;
}

static void uuid_to_string_me(const uint8_t uuid[16], char *uuid_str)
{
    sprintf(uuid_str, "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            uuid[3], uuid[2], uuid[1], uuid[0], uuid[5], uuid[4], uuid[7], uuid[6],
            uuid[8], uuid[9], uuid[10], uuid[11], uuid[12], uuid[13], uuid[14], uuid[15]);
}


static int probe_gpt_devices(int fd, const char *devname, struct block_device_info **devices)
{
    uint8_t block[512];

    // Check for protective MBR
    if (pread(fd, block, sizeof(block), 0) < 0)
        return -1;
    if (block[510] != 0x55 || block[511] != 0xaa || block[446 + 4] != 0xee)
        return -1;

    // Check GPT header
    if (pread(fd, block, sizeof(block), 512) < 0)
        return -1;

    if (block[0] != 'E' ||
        block[1] != 'F' ||
        block[2] != 'I' ||
        block[3] != ' ' ||
        block[4] != 'P' ||
        block[5] != 'A' ||
        block[6] != 'R' ||
        block[7] != 'T')
        return -1;

    // Add the disk
    struct block_device_info *blkdev = alloc_blkdev();
    blkdev->next = *devices;
    blkdev->type = BLOCK_DEVICE_DISK;
    snprintf(blkdev->path, sizeof(blkdev->path), "/dev/%.16s", devname);
    uuid_to_string_me(&block[56], blkdev->uuid);
    *devices = blkdev;

    // Load the partition table
    uint32_t partition_count = from_le32(&block[80]);
    if (partition_count > 256)
        return -1;

    uint32_t partition_size = from_le32(&block[84]);
    if (partition_count > 256)
        return -1;

    uint32_t partition_table_size = partition_count * partition_size;
    uint8_t *partitions = malloc(partition_count * partition_size);

    if (pread(fd, partitions, partition_table_size, 512 * 2) < 0) {
        free(partitions);
        return -1;
    }

    const char *p = p_or_np(devname);
    uint8_t *partition = partitions + partition_size * partition_count;
    for (uint32_t i = partition_count; i > 0; i--) {
        partition -= partition_size;

        if (!is_zeros(partition, 16)) {
            struct block_device_info *blkdev = alloc_blkdev();
            blkdev->next = *devices;
            blkdev->type = BLOCK_DEVICE_PARTITION;
            snprintf(blkdev->path, sizeof(blkdev->path), "/dev/%.16s%s%d", devname, p, i);
            uuid_to_string_me(&partition[16], blkdev->uuid);
            *devices = blkdev;
        }
    }

    free(partitions);

    return 0;
}

static int probe_mbr_devices(int fd, const char *devname, struct block_device_info **devices)
{
    uint8_t mbr[512];
    if (pread(fd, mbr, sizeof(mbr), 0) < 0)
        return -1;

    // Check for MBR signature
    if (mbr[510] != 0x55 || mbr[511] != 0xaa)
        return -1;

    // Check for GPT
    // First partition has type 0xee
    if (mbr[446 + 4] == 0xee)
        return -1;

    // Capture the disk UUID since MBR partitions don't have UUIDs
    uint32_t disk_uuid = from_le32(&mbr[440]);

    // Add the disk
    struct block_device_info *blkdev = alloc_blkdev();
    blkdev->next = *devices;
    blkdev->type = BLOCK_DEVICE_DISK;
    snprintf(blkdev->path, sizeof(blkdev->path), "/dev/%.16s", devname);
    snprintf(blkdev->uuid, sizeof(blkdev->uuid), "%08x", disk_uuid);
    *devices = blkdev;

    // Enumerate the primary partitions
    const char *p = p_or_np(devname);
    const uint8_t *partition = &mbr[446 + 4*16];
    for (int i = 4; i > 0; i--) {
        // If non-empty partition
        partition -= 16;
        if (partition[4] != 0) {
            struct block_device_info *blkdev = alloc_blkdev();
            blkdev->next = *devices;
            blkdev->type = BLOCK_DEVICE_PARTITION;
            snprintf(blkdev->path, sizeof(blkdev->path), "/dev/%.16s%s%d", devname, p, i);
            snprintf(blkdev->uuid, sizeof(blkdev->uuid), "%08x-%02x", disk_uuid, i);
            *devices = blkdev;
        }
    }
    return 0;
}

static int probe_partitions(const char *devname, struct block_device_info **devices)
{
    char devpath[32];
    snprintf(devpath, sizeof(devpath), "/dev/%.16s", devname);

    int fd = open(devpath, O_RDONLY | O_CLOEXEC);
    if (fd < 0)
        return -1;

    int rc = 0;
    if (probe_mbr_devices(fd, devname, devices) < 0 &&
        probe_gpt_devices(fd, devname, devices) < 0)
        rc = -1;

    close(fd);

    return rc;
}

static int reverse_alphasort(const struct dirent **a, const struct dirent **b)
{
    return alphasort(b, a);
}

int probe_block_devices(struct block_device_info **devices)
{
    *devices = NULL;

    struct dirent **namelist;
    int n = scandir("/sys/block",
                    &namelist,
                    NULL,
                    reverse_alphasort);
    int i;
    for (i = 0; i < n; i++) {
        if (namelist[i]->d_name[0] == '.')
            continue;

        probe_partitions(namelist[i]->d_name, devices);
    }

    if (n >= 0) {
        for (i = 0; i < n; i++)
            free(namelist[i]);
        free(namelist);
    }

    return 0;
}

void free_block_devices(struct block_device_info *devices)
{
    while (devices) {
        struct block_device_info *next = devices->next;
        free(devices);
        devices = next;
    }
}

static int find_block_device_by_uuid(enum block_device_type type, const char *uuid, char *path)
{
    struct block_device_info *devices;
    if (probe_block_devices(&devices) < 0)
        return -1;

    int rc = -1;
    for (struct block_device_info *device = devices; device; device = device->next) {
        if (type == device->type && strcmp(uuid, device->uuid) == 0) {
            strcpy(path, device->path);
            rc = 0;
            break;
        }
    }
    free_block_devices(devices);
    return rc;
}

int find_block_device_by_spec(const char *spec, char *path)
{
    if (strncmp("PARTUUID=", spec, 9) == 0) {
        return find_block_device_by_uuid(BLOCK_DEVICE_PARTITION, &spec[9], path);
    } else if (strncmp("DISKUUID=", spec, 9) == 0) {
        return find_block_device_by_uuid(BLOCK_DEVICE_DISK, &spec[9], path);
    } else {
        // Assume path
        strcpy(path, spec);
        return 0;
    }
}

static int open_block_device_impl(const char *spec, int flags, char *path)
{
    if (find_block_device_by_spec(spec, path) < 0)
        return -1;

    return open(path, flags);
}

// Files in /dev populate asynchronously so this lets us wait for them to show up.
int open_block_device(const char *spec, int flags, char *path)
{
    // If this is called multiple times and we've exhausted the wait time, then
    // don't wait any longer. We don't want a longer cumulative wait that depends on
    // the contents of the script.
    static int tries = 1000; // Wait 1000 * 1ms = 1 second total
    int fd = open_block_device_impl(spec, flags, path);
    while (fd < 0 && tries > 0) {
        usleep(1000);
        fd = open_block_device_impl(spec, flags, path);
        tries--;
    }

    if (fd < 0)
        info("Could not open block device '%s' even after waiting!", spec);

    return fd;
}