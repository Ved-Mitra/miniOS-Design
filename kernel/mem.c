#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "vm.h"  
#include "defs.h"      // ✅ ADD THIS
#include "mem.h"

struct {
    struct spinlock lock;
    int total_allocs;
} mem_state;

void
meminit(void)
{
    initlock(&mem_state.lock, "mem");
    mem_state.total_allocs = 0;
}

void*
mem_alloc(enum mem_type type)
{
    void *ptr = kalloc();

    if(ptr == 0)
        return 0;

    acquire(&mem_state.lock);
    mem_state.total_allocs++;
    release(&mem_state.lock);

    return ptr;
}

void
mem_free(void *ptr)
{
    if(ptr == 0)
        return;

    kfree(ptr);

    acquire(&mem_state.lock);
    mem_state.total_allocs--;
    release(&mem_state.lock);
}