#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// bench_sched.c: Benchmark for priority scheduler quantification
// Spawns multiple processes with different workloads.

#define NPROCS 6
#define LO_ITER 1000000
#define HI_ITER 5000000

void
work(int id, int iterations)
{
  volatile int x = 0;
  for(int i = 0; i < iterations; i++){
    x = x + i;
  }
}

int
main(int argc, char *argv[])
{
  printf("Benchmark starting with %d processes...\n", NPROCS);

  for(int i = 0; i < NPROCS; i++){
    int pid = fork();
    if(pid < 0){
      printf("fork failed\n");
      exit(1);
    }
    if(pid == 0){
      // Child
      if(i % 2 == 0){
        // High load
        work(i, HI_ITER);
      } else {
        // Low load
        work(i, LO_ITER);
      }
      exit(0);
    }
  }

  // Wait for all children
  for(int i = 0; i < NPROCS; i++){
    wait(0);
  }

  printf("Benchmark finished.\n");
  exit(0);
}
