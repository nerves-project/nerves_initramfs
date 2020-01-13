#ifndef BLOCK_DEVICE_H
#define BLOCK_DEVICE_H

#define BLOCK_DEVICE_PATH_LEN 32

enum block_device_type {
    BLOCK_DEVICE_DISK = 0,
    BLOCK_DEVICE_PARTITION
};

struct block_device_info
{
    struct block_device_info *next;
    enum block_device_type type;
    char path[BLOCK_DEVICE_PATH_LEN];
    char uuid[48];
};

int probe_block_devices(struct block_device_info **devices);
void free_block_devices(struct block_device_info *devices);
int find_block_device_by_spec(const char *spec, char *path);
int open_block_device(const char *spec, int flags, char *path);

#endif