#define NMEMFILE     50 // Maximum number of in-memory files

struct file {
  enum { FD_NONE, FD_PIPE, FD_INODE, FD_DEVICE, FD_MEM } type;
  int ref; // reference count
  char readable;
  char writable;
  struct pipe *pipe; // FD_PIPE
  struct inode *ip;  // FD_INODE and FD_DEVICE
  struct memfile *memf; 
  uint off;          // FD_INODE
  short major;       // FD_DEVICE
};

// In-memory file structure for MiniOS
struct memfile {
  uint ref_count;      // Number of open references
  uint size;           // Size of the file in bytes
  char *data;          // Pointer to dynamically allocated memory block
  int is_marked_deleted;  // 1 if file is deleted but memory not yet collected
};

struct mftable_t {
  struct spinlock lock;
  struct memfile memfiles[NMEMFILE];
};

extern struct mftable_t mftable;

#define major(dev)  ((dev) >> 16 & 0xFFFF)
#define minor(dev)  ((dev) & 0xFFFF)
#define	mkdev(m,n)  ((uint)((m)<<16| (n)))

// in-memory copy of an inode
struct inode {
  uint dev;           // Device number
  uint inum;          // Inode number
  int ref;            // Reference count
  struct sleeplock lock; // protects everything below here
  int valid;          // inode has been read from disk?

  short type;         // copy of disk inode
  short major;
  short minor;
  short nlink;
  uint size;
  uint addrs[NDIRECT+1];
};

// map major device number to device functions.
struct devsw {
  int (*read)(int, uint64, int);
  int (*write)(int, uint64, int);
};

extern struct devsw devsw[];

#define CONSOLE 1
