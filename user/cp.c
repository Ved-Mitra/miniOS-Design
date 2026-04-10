#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"
#include "kernel/fcntl.h"

int main(int argc, char *argv[])
{
    int fd_src, fd_dest, n;
    char buf[512];
    if(argc !=3){
        printf(YELLOW "Usage: cp <source> <destination>\n" RESET);
        exit(1);
    }

    // Open the source file for reading
    if ((fd_src = open(argv[1], O_RDONLY)) < 0) {
        printf(RED "cp: cannot open source file %s\n" RESET, argv[1]);
        exit(1);
    }

    // Open (or create) the destination file for writing
    if ((fd_dest = open(argv[2], O_CREATE | O_WRONLY)) < 0) {
        printf(RED "cp: cannot create destination file %s\n" RESET, argv[2]);
        close(fd_src);
        exit(1);
    }

    // Read from the source and write to the destination in chunks of 512 bytes
    while ((n = read(fd_src, buf, sizeof(buf))) > 0) {
        if (write(fd_dest, buf, n) != n) {
        printf(RED "cp: write error\n" RESET);
        close(fd_src);
        close(fd_dest);
        exit(1);
        }
    }

    if (n < 0) {
        printf(RED "cp: read error\n" RESET);
    } else {
        printf(GREEN "Copied %s -> %s\n" RESET, argv[1], argv[2]);
    }

    close(fd_src);
    close(fd_dest);
    exit(0);
}