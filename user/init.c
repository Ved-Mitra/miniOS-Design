// init: The initial user-level program

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/spinlock.h"
#include "kernel/sleeplock.h"
#include "kernel/fs.h"
#include "kernel/file.h"
#include "user/user.h"
#include "kernel/fcntl.h"

char *argv[] = { "sh", 0 };

int
main(void)
{
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  dup(0);  // stderr

  for(;;){
    /*
    printf("init: starting priority_test\n");
    pid = fork();
    if(pid == 0){
      exec("priority_test", (char *[]){ "priority_test", 0 });
      printf("init: exec priority_test failed\n");
      exit(1);
    }
    while(wait(0) != pid);

    printf("init: starting fairness_test\n");
    pid = fork();
    if(pid == 0){
      exec("fairness_test", (char *[]){ "fairness_test", 0 });
      printf("init: exec fairness_test failed\n");
      exit(1);
    }
    while(wait(0) != pid);
    */

    printf("init: starting sh\n");
    pid = fork();
    if(pid < 0){
      printf("init: fork failed\n");
      exit(1);
    }
    if(pid == 0){
      exec("sh", argv);
      printf("init: exec sh failed\n");
      exit(1);
    }

    for(;;){
      wpid = wait((int *) 0);
      if(wpid == pid){
        break;
      } else if(wpid < 0){
        printf("init: wait returned an error\n");
        exit(1);
      }
    }
  }
}
