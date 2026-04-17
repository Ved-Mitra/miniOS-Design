// kernel/sched.h — MiniOS Dynamic Priority Scheduler (RISC-V)
//
// This header contains all scheduler-specific constants.
// Ported from x86 to RISC-V.

#ifndef SCHED_H
#define SCHED_H

// -----------------------------------------------------------------
// Priority scheduler tuning parameters (REQ-SCH-2, REQ-SCH-3)
// -----------------------------------------------------------------
#define SCHED_ALPHA      5    // aging increment per wait cycle     (REQ-SCH-6; range 0-5,   REQ-SCH-7)
#define SCHED_BETA       10    // CPU penalty decrement per run cycle (REQ-SCH-6; range 0-10,  REQ-SCH-7)
#define SCHED_DEFAULT   60    // starting priority for all new processes
#define SCHED_MAX      100    // maximum allowed priority
#define SCHED_MIN        0    // minimum allowed priority
#define SCHED_WMAX     50    // maximum allowed waiting ticks (REQ-SCH-4, NFR-PERF-1)

// -----------------------------------------------------------------
// CPU-bound detection window parameters (REQ-SCH-5, REQ-SCH-6, REQ-SCH-7)
// -----------------------------------------------------------------
#define SCHED_TCPU_MAX  1   // CPU-bound tick threshold per window (REQ-SCH-6; range 1-100,  REQ-SCH-7)
#define SCHED_W         50    // scheduling window width in cycles   (REQ-SCH-6; range 10-500, REQ-SCH-7)

#endif // SCHED_H
