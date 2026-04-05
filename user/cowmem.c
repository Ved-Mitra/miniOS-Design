#include "kernel/types.h"
#include "user/user.h"
#include "user/color.h"

#define PGSIZE 4096
#define NPAGES 20

int
main(void)
{
  printf(CYAN "=== COW Memory Pressure Test ===\n" RESET);

  char *pages[NPAGES];

  // allocate many pages
  for(int i = 0; i < NPAGES; i++){
    pages[i] = sbrk(PGSIZE);
    if(pages[i] == (void*)-1){
      printf(RED "alloc failed\n" RESET);
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
      printf(RED "ERROR at page %d\n" RESET, i);
      exit(1);
    }
  }

  printf(GREEN "=== PASS ===\n" RESET);
  exit(0);
}