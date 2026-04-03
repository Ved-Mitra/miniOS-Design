#ifndef MEM_H
#define MEM_H

#include "types.h"

enum mem_type {
    MEM_KERNEL,
    MEM_FILE,
    MEM_PIPE
};

void* mem_alloc(enum mem_type type);
void mem_free(void* ptr);

#endif