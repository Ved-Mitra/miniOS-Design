#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char *argv[])
{
  int fd1, fd2;
  int ret;

  printf(1, "==== Memfile Test Started ====\n");

  // 1. Test creation
  printf(1, "Testing memcreate()...\n");
  fd1 = memcreate();
  if(fd1 < 0){
    printf(1, "FAILED: memcreate returned %d\n", fd1);
    exit();
  }
  printf(1, "SUCCESS: Created memfile with fd = %d\n", fd1);

  // 2. Test multiple parameter creations
  fd2 = memcreate();
  if(fd2 < 0){
    printf(1, "FAILED: second memcreate returned %d\n", fd2);
    exit();
  }
  printf(1, "SUCCESS: Created second memfile with fd = %d\n", fd2);

  // 3. Test deletion of an invalid fd (should fail gracefully)
  printf(1, "Testing invalid memdelete()...\n");
  ret = memdelete(99); 
  if(ret < 0){
    printf(1, "SUCCESS: Correctly rejected invalid fd 99\n");
  } else {
    printf(1, "FAILED: Accepted invalid fd 99\n");
  }

  // 4. Test deletion of a valid memfile
  printf(1, "Testing valid memdelete() on fd %d...\n", fd1);
  ret = memdelete(fd1);
  if(ret < 0){
    printf(1, "FAILED: memdelete failed on valid fd %d\n", fd1);
  } else {
    printf(1, "SUCCESS: memdelete worked on fd %d\n", fd1);
  }

  // 5. Test close() interoperability
  printf(1, "Testing standard close() on memfile fd %d...\n", fd2);
  close(fd2);
  printf(1, "SUCCESS: close() completed on memfile\n");

  printf(1, "==== Memfile Test Completed successfully ====\n");
  exit();
}
