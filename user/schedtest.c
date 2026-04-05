#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

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

  printf(CYAN "Starting Scheduler Test: %d processes competing for CPU...\n" RESET, NCHILD);
  printf(YELLOW "Observe 'pri' and 'cpu' changes in kernel logs.\n\n" RESET);

  for(int i = 0; i < NCHILD; i++){
    int pid = fork();
    if(pid < 0){
      printf(RED "fork failed\n" RESET);
      exit(1);
    }
    if(pid == 0){
      // Child: waste CPU
      cpu_waste();
      printf(GREEN "Child %d (pid %d) finished.\n" RESET, i, getpid());
      exit(0);
    }
    pids[i] = pid;
  }

  printf(YELLOW "Children PIDs: " RESET);
  for(int i = 0; i < NCHILD; i++) printf(YELLOW "%d " RESET, pids[i]);
  printf("\n");
  for(int i = 0; i < NCHILD; i++){
    wait(0);
  }

  printf(GREEN "\nScheduler Test Complete.\n" RESET);
  exit(0);
}
