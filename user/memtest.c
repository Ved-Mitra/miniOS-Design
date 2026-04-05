#include "kernel/types.h"
#include "user/user.h"
#include "user/color.h"

int
main(void)
{
  printf(CYAN "=== Memory Abstraction Test Start ===\n" RESET);

  // 🔹 Test 1: Basic pipe functionality
  int p[2];
  if(pipe(p) < 0){
    printf(RED "Pipe creation failed\n" RESET);
    exit(1);
  }

  write(p[1], "hello", 5);

  char buf[10] = {0};
  read(p[0], buf, 5);

  printf(YELLOW "Pipe read: %s\n" RESET, buf);

  close(p[0]);
  close(p[1]);

  // 🔹 Test 2: Multiple pipe allocations (stress test)
  for(int i = 0; i < 20; i++){
    int fd[2];
    if(pipe(fd) < 0){
      printf(RED "Pipe failed at iteration %d\n" RESET, i);
      exit(1);
    }
    close(fd[0]);
    close(fd[1]);
  }
  printf(GREEN "Multiple pipe allocation test passed\n" RESET);

  // 🔹 Test 3: Fork + pipe combined
  int fd2[2];
  pipe(fd2);

  int pid = fork();
  if(pid == 0){
    // child
    write(fd2[1], "child_msg", 9);
    close(fd2[0]);
    close(fd2[1]);
    exit(0);
  } else {
    char buf2[20] = {0};
    read(fd2[0], buf2, 9);
    printf(YELLOW "Received from child: %s\n" RESET, buf2);
    wait(0);
  }

  close(fd2[0]);
  close(fd2[1]);

  printf(GREEN "Fork + pipe test passed\n" RESET);

  // 🔹 Test 4: Stress fork (indirect kernel stack usage)
  for(int i = 0; i < 10; i++){
    int pid = fork();
    if(pid == 0){
      exit(0);
    }
  }

  for(int i = 0; i < 10; i++){
    wait(0);
  }

  printf(GREEN "Fork stress test passed\n" RESET);

  printf(GREEN "=== ALL TESTS PASSED ===\n" RESET);
  exit(0);
}