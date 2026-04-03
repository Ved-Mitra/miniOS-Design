#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int main(int argc, char *argv[])
{
  printf(CYAN "Starting memory compaction & best-fit test...\n" RESET);

  int pids[10];

  printf(YELLOW "Phase 1: Forking 10 children to fragment memory...\n" RESET);
  for (int i = 0; i < 10; i++) {
    pids[i] = fork();
    if (pids[i] == 0) {
      char *mem = sbrk(5 * 4096); 
      for(int j = 0; j < 5; j++) {
        mem[j * 4096] = 'A' + i; 
      }

      if (i % 2 == 0) {
        printf("  Child %d exiting immediately to create a memory hole.\n", i);
        exit(0);
      } else {
        int delay = 0;
        while(delay < 100000000) delay++;
        printf("  Child %d exiting after hold.\n", i);
        exit(0);
      }
    }
  }

  // Allow children to start
  int d = 0; while(d < 100000000) d++;

  printf(YELLOW "\nPhase 2: Allocating a 3-page block. Watch kernel output for 'best_fit' placement!\n" RESET);
  char *test_mem = sbrk(3 * 4096);
  test_mem[0] = 'X'; 
  
  printf(YELLOW "\nPhase 3: Triggering compaction. CPU IDLE.\n" RESET);
  // Long pause pushes scheduler to IDLE
  d = 0; while(d < 500000000) d++;

  printf(YELLOW "\nPhase 4: Allocating a 12-page block.\n" RESET);
  char *large_mem = sbrk(12 * 4096);
  if(large_mem == (char*)-1) {
    printf(RED "ERROR: Failed to allocate large block despite compaction! Heap might be fragmented.\n" RESET);
  } else {
    printf(GREEN "SUCCESS: Allocated 12-page block at %p!\n" RESET, large_mem);
  }

  for (int i = 0; i < 10; i++) {
    wait(0);
  }

  printf(CYAN "\nMemory compaction & best-fit test finished!\n" RESET);
  exit(0);
}
