# MiniOS — Sprint Plan

**Project:** MiniOS (xv6 Extension)  
**Platform:** xv6 kernel running on QEMU x86 emulator  
**Date:** March 2026  
**Team:**

| # | Member | Feature Ownership |
|---|---|---|
| 1 | Taksh Mehta | Dynamic Priority Scheduler |
| 2 | Aditya Sharma | Paging + Copy-On-Write (lead) |
| 3 | Mayank Tiwari | Paging + Copy-On-Write (support) + Integration |
| 4 | Ved Mitra Verma | Hybrid IPC (Mailbox + Shared Memory) |

---

## Feature → SRS Requirements Mapping

| Feature | SRS Requirements |
|---|---|
| Dynamic Priority Scheduling | REQ-SCH-1, REQ-SCH-2, REQ-SCH-3, REQ-SCH-4 |
| Paging with Copy-On-Write | REQ-MEM-1, REQ-MEM-2, REQ-MEM-3, REQ-MEM-4 |
| Hybrid IPC | REQ-IPC-1, REQ-IPC-2, REQ-IPC-3, REQ-IPC-4 |

---

## Sprint 1 — Foundation & Environment Setup
**Duration:** Week 1  
**Goal:** Everyone has a working dev environment. All three features have `struct` extensions and stub code in place. No regressions to base xv6.

### Tasks

**Taksh — Priority Scheduler**
- [ ] Study `proc.c`, `trap.c`, `sched()` flow in xv6
- [ ] Add `priority`, `wait_ticks`, and `cpu_ticks` fields to `struct proc` in `proc.h`
- [ ] Create stub `scheduler()` that replaces round-robin (does not change behaviour yet)
- [ ] Document chosen initial values for α and β (to be tuned in Sprint 3)

**Aditya — COW Memory (Lead)**
- [ ] Study `vm.c`, `kalloc.c`, and `fork()` in xv6
- [ ] Understand the page table entry (PTE) layout for x86
- [ ] Add `ref_count[PHYSTOP/PGSIZE]` array stub to `kalloc.c`
- [ ] Draft design doc for COW page fault flow

**Mayank — COW Memory (Support) + Build**
- [ ] Set up QEMU + xv6 build system and verify it works on all team machines
- [ ] Write shared `Makefile` patch and document build steps in `README.md`
- [ ] Assist Aditya: add stub page fault handler entry in `trap.c` for COW

**Ved Mitra — Hybrid IPC**
- [ ] Study `pipe.c`, `sysfile.c`, `syscall.c` in xv6
- [ ] Design `struct mailbox` (message queue, capacity, owner process)
- [ ] Add stub syscalls `send(mbx, msg)` and `recv(mbx, buf)` to `syscall.c` / `sysproc.c`
- [ ] Add shared memory stub syscalls `shmget()` / `shmrelease()`

### Sprint 1 Deliverables
- [ ] xv6 builds and boots on all team machines (Mayank)
- [ ] `struct proc` extended with priority fields (Taksh)
- [ ] `ref_count[]` array stub committed (Aditya)
- [ ] Mailbox struct + 4 syscall stubs exist and compile (Ved Mitra)
- [ ] Sprint 1 demo: kernel boots, no regressions

---

## Sprint 2 — Core Logic Implementation
**Duration:** Week 2  
**Goal:** Each feature has its primary logic implemented independently. Basic functionality is demonstrable via kernel print logs.

### Tasks

**Taksh — Priority Scheduler**
- [ ] Implement `scheduler()` with dynamic priority selection:
  - Select the RUNNABLE process with the highest `priority`
  - On each timer tick: increment `wait_ticks` for waiting procs, increment `cpu_ticks` for running proc
- [ ] Apply aging rule: `priority += α` for each waiting tick (REQ-SCH-2)
- [ ] Apply CPU-bound penalty: `priority -= β` for each CPU tick (REQ-SCH-3)
- [ ] Add round-robin tie-breaking for equal-priority processes
- [ ] Log priority changes with `cprintf` for debugging

