#ifndef _KALLOC_H_
#define _KALLOC_H_

#ifndef __SPINLOCK_FWD_DECL__
#define __SPINLOCK_FWD_DECL__
struct spinlock;
#endif
#include "types.h"

// Forward declaration for struct run
struct run {
    struct run *next;
};

extern int ref_count[];
extern struct {
    struct spinlock lock;
    struct run *freelist;
} kmem;

#define PA2IDX(pa) (((uint64)(pa)) / PGSIZE)

#endif
