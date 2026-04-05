#include "kernel/types.h"
#include "user/user.h"
#include "user/color.h"

#define DEPTH 5

int
main(void)
{
  printf(CYAN "=== COW Fork Explosion Test ===\n" RESET);

  int *shared = (int*)sbrk(4096);
  *shared = 1;

  for(int i = 0; i < DEPTH; i++){
    int pid = fork();
    if(pid < 0){
      printf(RED "fork failed\n" RESET);
      exit(1);
    }
  }

  // all processes modify
  *shared += 1;

  printf(YELLOW "PID %d value: %d\n" RESET, getpid(), *shared);

  // wait only in parent
  for(int i = 0; i < DEPTH; i++)
    wait(0);

  printf(GREEN "=== PASS ===\n" RESET);
  exit(0);
}