**Aditya — COW Memory (Lead)**
- [ ] Modify `fork()` in `proc.c`:
  - Map parent's pages into child's page table (read-only for both)
  - Mark PTEs with a custom COW bit (`PTE_COW`)
  - Increment `ref_count` for each shared page
- [ ] Implement `kref()` and `kunref()` helpers in `kalloc.c`

**Mayank — COW Memory (Support)**
- [ ] Implement COW page fault handler in `trap.c`:
  - Detect write fault on a COW page
  - Allocate new physical page via `kalloc()`
  - Copy data, update PTE to point to new page (writable)
  - Call `kunref()` on old page; free if `ref_count` reaches 0
- [ ] Write `cowtest.c` user-space test: fork, then write to shared variable

**Ved Mitra — Hybrid IPC**
- [ ] Implement kernel mailbox in `ipc.c`:
  - Fixed-size circular message queue per mailbox
  - `send()`: enqueue message, wake sleeping receiver
  - `recv()`: dequeue or sleep until message arrives
- [ ] Implement blocking semantics using `sleep()` / `wakeup()` primitives
- [ ] Stub out shared memory map: `shmget()` allocates pages, returns shared region descriptor

### Sprint 2 Deliverables
- [ ] Scheduler selects correct process (verified via `cprintf` priority logs) (Taksh)
- [ ] `fork()` shares pages without duplication, `ref_count` increments (Aditya)
- [ ] COW page fault correctly duplicates page (Mayank — `cowtest` passes)
- [ ] Two processes exchange messages via mailbox (Ved Mitra — print verified)

---

## Sprint 3 — Integration & Synchronization
**Duration:** Week 3  
**Goal:** All three features work together in the xv6 kernel. Edge cases, race conditions, and cross-feature interactions are resolved.

### Tasks

**Taksh — Priority Scheduler**
- [ ] Verify bounded wait time: stress test with CPU-hog + IO-bound processes
- [ ] Finalize and document α and β values (update SRS TBD items)
- [ ] Handle IPC-blocked processes: ensure `priority` aging continues while process is sleeping in `recv()` (coordinate with Ved Mitra)
- [ ] Handle COW child processes: verify priority fields are correctly initialized in forked child (coordinate with Aditya)

**Aditya — COW Memory (Lead)**
- [ ] Handle edge case: when `ref_count` hits 0, page is returned to `kalloc` free list
- [ ] Test `fork()` → `exec()` chain: verify pages are released properly on `exec`
- [ ] Code review pass on Mayank's fault handler for correctness
- [ ] Add `kref()`/`kunref()` spinlock protection (coordinate with Mayank)

**Mayank — COW Memory (Support) + Integration**
- [ ] Add spinlock around `ref_count` access in `kalloc.c` to prevent race conditions
- [ ] Integration test: run scheduler + COW simultaneously (fork many processes, write data)
- [ ] Fix any kernel panics discovered during combined testing
- [ ] Assist with final integration Makefile (add `ipctest`, `cowtest`, `schedtest` to build)

**Ved Mitra — Hybrid IPC**
- [ ] Implement shared memory isolation (REQ-IPC-3): kernel enforces process ownership check on every `shm` access
- [ ] Implement synchronization primitive for shared memory (REQ-IPC-4): add a simple mutex (test-and-set spinlock or semaphore) accessible to user processes via syscall
- [ ] Test: unauthorized process access to shared region must return error, not panic
- [ ] Coordinate with Taksh: sleeping processes in `recv()` must still age in priority queue

### Cross-Feature Coordination Points

