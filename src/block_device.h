#ifndef BLOCK_DEVICE_H
#define BLOCK_DEVICE_H

struct block_device_info
{
    struct block_device_info *next;
    char path[32];
    char partuuid[48];
};

int probe_block_devices(struct block_device_info **devices);
void free_block_devices(struct block_device_info *devices);

#endif