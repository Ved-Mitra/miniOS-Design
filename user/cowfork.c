#include "kernel/types.h"
#include "user/user.h"

#define DEPTH 5

int
main(void)
{
  printf("=== COW Fork Explosion Test ===\n");

  int *shared = (int*)sbrk(4096);
  *shared = 1;

  for(int i = 0; i < DEPTH; i++){
    int pid = fork();
    if(pid < 0){
      printf("fork failed\n");
      exit(1);
    }
  }

  // all processes modify
  *shared += 1;

  printf("PID %d value: %d\n", getpid(), *shared);

  // wait only in parent
  for(int i = 0; i < DEPTH; i++)
    wait(0);

  printf("=== PASS ===\n");
  exit(0);
}