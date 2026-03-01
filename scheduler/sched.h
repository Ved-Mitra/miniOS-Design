// scheduler/sched.h — MiniOS Dynamic Priority Scheduler
// Owner: Taksh Mehta
//
// This header contains all scheduler-specific constants and (in Sprint 2+)
// function declarations for the priority scheduling module.
//
// Include this file in proc.c and any future scheduler source files.
// Do NOT include this in non-scheduler kernel files directly; use param.h
// for system-wide constants.

#ifndef SCHED_H
#define SCHED_H

// -----------------------------------------------------------------
// Priority scheduler tuning parameters (REQ-SCH-2, REQ-SCH-3)
//
// SCHED_ALPHA  — priority gained per scheduler cycle while WAITING
//                (aging: prevents starvation, satisfies REQ-SCH-2)
//
// SCHED_BETA   — priority lost per scheduler cycle while RUNNING
//                (CPU-bound penalty, satisfies REQ-SCH-3)
//
// SCHED_DEFAULT — initial priority assigned to every new process
//                 All processes start equal so behaviour is identical
//                 to round-robin until priorities diverge.
//
// SCHED_MAX    — priority ceiling (prevents runaway aging)
// SCHED_MIN    — priority floor  (prevents negative priority)
//
// NOTE: Alpha and beta are provisional (SRS TBD item).
//       Final values will be determined empirically in Sprint 3
//       after running schedtest.
// -----------------------------------------------------------------
#define SCHED_ALPHA      1    // aging increment per wait cycle
#define SCHED_BETA       2    // CPU penalty decrement per run cycle
#define SCHED_DEFAULT   60    // starting priority for all new processes
#define SCHED_MAX      100    // maximum allowed priority
#define SCHED_MIN        0    // minimum allowed priority

#endif // SCHED_H
