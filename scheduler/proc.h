// proc.h — per-process and per-CPU state
// MiniOS extension: priority scheduling fields added to struct proc.

// Per-CPU state
struct cpu {
  uchar apicid;                // Local APIC ID
  struct context *scheduler;   // swtch() here to enter scheduler
  struct taskstate ts;         // Used by x86 to find stack for interrupt
  struct segdesc gdt[NSEGS];   // x86 global descriptor table
  volatile uint started;       // Has the CPU started?
  int ncli;                    // Depth of pushcli nesting.
  int intena;                  // Were interrupts enabled before pushcli?
  struct proc *proc;           // The process running on this cpu or null
};

extern struct cpu cpus[NCPU];
extern int ncpu;

//PAGEBREAK: 17
// Saved registers for kernel context switches.
// Don't need to save all the segment registers (%cs, etc),
// because they are constant across kernel contexts.
// Don't need to save %eax, %ecx, %edx, because the
// x86 convention is that the caller has saved them.
// Contexts are stored at the bottom of the stack they
// describe; the stack pointer is the address of the context.
// The layout of the context matches the layout of the stack in swtch.S
// at the "Switch stacks" comment. Switch doesn't save eip explicitly,
// but it is on the stack and allocproc() manipulates it.
struct context {
  uint edi;
  uint esi;
  uint ebx;
  uint ebp;
  uint eip;
};

enum procstate { UNUSED, EMBRYO, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// Per-process state
struct proc {
  uint sz;                     // Size of process memory (bytes)
  pde_t* pgdir;                // Page table
  char *kstack;                // Bottom of kernel stack for this process
  enum procstate state;        // Process state
  int pid;                     // Process ID
  struct proc *parent;         // Parent process
  struct trapframe *tf;        // Trap frame for current syscall
  struct context *context;     // swtch() here to run process
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)

  // -----------------------------------------------------------------
  // MiniOS: Dynamic Priority Scheduler fields (REQ-SCH-1)
  //
  //   priority   — current dynamic priority of this process.
  //                Ranges from SCHED_MIN (0) to SCHED_MAX (100).
  //                Higher value = higher scheduling urgency.
  //                Initialised to SCHED_DEFAULT (60) in allocproc().
  //
  //   wait_ticks — total scheduler cycles this process has spent in
  //                the RUNNABLE state without being selected.
  //                Used to diagnose starvation (REQ-SCH-4).
  //
  //   cpu_ticks  — total scheduler cycles this process has spent
  //                actively RUNNING on the CPU.
  //                Used to identify CPU-bound behaviour (REQ-SCH-3).
  // -----------------------------------------------------------------
  int priority;                // Dynamic priority (SCHED_MIN–SCHED_MAX)
  int wait_ticks;              // Ticks waiting in RUNNABLE state
  int cpu_ticks;               // Ticks spent running on CPU
};

// Process memory is laid out contiguously, low addresses first:
//   text
//   original data and bss
//   fixed-size stack
//   expandable heap
