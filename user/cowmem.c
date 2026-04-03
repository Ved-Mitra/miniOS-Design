#include "kernel/types.h"
#include "user/user.h"

#define PGSIZE 4096
#define NPAGES 20

int
main(void)
{
  printf("=== COW Memory Pressure Test ===\n");

  char *pages[NPAGES];

  // allocate many pages
  for(int i = 0; i < NPAGES; i++){
    pages[i] = sbrk(PGSIZE);
    if(pages[i] == (void*)-1){
      printf("alloc failed\n");
      exit(1);
    }
    pages[i][0] = i;
  }

  int pid = fork();

  if(pid == 0){
    // child modifies all pages
    for(int i = 0; i < NPAGES; i++){
      pages[i][0] += 1;
    }
    exit(0);
  }

  wait(0);

  // parent checks values unchanged
  for(int i = 0; i < NPAGES; i++){
    if(pages[i][0] != i){
      printf("ERROR at page %d\n", i);
      exit(1);
    }
  }

  printf("=== PASS ===\n");
  exit(0);
}