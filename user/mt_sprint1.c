#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int
main(int argc, char *argv[])
{
  int fd1, fd2;
  int ret;

  printf(CYAN "Memfile Test Started (Sprint 1)\n"RESET);

  //Test creation
  printf(YELLOW "Testing memcreate()...\n" RESET);
  fd1 = memcreate();
  if(fd1 < 0){
    printf(RED "FAILED: memcreate returned %d\n" RESET, fd1);
    exit(0);
  }
  printf( GREEN "SUCCESS: Created memfile with fd = %d\n" RESET, fd1);

  //Test multiple parameter creations
  fd2 = memcreate();
  if(fd2 < 0){
    printf(RED "FAILED: second memcreate returned %d\n" RESET, fd2);
    exit(0);
  }
  printf( GREEN "SUCCESS: Created second memfile with fd = %d\n" RESET, fd2);

  //Test deletion of an invalid fd (should fail gracefully)
  printf( YELLOW "Testing invalid memdelete()...\n" RESET);
  ret = memdelete(99); 
  if(ret < 0){
    printf( GREEN "SUCCESS: Correctly rejected invalid fd 99\n" RESET);
  } else {
    printf( RED "FAILED: Accepted invalid fd 99\n" RESET);
  }

  //Test deletion of a valid memfile
  printf( YELLOW "Testing valid memdelete() on fd %d...\n" RESET, fd1);
  ret = memdelete(fd1);
  if(ret < 0){
    printf( RED "FAILED: memdelete failed on valid fd %d\n" RESET, fd1);
  } else {
    printf( GREEN "SUCCESS: memdelete worked on fd %d\n" RESET, fd1);
  }

  //Test close()
  printf( YELLOW "Testing standard close() on memfile fd %d...\n" RESET, fd2);
  close(fd2);
  printf( GREEN "SUCCESS: close() completed on memfile\n" RESET);

  printf(CYAN "Memfile Test Completed successfully\n" RESET);
  exit(0);
}
