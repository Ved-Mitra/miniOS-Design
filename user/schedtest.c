#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define NCHILD 3
#define WORKLOAD 100000000LL

void
cpu_waste()
{
  long long count = 0;
  while(count < WORKLOAD){
    count++;
  }
}

int
main(int argc, char *argv[])
{
  int pids[NCHILD];

  printf("Starting Scheduler Test: %d processes competing for CPU...\n", NCHILD);
  printf("Observe 'pri' and 'cpu' changes in kernel logs.\n\n");

  for(int i = 0; i < NCHILD; i++){
    int pid = fork();
    if(pid < 0){
      printf("fork failed\n");
      exit(1);
    }
    if(pid == 0){
      // Child: waste CPU
      cpu_waste();
      printf("Child %d (pid %d) finished.\n", i, getpid());
      exit(0);
    }
    pids[i] = pid;
  }

  printf("Children PIDs: ");
  for(int i = 0; i < NCHILD; i++) printf("%d ", pids[i]);
  printf("\n");
  for(int i = 0; i < NCHILD; i++){
    wait(0);
  }

  printf("\nScheduler Test Complete.\n");
  exit(0);
}
