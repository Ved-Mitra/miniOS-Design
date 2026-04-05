import re

# Fix Makefile
with open("Makefile", "r") as f:
    text = f.read()

text = re.sub(r"\$K/virtio_disk\.o \\\n\s*\$K/gc\.o\n\s*\$K/mem\.o \\\n", 
              "$K/virtio_disk.o \\\n  $K/gc.o\n", text)
              
text = re.sub(r"\$U/_mytest\n\s*\$U/_cowtest\\\n", 
              "$U/_mytest\\\n\t$U/_cowtest\\\n", text)

text = re.sub(r"\$U/_cowmem\\\n", "$U/_cowmem\n", text)

with open("Makefile", "w") as f:
    f.write(text)

print("Makefile fixed")

# Write new kalloc.c
kalloc_content = """// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"
#include "color.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.

struct rmap {
  pagetable_t pagetable;
  uint64 va;
};

// Map tracks PA from KERNBASE to PHYSTOP
struct rmap reverse_map[(PHYSTOP - KERNBASE) / PGSIZE];

struct free_block {
  struct free_block *next;
  uint num_pages;
};

// 🔥 Reference count array
int ref_count[PHYSTOP / PGSIZE];

#define PA2IDX(pa) (((uint64)(pa)) / PGSIZE)

struct {
  struct spinlock lock;
  int use_lock;
  struct free_block *freelist;
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  memset(reverse_map, 0, sizeof(reverse_map));
  
  // 🔥 Initialize all ref counts to 0
  for(int i = 0; i < PHYSTOP / PGSIZE; i++)
    ref_count[i] = 0;

  freerange(end, (void*)PHYSTOP);
  kmem.use_lock = 1;
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    ref_count[PA2IDX(p)] = 1;
  }
  kfree_contig((void*)PGROUNDUP((uint64)pa_start), ((uint64)pa_end - (uint64)PGROUNDUP((uint64)pa_start)) / PGSIZE);
}

void
record_rmap(uint64 pa, pagetable_t pagetable, uint64 va)
{
  if(pa >= KERNBASE && pa < PHYSTOP) {
    uint64 idx = (pa - KERNBASE) / PGSIZE;
    reverse_map[idx].pagetable = pagetable;
    reverse_map[idx].va = va;
  }
}

void
clear_rmap(uint64 pa)
{
  if(pa >= KERNBASE && pa < PHYSTOP) {
    uint64 idx = (pa - KERNBASE) / PGSIZE;
    reverse_map[idx].pagetable = 0;
    reverse_map[idx].va = 0;
  }
}

void
kfree_contig(void *pa, int n)
{
  struct free_block *b, *prev, *curr;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa + n * PGSIZE > PHYSTOP)
    panic("kfree_contig");

  if(kmem.use_lock) acquire(&kmem.lock);

  for(int i = 0; i < n; i++) {
    int idx = PA2IDX((char*)pa + i * PGSIZE);
    if(ref_count[idx] <= 0)
      panic("kfree_contig: ref_count already zero");
    ref_count[idx]--;
  }

  // If ANY page is still referenced (e.g. CoW ownership), we early return for that chunk.
  if (n == 1 && ref_count[PA2IDX(pa)] > 0) {
    if(kmem.use_lock) release(&kmem.lock);
    return;
  }

  if (n > 1) {
    for(int i = 0; i < n; i++) {
      if (ref_count[PA2IDX((char*)pa + i * PGSIZE)] > 0) {
        panic("kfree_contig: partial free not supported on contiguous blocks");
      }
    }
  }

  if(kmem.use_lock) release(&kmem.lock);

  for(int i = 0; i < n; i++) {
    clear_rmap((uint64)pa + i * PGSIZE);
  }

  memset(pa, 1, n * PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);

  b = (struct free_block*)pa;
  b->num_pages = n;

  prev = 0;
  curr = kmem.freelist;
  while(curr != 0 && curr < b) {
    prev = curr;
    curr = curr->next;
  }

  if(prev) prev->next = b;
  else kmem.freelist = b;
  b->next = curr;

  // Coalesce right
  if(b->next && (char*)b + b->num_pages * PGSIZE == (char*)b->next) {
    b->num_pages += b->next->num_pages;
    b->next = b->next->next;
  }

  // Coalesce left
  if(prev && (char*)prev + prev->num_pages * PGSIZE == (char*)b) {
    prev->num_pages += b->num_pages;
    prev->next = b->next;
  }

  if(kmem.use_lock)
    release(&kmem.lock);
}

void *
kalloc_contig(int n)
{
  struct free_block *curr, *prev, *best_prev, *best_curr;

  if(kmem.use_lock)
    acquire(&kmem.lock);

  prev = 0;
  curr = kmem.freelist;
  best_prev = 0;
  best_curr = 0;

  while(curr != 0) {
    if(curr->num_pages >= n) {
      if(!best_curr || curr->num_pages < best_curr->num_pages) {
        best_prev = prev;
        best_curr = curr;
      }
    }
    prev = curr;
    curr = curr->next;
  }

  if(!best_curr) {
    if(kmem.use_lock) release(&kmem.lock);
    printf(GREY "DEBUG: Failed to kalloc_contig %d pages. Memory heavily fragmented.\\n" RESET, n);
    return 0;
  }

  // Determine split type for logging
  if (n > 1) { // dont spam for 1 page kernel sizes
    if (best_curr->num_pages == n) {
      printf(MAGENTA "DEBUG kalloc_contig: PERFECT FIT. Requested %d pages. Found exact hole. No split.\\n" RESET, n);
    } else {
      printf(BLUE "DEBUG kalloc_contig: BEST FIT SPLIT. Requested %d pages. Split block of %d pages, leaving %d pages.\\n" RESET, n, best_curr->num_pages, best_curr->num_pages - n);
    }
  }

  if(best_curr->num_pages == n) {
    if(best_prev) best_prev->next = best_curr->next;
    else kmem.freelist = best_curr->next;
  } else {
    char *new_block_start = (char*)best_curr + n * PGSIZE;
    struct free_block *split = (struct free_block*)new_block_start;
    split->num_pages = best_curr->num_pages - n;
    split->next = best_curr->next;
    if(best_prev) best_prev->next = split;
    else kmem.freelist = split;
  }

  // 🔥 Initialize ref count for allocated pages
  for (int i = 0; i < n; i++) {
    ref_count[PA2IDX((char*)best_curr + i * PGSIZE)] = 1;
  }

  if(kmem.use_lock)
    release(&kmem.lock);

  memset((char*)best_curr, 5, n * PGSIZE);
  return (void*)best_curr;
}

void kfree(void *pa) { kfree_contig(pa, 1); }
void *kalloc(void) { return kalloc_contig(1); }

void
compact_memory(void)
{
  if(!kmem.use_lock) return;
  acquire(&kmem.lock);
  
  struct free_block *curr = kmem.freelist;
  int compacted = 0;

  while (curr != 0) {
    uint64 hole_start_pa = (uint64)curr;
    uint hole_size_pages = curr->num_pages;
    uint64 used_block_start_pa = hole_start_pa + (hole_size_pages * PGSIZE);
    
    if (used_block_start_pa >= PHYSTOP) break;

    if (curr->next != 0 && (uint64)curr->next == used_block_start_pa) {
      curr = curr->next;
      continue; 
    }

    uint64 pfn_used = (used_block_start_pa - KERNBASE) / PGSIZE;
    
    if (reverse_map[pfn_used].pagetable != 0 && ref_count[pfn_used] == 1) { // Only compact unshared pages for safety
      if(!compacted) {
         printf(BLUE "\\nDEBUG kernel: *** IDLE SYSTEM DETECTED. COMPACTING MEMORY ***\\n" RESET);
      }
      printf(GREY "DEBUG compact: Bubbling physical page downward [%p -> %p]\\n" RESET, (void*)used_block_start_pa, (void*)hole_start_pa);
      
      // Swap references
      int idx_hole = PA2IDX(hole_start_pa);
      int idx_used = PA2IDX(used_block_start_pa);
      int tmp_ref = ref_count[idx_hole];
      ref_count[idx_hole] = ref_count[idx_used];
      ref_count[idx_used] = tmp_ref;

      memmove((void*)hole_start_pa, (void*)used_block_start_pa, PGSIZE);

      pagetable_t pagetable = reverse_map[pfn_used].pagetable;
      uint64 va = reverse_map[pfn_used].va;
      
      pte_t *pte = walk(pagetable, va, 0);
      if (pte && (*pte & PTE_V)) {
        uint flags = PTE_FLAGS(*pte);
        *pte = PA2PTE(hole_start_pa) | flags;
      }
      
      reverse_map[(hole_start_pa - KERNBASE) / PGSIZE].pagetable = pagetable;
      reverse_map[(hole_start_pa - KERNBASE) / PGSIZE].va = va;
      reverse_map[pfn_used].pagetable = 0;
      reverse_map[pfn_used].va = 0;
      
      uint64 new_hole_start = hole_start_pa + PGSIZE;
      struct free_block *shifted = (struct free_block*)new_hole_start;
      shifted->num_pages = hole_size_pages;
      shifted->next = curr->next;
      
      if (kmem.freelist == curr) {
        kmem.freelist = shifted;
      } else {
        struct free_block *p = kmem.freelist;
        while (p->next != curr) p = p->next;
        p->next = shifted;
      }
      
      // Coalescing right side if possible
      if(shifted->next && (char*)shifted + shifted->num_pages * PGSIZE == (char*)shifted->next) {
        shifted->num_pages += shifted->next->num_pages;
        shifted->next = shifted->next->next;
      }
      
      curr = kmem.freelist;
      compacted = 1;
    } else {
       curr = curr->next;
    }
  }

  release(&kmem.lock);
  if(compacted) {
    // sfence_vma(); 
  }
}

// 🔥 Increment reference count
void
incref(uint64 pa)
{
  acquire(&kmem.lock);
  ref_count[PA2IDX(pa)]++;
  release(&kmem.lock);
}

// 🔥 Get reference count
int
getref(uint64 pa)
{
  int count;
  acquire(&kmem.lock);
  count = ref_count[PA2IDX(pa)];
  release(&kmem.lock);
  return count;
}

// 🔥 Decrement reference count
int
decref(uint64 pa)
{
  int count;
  acquire(&kmem.lock);

  int idx = PA2IDX(pa);
  if(ref_count[idx] <= 0)
    panic("decref: invalid");

  ref_count[idx]--;
  count = ref_count[idx];

  release(&kmem.lock);
  return count;
}
"""
with open("kernel/kalloc.c", "w") as f:
    f.write(kalloc_content)

