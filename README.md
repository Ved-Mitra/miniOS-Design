# MiniOS (Version 1.0)

MiniOS is a pedagogical operating system built as an advanced extension of the [MIT xv6](https://pdos.csail.mit.edu/6.1810/) UNIX-like teaching OS. It introduces modern operating system concepts including dynamic scheduling, advanced memory management, and specialized user space applications.

## 🚀 Core Features

MiniOS replaces standard xv6 components with advanced subsystems:

1. **Dynamic Priority Scheduling:** 
   Preemptive scheduling algorithm featuring aging to prevent starvation. It dynamically adjusts process priorities based on CPU usage (applying a penalty for CPU-bound processes) and waiting time (applying an aging increment).

2. **Copy-On-Write (COW) Fork:**
   Optimized process creation where the parent and child share physical memory pages upon `fork()`. Pages are only duplicated when a process attempts to modify them, managed via a robust reference counting mechanism.

3. **Advanced File Management System:**
   Dynamic file storage handling creation, reading, writing, and deletion of files in dynamically allocated memory blocks.

4. **Garbage Collection:**
   Automatic memory reclamation subsystem that detects unused file blocks and cleans up memory during system idle periods to minimize performance impact.

5. **Dynamic Memory Compaction:**
   Eliminates external fragmentation caused by file deletions by reorganizing physical memory and updating internal file references dynamically.
6. **Log Keeper:**
   Robust logging mechanism (`logkeeper`) designed to reliably record system events, track operations, and assist in debugging and stress testing across the OS.
<!-- ## 🎮 User Applications

MiniOS includes interactive user-space applications demonstrating its capabilities:
- **Automatic Quiz System:** A fully functional interactive terminal quiz application.
- **Snake Game:** The classic arcade game built for the MiniOS terminal.
- **Tetris:** A terminal-based implementation of Tetris. -->

## 🛠⚙️ Environment & Tech Stack

- **Target Architecture:** RISC-V / x86 Architecture
- **Emulator:** QEMU
- **Languages:** C, Assembly
- **Build Tools:** GNU Toolchain (gcc, ld, make)

## 🏗️ Building and Running MiniOS

Ensure you have the required RISC-V or x86 toolchain installed, QEMU (e.g., `qemu-system-riscv64` or `qemu-system-i386`), and Python 3.

1. Clone the repository and navigate to the project root.
2. Compile and run the OS using the custom runner script:
   ```bash
   python run_os.py
   ```
3. To view available commands once booted, explore the user space programs or refer to system binaries (e.g., `help` if implemented).

## 👥 Contributors

MiniOS Version 1.0 core subsystems were developed by:
- **Taksh Mehta:** Dynamic Priority Scheduling
- **Aditya Sharma:** Paging with Copy-On-Write (COW)
- **Ved Mitra Verma:** File Management System & Garbage Collection
- **Mayank Tiwari:** Dynamic Memory Compaction

---
*XV6 ACKNOWLEDGMENTS: xv6 is inspired by John Lions's Commentary on UNIX 6th Edition. MiniOS builds upon the foundational work provided by the MIT PDOS group.*
