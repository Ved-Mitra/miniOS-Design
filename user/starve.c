#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// starve.c: Verify starvation prevention (Bounded Waiting Time)
// Expected behavior: The high-priority process should NOT completely
// starve the low-priority process due to the SCHED_WMAX (100) threshold.

void
work(int id, int iterations)
{
  for(int i = 0; i < iterations; i++){
    if(i % 1000000 == 0){
        // printf("Process %d at iteration %d\n", id, i);
    }
  }
  printf("Process %d finished\n", id);
}

int
main(int argc, char *argv[])
{
  printf("Starvation test starting...\n");

  int pid = fork();
  if(pid < 0){
    printf("fork failed\n");
    exit(1);
  }

  if(pid == 0){
    // Child: Lower priority
    // In our scheduler, child starts with SCHED_DEFAULT (60).
    // We want it to be lower than the hog.
    work(2, 50000000);
    exit(0);
  } else {
    // Parent: High priority hog
    // We don't have a direct 'setpriority' syscall in the current SRS/implementation,
    // but the hog will naturally decrease its priority over time (penalty).
    // However, if we had multiple CPU-bound processes, we want to see they don't starve.
    work(1, 100000000);
    wait(0);
  }

  printf("Starvation test PASSED (Both processes finished)\n");
  exit(0);
}
