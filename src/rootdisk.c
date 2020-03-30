/*
The MIT License (MIT)

Copyright (c) 2013-20 Frank Hunleth

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysmacros.h>

#include "util.h"

#define SHORT_PATH_MAX 256

struct block_device_info {
    struct block_device_info *next;
    char *name;
    dev_t dev;
    unsigned int partition_number;
    struct block_device_info *parent;
};

static dev_t read_dev_file(const char *base, const char *name)
{
    char fname[SHORT_PATH_MAX];
    snprintf(fname, sizeof(fname), "%.64s/%.32s/dev", base, name);
    FILE *fp = fopen(fname, "r");
    if (!fp)
        return 0;

    unsigned int dev_major;
    unsigned int dev_minor;

    dev_t d = 0;
    if (fscanf(fp, "%u:%u", &dev_major, &dev_minor) == 2) {
#if defined(__APPLE__)
        d = (dev_major << 8) + dev_minor;
#else
        d = makedev(dev_major, dev_minor);
#endif
    }

    fclose(fp);
    return d;
}

static unsigned int read_partition_file(const char *base, const char *name)
{
    char fname[SHORT_PATH_MAX];
    snprintf(fname, sizeof(fname), "%.64s/%.32s/partition", base, name);
    FILE *fp = fopen(fname, "r");
    if (!fp)
        return 0;

    unsigned int partition;
    if (fscanf(fp, "%u", &partition) != 1)
        partition = 0;

    fclose(fp);

    return partition;
}

static int not_special_filter(const struct dirent *d)
{
    return d->d_name[0] != '.';
}

static int directory_filter(const struct dirent *d)
{
    return d->d_name[0] != '.' && (d->d_type & DT_DIR);
}

static void scan_for_partitions(struct block_device_info *parent,
            struct block_device_info **infos)
{
    char base_dir[SHORT_PATH_MAX];
    snprintf(base_dir, sizeof(base_dir), "/sys/block/%s", parent->name);

    struct dirent **namelist;
    int n = scandir(base_dir,
                    &namelist,
                    directory_filter,
                    alphasort);
    int i;
    for (i = 0; i < n; i++) {
        dev_t dev = read_dev_file(base_dir, namelist[i]->d_name);
        unsigned int partition_number = read_partition_file(base_dir, namelist[i]->d_name);
        if (dev == 0 || partition_number == 0)
            continue;

        struct block_device_info *info = malloc(sizeof(struct block_device_info));
        info->next = *infos;
        info->name = strdup(namelist[i]->d_name);
        info->dev = dev;
        info->partition_number = partition_number;
        info->parent = parent;
        *infos = info;
    }

    if (n >= 0) {
        for (i = 0; i < n; i++)
            free(namelist[i]);
        free(namelist);
    }
}

static struct block_device_info *scan_for_block_devices()
{
    struct block_device_info *infos = NULL;
    const char *base_dir = "/sys/block";

    struct dirent **namelist;
    int n = scandir(base_dir,
                    &namelist,
                    not_special_filter,
                    alphasort);
    int i;
    for (i = 0; i < n; i++) {
        dev_t dev = read_dev_file(base_dir, namelist[i]->d_name);
        if (dev == 0)
            continue;

        struct block_device_info *info = malloc(sizeof(struct block_device_info));
        info->next = infos;
        info->name = strdup(namelist[i]->d_name);
        info->dev = dev;
        info->partition_number = 0;
        info->parent = NULL;
        infos = info;

        scan_for_partitions(info, &infos);
    }
    if (n <= 0)
        info("No directories found under /sys/block. Check that /sys is mounted");

    if (n >= 0) {
        for (i = 0; i < n; i++)
            free(namelist[i]);
        free(namelist);
    }

    return infos;
}

static void free_block_device_info(struct block_device_info *info)
{
    while (info) {
        struct block_device_info *next = info->next;
        free(info->name);
        free(info);
        info = next;
    }
}

static void create_dev_symlink(const char *partition_suffix, const char *devname)
{
    char symlinkpath[SHORT_PATH_MAX];
    char devpath[SHORT_PATH_MAX];

    snprintf(symlinkpath, sizeof(symlinkpath), "/dev/rootdisk%s", partition_suffix);
    snprintf(devpath, sizeof(devpath), "/dev/%s", devname);
    if (symlink(devpath, symlinkpath) < 0)
        info("Could not create symlink '%s'->'%s': %s", symlinkpath, devpath, strerror(errno));
}

static dev_t rootfs_device(const char *rootfs_devname)
{
    struct stat st;
    if (stat(rootfs_devname, &st) >= 0) {
        return st.st_rdev;
    } else {
        info("Could not determine root device for %s: %s", rootfs_devname, strerror(errno));
        return 0;
    }
}

void create_rootdisk_symlinks(const char *rootfs_devname)
{
    struct block_device_info *infos = scan_for_block_devices();

    dev_t rootfs_dev = rootfs_device(rootfs_devname);
    if (rootfs_dev == 0)
        return;

    struct block_device_info *rootfs_info = NULL;
    for (struct block_device_info *i = infos; i != NULL; i = i->next) {
        if (i->dev == rootfs_dev) {
            rootfs_info = i;
            break;
        }
    }

    if (!rootfs_info || !rootfs_info->parent) {
        info("Root disk is supposed to be %s, but it wasn't found or wasn't a partition.", rootfs_devname);
        return;
    }

    struct block_device_info *rootdisk_info = rootfs_info->parent;

    // Create the main disk's symlink.
    create_dev_symlink("0", rootdisk_info->name);

    // Create all of the partition symlinks (of which one will be the rootfs).
    for (struct block_device_info *i = infos; i != NULL; i = i->next) {
        if (i->parent == rootdisk_info) {
            char partition_suffix[8];
            snprintf(partition_suffix, sizeof(partition_suffix), "0p%d", i->partition_number);
            create_dev_symlink(partition_suffix, i->name);
        }
    }

    free_block_device_info(infos);
}
