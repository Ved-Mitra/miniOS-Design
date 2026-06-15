# Operating System Metrics Methodology

This document outlines the testing methodology used to gather performance and overhead metrics for the MiniOS subsystems.

## 1. Copy-on-Write (COW) Fork
**Objective:** Measure the efficiency of physical memory sharing during process creation.
**Methodology:** 
We instrumented `kernel/vm.c` by adding global atomic counters to track two events:
1. `uvmcopy` (Fork event): Counted the number of physical pages shared by mapping them into the child page table without duplicating data.
2. `vmfault` (Page Fault event): Counted the number of times a shared page was written to, triggering a COW page duplication.
The `cowtest` and `cowstress` utilities were executed in QEMU. The kernel logged the counts, demonstrating the ratio of shared pages to forcefully copied pages.

## 2. Garbage Collection (GC)
**Objective:** Measure the background reclamation of deleted in-memory file resources.
**Methodology:**
We instrumented the `garbage_collect` function in `kernel/gc.c` to print a counter every time a memfile structure with 0 references and marked for deletion was successfully reclaimed.
The `mt_sprint2` test was run to create, write, and delete an in-memory file (`sys_memdelete`). The system was then put into an idle state (`idle_start_tick >= 5` ticks) to trigger the background GC, which successfully logged the reclaimed file count.

## 3. Dynamic Memory Compaction
**Objective:** Validate the system's ability to eliminate external fragmentation.
**Methodology:** 
The `memcomp_test` user program was executed to intentionally fragment physical memory by forking 10 children and selectively terminating them to create holes. A small block was then allocated to pin memory, and the system was paused. The test verified that despite severe initial fragmentation, a large contiguous 12-page (48KB) block could be successfully allocated (`sbrk(12 * 4096)`) after the kernel's memory management dynamically coalesced and organized physical pages.