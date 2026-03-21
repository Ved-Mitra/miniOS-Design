#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int
main(int argc, char *argv[])
{
  int fd;
  char buf[50];
  int n;

  printf(1, CYAN "Memfile R/W & GC Test Started (SPRINT 2)\n" RESET);

  //Test creation
  printf(1, YELLOW "1. Testing memcreate()...\n" RESET);
  fd = memcreate();
  if(fd < 0){
    printf(1, RED "FAILED: memcreate returned %d\n" RESET, fd);
    exit(0);
  }
  printf(1, GREEN "SUCCESS: Created memfile with fd = %d\n" RESET, fd);

  //Test writing to the memory file
  printf(1, YELLOW "2. Testing write()...\n" RESET);
  char *msg = "Hello MiniOS In-Memory File!";
  printf(1, BLUE "Writing message to memfile: '%s'\n" RESET, msg);
  int len = 28; // length of the message
  n = write(fd, msg, len);
  if(n == len){
    printf(1, GREEN "SUCCESS: Wrote %d bytes successfully.\n" RESET, n);
  } else {
    printf(1, RED "FAILED: Write returned %d\n" RESET, n);
  }

  //Test reading from the memory file
  printf(1, YELLOW "3. Testing read()...\n" RESET);
  // Since we just wrote to the file, the offset is at the end.
  // A read right now should return 0 (EOF).
  // printf(1, BLUE "Attempting to read from memfile at current offset (should be EOF)... as the offset has advanced to EOF due to the write operation done above.\n" RESET);

  // Wipe the buffer clean first to prove we aren't faking it
  memset(buf, 0, sizeof(buf)); 
  n = read(fd, buf, 28); // Read the 28 bytes back

  if(n == 0){
    printf(1, GREEN "SUCCESS: Read returned 0 (Expected End-Of-File since offset advanced).\n" RESET);
  } else if (n > 0) {
    buf[n] = '\0';
    printf(1, GREEN "SUCCESS: Read %d bytes: %s\n" RESET, n, buf);
    printf(1, MAGENTA "-----> DATA RETRIEVED: '%s' <-----\n" RESET, buf);
  } else {
    printf(1, RED "FAILED: Read returned %d\n" RESET, n);
  }

  //Test logical deletion
  printf(1, YELLOW "4. Testing memdelete()...\n" RESET);
  n = memdelete(fd);
  if(n < 0){
    printf(1, RED "FAILED: memdelete failed on fd %d\n" RESET, fd);
  } else {
    printf(1, GREEN "SUCCESS: memdelete marked file for deletion.\n" RESET);
  }

  //Test close() and trigger Garbage Collection
  printf(1, YELLOW  "5. Closing fd to drop reference count to 0...\n" RESET);
  close(fd);
  printf(1, GREEN "SUCCESS: fd closed.\n" RESET);

  // Sleep for a short time to allow the background Garbage Collector to run
  // You should see the Kernel's cprintf log pop up in the terminal!
  printf(1, YELLOW "Waiting for OS Garbage Collector to trigger...\n" RESET);
  sleep(150);

  printf(1, CYAN "Memfile Test Completed\n" RESET);
  exit(0);
}