#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main()
{
  int *x;
  x = (int *) sbrk(4096);
  x[0] = 10;
  printf("Before fork: %d\n", x[0]);
  int pid = fork();
  if(pid == 0){
    printf("Child sees: %d\n", x[0]);
    x[0] = 20;  
    printf("Child changed to: %d\n", x[0]);
    exit(0);
  } else {
    wait(0);
    printf("Parent sees after child: %d\n", x[0]);
    exit(0);
  }
}