print("kalloc.c fixed")

# Fix vm.c
with open("kernel/vm.c", "r") as f:
    vm_text = f.read()

# Fix uvmalloc
uvmalloc_correct = """uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz, int xperm)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}"""
vm_text = re.sub(r"uint64\s*uvmalloc\(pagetable_t pagetable, uint64 oldsz, uint64 newsz, int xperm\).*?return newsz;\n}", uvmalloc_correct, vm_text, flags=re.DOTALL)

# Fix vmfault
vmfault_correct = """uint64
vmfault(pagetable_t pagetable, uint64 va, int read)
{
  uint64 pa;
  pte_t *pte;
  struct proc *p = myproc();

  if (va >= p->sz)
    return 0;
  va = PGROUNDDOWN(va);

  pte = walk(pagetable, va, 0);

  // -------------------------------
  // CASE 1: Page not mapped (lazy alloc)
  // -------------------------------
  if(pte == 0 || (*pte & PTE_V) == 0){
    uint64 mem = (uint64)kalloc();
    if(mem == 0)
      return 0;

    memset((void*)mem, 0, PGSIZE);

    if(mappages(pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0){
      kfree((void*)mem);
      return 0;
    }
    return mem;
  }

  // -------------------------------
  // CASE 2: COW page fault
  // -------------------------------
  if((*pte & PTE_COW) && !(*pte & PTE_W)){
    pa = PTE2PA(*pte);
    int ref = getref(pa);

    if(ref > 1){
      decref(pa);
      char *mem = kalloc();
      if(mem == 0)
        return 0;
      memmove(mem, (char*)pa, PGSIZE);
      *pte = PA2PTE(mem) | PTE_W | PTE_U | PTE_R | PTE_V;
    } else {
      *pte |= PTE_W;
      *pte &= ~PTE_COW;
    }
    
    // Always refresh rmap so compaction knows about the page!
    record_rmap(PTE2PA(*pte), pagetable, va);

    return PTE2PA(*pte);
  }

  return 0;
}"""
vm_text = re.sub(r"uint64\s*vmfault\(pagetable_t pagetable, uint64 va, int read\).*?return 0;\n}", vmfault_correct, vm_text, flags=re.DOTALL)

with open("kernel/vm.c", "w") as f:
    f.write(vm_text)

print("vm.c fixed")

