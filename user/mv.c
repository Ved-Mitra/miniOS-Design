#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int main(int argc, char *argv[])
{
    if(argc!=3){
        printf(YELLOW "Usage: mv <source> <destination>\n" RESET);
        exit(1);
    }

    //Create a new link (new name) to the existing file
    if (link(argv[1], argv[2]) < 0) {
        printf(RED"mv: failed to move %s to %s\n", RESET ,argv[1], argv[2]);
        exit(1);
    }

    //Delete the old link (old name)
    if (unlink(argv[1]) < 0) {
        printf(RED"mv: failed to delete original file %s\n", RESET ,argv[1]);
        exit(1);
    }

    printf(GREEN "Moved %s -> %s\n" RESET, argv[1], argv[2]);
    exit(0);
}