#ifndef BLOCK_DEVICE_H
#define BLOCK_DEVICE_H

#define BLOCK_DEVICE_PATH_LEN 32

struct block_device_info
{
    struct block_device_info *next;
    char path[BLOCK_DEVICE_PATH_LEN];
    char partuuid[48];
};

int probe_block_devices(struct block_device_info **devices);
void free_block_devices(struct block_device_info *devices);
int find_block_device_by_spec(const char *spec, char *path);

#endif