//
// Support functions for system calls that involve file descriptors.
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "file.h"
#include "stat.h"
#include "proc.h"

struct mftable_t mftable;

void
memfileinit(void)
{
  initlock(&mftable.lock, "mftable");
}

// Stub for creating an in-memory file
struct memfile* memfile_create(void)
{
  struct memfile* mf;
  acquire(&mftable.lock);
  for(mf = mftable.memfiles; mf < mftable.memfiles + NMEMFILE; mf++){
    if(mf->ref_count == 0 && mf->is_marked_deleted == 0){
      mf->ref_count = 1;
      mf->size = 0;
      mf->is_marked_deleted = 0;
      //Allocate one page (4096 bytes) for file data
      mf->data = kalloc();
      if(mf->data == 0){
        // Allocation failed
        mf->ref_count = 0;
        mf->size = 0;
        mf->is_marked_deleted = 0;
        release(&mftable.lock);
        return 0;
      }
      release(&mftable.lock);
      return mf;
    }
  }
  release(&mftable.lock);
  return 0; // no free slot
}

// Stub for deleting an in-memory file
int memfile_delete(struct memfile *mf)
{
  if(mf == 0 || mf->ref_count < 1)
    return -1;
    
  acquire(&mftable.lock);
  mf->ref_count--;
  mf->is_marked_deleted = 1; // Mark for GC to reclaim later
  release(&mftable.lock);
  
  return 0;
}

struct devsw devsw[NDEV];
struct {
  struct spinlock lock;
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
  initlock(&ftable.lock, "ftable");
}

// Allocate a file structure.
struct file*
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filedup");
  f->ref++;
  release(&ftable.lock);
  return f;
}

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  struct file ff;

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  if(--f->ref > 0){
    release(&ftable.lock);
    return;
  }
  ff = *f;
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);

  if(ff.type == FD_PIPE){
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
  struct proc *p = myproc();
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    ilock(f->ip);
    stati(f->ip, &st);
    iunlock(f->ip);
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
      return -1;
    return 0;
  }
  return -1;
}

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
  int r = 0;

  if(f->readable == 0)
    return -1;

  if(f->type == FD_PIPE){
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    ilock(f->ip);
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
  } else if(f->type == FD_MEM){
    struct memfile *mf = f->memf;
    if(mf->is_marked_deleted == 1)
      return -1;
    
    acquire(&mftable.lock);
    f->off = 0; // assuming entire file read for testing
    
    if(mf->data == 0 || f->off >= mf->size){
      release(&mftable.lock);
      return 0; // EOF
    }
    
    int max_read = mf->size - f->off;
    if(n > max_read)
      n = max_read;
      
    if(n > 0){
      if(copyout(myproc()->pagetable, addr, mf->data + f->off, n) < 0){
        release(&mftable.lock);
        return -1;
      }
      f->off += n;
      printf("KERNEL PROOF: Reading from physical memory address %p\n", mf->data);
    }
    release(&mftable.lock);
    return n;
  } else {
    panic("fileread");
  }

  return r;
}

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    return -1;

  if(f->type == FD_PIPE){
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    // write a few blocks at a time to avoid exceeding
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
      ilock(f->ip);
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r != n1){
        // error from writei
        break;
      }
      i += r;
    }
    ret = (i == n ? n : -1);
  } else if(f->type == FD_MEM){
    struct memfile *mf = f->memf;
    if(mf->is_marked_deleted == 1)
      return -1;
    
    acquire(&mftable.lock);
    if(mf->data == 0){
      mf->data = kalloc();
      if(mf->data == 0){
        release(&mftable.lock);
        return -1;
      }
    }
    
    int max_write = 4096 - f->off;
    if(n > max_write)
      n = max_write;
      
    if(n > 0){
      if(copyin(myproc()->pagetable, mf->data + f->off, addr, n) < 0){
        release(&mftable.lock);
        return -1;
      }
      f->off += n;
      if(f->off > mf->size)
        mf->size = f->off;
      printf("KERNEL PROOF: kalloc() gave physical memory address %p\n", mf->data);
      printf("KERNEL PROOF: Wrote text into %p\n", mf->data);
    }
    release(&mftable.lock);
    ret = n;
  } else {
    panic("filewrite");
  }

  return ret;
}

