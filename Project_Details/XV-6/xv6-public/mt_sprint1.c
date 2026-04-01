#include "types.h"
#include "stat.h"
#include "user.h"
#include "color.h"

int
main(int argc, char *argv[])
{
  int fd1, fd2;
  int ret;

  printf(1,CYAN "Memfile Test Started (Sprint 1)\n"RESET);

  //Test creation
  printf(1,YELLOW "Testing memcreate()...\n" RESET);
  fd1 = memcreate();
  if(fd1 < 0){
    printf(1,RED "FAILED: memcreate returned %d\n" RESET, fd1);
    exit();
  }
  printf(1, GREEN "SUCCESS: Created memfile with fd = %d\n" RESET, fd1);

  //Test multiple parameter creations
  fd2 = memcreate();
  if(fd2 < 0){
    printf(1,RED "FAILED: second memcreate returned %d\n" RESET, fd2);
    exit();
  }
  printf(1, GREEN "SUCCESS: Created second memfile with fd = %d\n" RESET, fd2);

  //Test deletion of an invalid fd (should fail gracefully)
  printf(1, YELLOW "Testing invalid memdelete()...\n" RESET);
  ret = memdelete(99); 
  if(ret < 0){
    printf(1, GREEN "SUCCESS: Correctly rejected invalid fd 99\n" RESET);
  } else {
    printf(1, RED "FAILED: Accepted invalid fd 99\n" RESET);
  }

  //Test deletion of a valid memfile
  printf(1, YELLOW "Testing valid memdelete() on fd %d...\n" RESET, fd1);
  ret = memdelete(fd1);
  if(ret < 0){
    printf(1, RED "FAILED: memdelete failed on valid fd %d\n" RESET, fd1);
  } else {
    printf(1, GREEN "SUCCESS: memdelete worked on fd %d\n" RESET, fd1);
  }

  //Test close()
  printf(1, YELLOW "Testing standard close() on memfile fd %d...\n" RESET, fd2);
  close(fd2);
  printf(1, GREEN "SUCCESS: close() completed on memfile\n" RESET);

  printf(1,CYAN "Memfile Test Completed successfully\n" RESET);
  exit();
}
