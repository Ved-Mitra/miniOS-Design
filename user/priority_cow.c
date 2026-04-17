#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define SIZE 1000

// -------------------- CoW TEST --------------------
void cow_test() {
    printf("\n===== CoW TEST START =====\n");

    int *arr = (int*) sbrk(sizeof(int) * 5);

    for(int i = 0; i < 5; i++){
        arr[i] = i;
    }

    int pid = fork();

    if(pid == 0){
        // Child modifies memory
        printf("[Child] Before write: arr[0] = %d\n", arr[0]);

        arr[0] = 999;   // 🔥 should trigger CoW

        printf("[Child] After write: arr[0] = %d\n", arr[0]);

        exit(0);
    } else {
        wait(0);

        // Parent checks its own memory
        printf("[Parent] After child write: arr[0] = %d\n", arr[0]);

        if(arr[0] == 0){
            printf("✅ CoW SUCCESS: Parent memory unchanged\n");
        } else {
            printf("❌ CoW FAILED: Memory overwritten\n");
        }
    }

    printf("===== CoW TEST END =====\n\n");
}

// -------------------- CPU-BOUND --------------------
void cpu_bound() {
    printf("[CPU] Started (should get penalized)\n");

    volatile long long x = 0;

    for(int i = 0; i < 5; i++){
        for(int k = 0; k < 5; k++){
            for(long long j = 0; j < 1000000; j++){
                x += j;
            }
            pause(1);   // force scheduler via pause syscall
        }

        printf("[CPU] Iteration %d\n", i);
    }

    printf("[CPU] Finished\n");
}

// -------------------- IO-BOUND --------------------
void io_bound() {
    printf("[IO] Started (priority boost expected)\n");

    for(int i = 0; i < 8; i++){
        printf("[IO] Iteration %d\n", i);
        pause(2);   // small sleep → frequent re-entry
    }

    printf("[IO] Finished\n");
}

// -------------------- SHORT JOB --------------------
void short_job() {
    printf("[SHORT] Quick execution\n");
}

// -------------------- SCHEDULER TEST --------------------
void scheduler_test() {
    printf("\n===== SCHEDULER TEST START =====\n");

    if(fork() == 0){
        cpu_bound();
        exit(0);
    }

    if(fork() == 0){
        io_bound();
        exit(0);
    }

    if(fork() == 0){
        short_job();
        exit(0);
    }

    // wait for all
    wait(0);
    wait(0);
    wait(0);

    printf("===== SCHEDULER TEST END =====\n\n");
}

// -------------------- MAIN --------------------
int main() {
    printf("===== GLOBAL TEST START =====\n");

    cow_test();
    scheduler_test();

    printf("===== GLOBAL TEST END =====\n");
    exit(0);
}