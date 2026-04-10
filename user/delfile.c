#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int main(int argc, char *argv[])
{
    if(argc!=2){
        printf(YELLOW "Usage: delfile <filename>\n" RESET);
        exit(1);
    }
    struct stat st;
    // Check if the file exists and get its info
    if (stat(argv[1], &st) < 0) {
        printf(RED "delfile: cannot find %s\n" RESET, argv[1]);
        exit(1);
    }

    // Prevent deleting a directory
    if (st.type == T_DIR) {
        printf(RED "delfile: %s is a directory. Use 'deldir' instead.\n" RESET, argv[1]);
        exit(1);
    }

    // Delete the file using unlink
    if (unlink(argv[1]) < 0) {
        printf(RED "delfile: failed to delete %s\n" RESET, argv[1]);
    } else {
        printf(GREEN "Deleted file: %s\n" RESET, argv[1]);
    }

    exit(0);
}