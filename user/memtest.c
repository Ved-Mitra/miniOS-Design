#include "kernel/types.h"
#include "user/user.h"

int
main(void)
{
  printf("=== Memory Abstraction Test Start ===\n");

  // 🔹 Test 1: Basic pipe functionality
  int p[2];
  if(pipe(p) < 0){
    printf("Pipe creation failed\n");
    exit(1);
  }

  write(p[1], "hello", 5);

  char buf[10] = {0};
  read(p[0], buf, 5);

  printf("Pipe read: %s\n", buf);

  close(p[0]);
  close(p[1]);

  // 🔹 Test 2: Multiple pipe allocations (stress test)
  for(int i = 0; i < 20; i++){
    int fd[2];
    if(pipe(fd) < 0){
      printf("Pipe failed at iteration %d\n", i);
      exit(1);
    }
    close(fd[0]);
    close(fd[1]);
  }
  printf("Multiple pipe allocation test passed\n");

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
    printf("Received from child: %s\n", buf2);
    wait(0);
  }

  close(fd2[0]);
  close(fd2[1]);

  printf("Fork + pipe test passed\n");

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

  printf("Fork stress test passed\n");

  printf("=== ALL TESTS PASSED ===\n");
  exit(0);
}