#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "user/color.h"

int main(int argc, char *argv[]) {
  int fd, n;
  char buf[512];

  if(argc != 3 || (strcmp(argv[1], "-a") != 0 && strcmp(argv[1], "-w") != 0)){
    printf(YELLOW "Usage: editfile -a/-w <file>\n" RESET);
    exit(1);
  }

  char *flag = argv[1];
  char *filename = argv[2];

  if (strcmp(flag, "-w") == 0) {
    // To overwrite in basic xv6, we delete the file first, then recreate it.
    unlink(filename);
    fd = open(filename, O_CREATE | O_WRONLY);
  } else {
    // Append mode (-a): open with read/write access
    fd = open(filename, O_CREATE | O_RDWR);
    if (fd >= 0) {
      // Read through the entire file until we reach the end.
      // This sets our writing pointer to the end of the file.
      while(read(fd, buf, sizeof(buf)) > 0) {
        // Do nothing, just consume bytes to reach EOF
      }
    }
  }

  if(fd < 0){
    printf(RED "editfile: cannot open %s\n" RESET, filename);
    exit(1);
  }
  printf(YELLOW);
  printf("Editing '%s' mode: %s\n", filename, (strcmp(flag, "-w") == 0) ? "Overwrite" : "Append");
  printf("Type your text below. Press Ctrl+D on an empty line to save and exit.\n");
  printf("---------------------------------------------------------------------\n");
  printf(RESET);

  // Read from standard input (file descriptor 0) and write to our file
  while((n = read(0, buf, sizeof(buf))) > 0) {
    if(write(fd, buf, n) != n) {
      printf(RED "editfile: write error\n" RESET);
      break;
    }
  }

  close(fd);
  printf(GREEN "\n[Saved and exited editfile]\n" RESET);
  exit(0);
}