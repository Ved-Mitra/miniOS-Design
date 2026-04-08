#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"
#include "kernel/fcntl.h"

int main(int argc, char *argv[])
{
    if (argc != 2) {
    printf(YELLOW "Usage: mkfile <filename>\n" RESET);
    exit(1);
  }

  // O_CREATE: Creates the file if it does not exist.
  // O_RDWR: Opens it for reading and writing so it successfully creates.
  int fd = open(argv[1], O_CREATE | O_RDWR);

  if (fd < 0) {
    printf(RED "mkfile: failed to create file %s\n" RESET, argv[1]);
    exit(1);
  }

  // Immediately close it, as we only wanted to create an empty file
  close(fd);
  exit(0);
}