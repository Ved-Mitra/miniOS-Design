#include "kernel/types.h"
#include "user/user.h"
#include "user/color.h"
#include "pgsize.h"

#define NCHILD 5
#define ITER 1000
#define PGSIZE 4096
int
main(void)
{
  printf(CYAN "=== COW Concurrent Write Stress Test ===\n" RESET);

  // allocate memory (will be shared after fork)
  int *shared = (int *)sbrk(PGSIZE);
  if(shared == (void*)-1){
    printf(RED "sbrk failed\n" RESET);
    exit(1);
  }

  *shared = 0;

  // create multiple children
  for(int i = 0; i < NCHILD; i++){
    int pid = fork();
    if(pid < 0){
      printf(RED "fork failed\n" RESET);
      exit(1);
    }

    if(pid == 0){
      // child: repeatedly write
      for(int j = 0; j < ITER; j++){
        *shared = i * 1000 + j;
      }
      exit(0);
    }
  }

  // parent also writes
  for(int j = 0; j < ITER; j++){
    *shared = 9999 + j;
  }

  // wait for all children
  for(int i = 0; i < NCHILD; i++){
    wait(0);
  }

  printf(YELLOW "Final value: %d\n" RESET, *shared);

  printf(GREEN "=== TEST COMPLETED ===\n" RESET);
  exit(0);
}