| Touchpoint | Who | Risk | Resolution |
|---|---|---|---|
| `struct proc` layout | Taksh + Aditya | Field conflicts | Agree on struct layout in Sprint 1; lock it by Sprint 3 |
| `trap.c` handlers | Taksh (timer tick) + Mayank (COW fault) | Handler routing | Use separate `T_PGFLT` and `T_IRQ0+IRQ_TIMER` conditions |
| Sleep/wakeup + priority | Taksh + Ved Mitra | Priority stale while sleeping | Taksh to age sleeping procs in scheduler loop |

### Sprint 3 Deliverables
- [ ] CPU-hog is deprioritized; long-waiting process promoted (Taksh — logged trace)
- [ ] Concurrent writes after `fork()` do not corrupt memory (Aditya + Mayank)
- [ ] Unauthorized shared memory access returns error (Ved Mitra)
- [ ] All three subsystems run simultaneously — no kernel panics

---

## Sprint 4 — Testing, Polish & Demo
**Duration:** Week 4  
**Goal:** Full system validation. Write test programs, produce demo, finalize documentation.

### Tasks

**Taksh — Priority Scheduler Testing**
- [ ] Write `schedtest.c`: spawn N processes with varied CPU/IO patterns
  - Measure and log per-process wait time
  - Assert no process waits beyond a configurable threshold (bounded wait — REQ-SCH-4)
  - Print priority traces over time to verify aging and penalty
- [ ] Document final α and β values in `README.md`

**Aditya — COW Testing & Docs**
- [ ] Stress `memtest.c`: 50+ concurrent `fork()` + write operations
- [ ] Verify physical memory usage: COW must use fewer pages than naive copy
- [ ] Add inline comments to `vm.c`, `kalloc.c`, `proc.c` explaining COW changes
- [ ] Update SRS TBD: QEMU memory configuration

**Mayank — Integration & Final QA**
- [ ] Full integration test: run `schedtest` + `cowtest` + `ipctest` concurrently
- [ ] Identify and fix any remaining race conditions
- [ ] Run QEMU with memory constraints to validate COW efficiency
- [ ] Help polish diagrams in final report

**Ved Mitra — IPC Testing & Docs**
- [ ] Write `ipctest.c`: producer/consumer via mailbox + shared memory under load
  - Verify messages are not lost or duplicated
  - Verify isolation: process B cannot read process A's shared region
- [ ] Finalize syscall API documentation (function signatures, error codes)
- [ ] Update SRS TBD: synchronization primitive specs

**All Members**
- [ ] Cross-feature code review: each person reviews another's feature code
- [ ] Update `README.md` with build, run, and test instructions
- [ ] Prepare QEMU live demo (boot → run all three tests → show output)
- [ ] Final report: fill in all SRS TBD items with actual decisions

### Sprint 4 Deliverables
- [ ] `schedtest` passes: no starvation, priority traces look correct (Taksh)
- [ ] `cowtest` + `memtest` pass: memory is reclaimed, no corruption (Aditya + Mayank)
- [ ] `ipctest` passes: messaging + shared memory work under load (Ved Mitra)
- [ ] No kernel panics under combined workload (Mayank)
- [ ] QEMU demo ready for presentation (All)

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| α/β values cause priority instability | Medium | Medium | Start with α=1, β=2; tune empirically in Sprint 3 |
| COW race condition on `ref_count` | High | High | Per-page spinlocks from Sprint 3 |
| IPC shared memory isolation bug | Medium | High | Kernel bounds-check on every access |
| `trap.c` conflict between Taksh & Mayank | Medium | Medium | Separate handler branches by trap number |
| QEMU memory config unknown (SRS TBD) | Low | Medium | Agree on config in Sprint 1 |

---

## Summary Timeline

| Week | Sprint | Primary Focus |
|---|---|---|
| Week 1 | Sprint 1 | Env setup, struct extensions, stubs |
| Week 2 | Sprint 2 | Core logic, per-feature implementation |
| Week 3 | Sprint 3 | Integration, edge cases, synchronization |
| Week 4 | Sprint 4 | Testing, polish, demo |

---

*Last updated: March 2026 — MiniOS Team*
