#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"

void empty_and_delete(char *path){
    char buf[512], *p;
    int fd;
    struct stat st;
    struct dirent de;

    if((fd=open(path,O_RDONLY))<0){
        printf(RED "deldir: cannot open %s\n" RESET, path);
        exit(1);
    }

    if(fstat(fd, &st) < 0){
        printf(RED "deldir: cannot stat %s\n" RESET, path);
        close(fd);
        return;
    }

    if(st.type == T_FILE){ //file delete it
        close(fd);
        unlink(path);
        return;
    }

    if(st.type == T_DIR){ //directory size too long not possible to delete further
        if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
        printf(RED "deldir: path %s is too long cannot delete further\n" RESET, path);
        close(fd);
        return;
        }

        // Copy the directory path into our buffer
        strcpy(buf, path);
        p = buf + strlen(buf);
        *p++ = '/'; // Add a slash so we can append filenames (e.g., "hello/")

        // Read the directory entries one by one
        while(read(fd, &de, sizeof(de)) == sizeof(de)){
            if(de.inum == 0) continue; // Skip empty entries
            
            // DO NOT delete the current (.) or parent (..) directories!
            if(strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0) {
                continue;
            }

            // Append the filename to the directory path in our buffer
            memmove(p, de.name, DIRSIZ);
            p[DIRSIZ] = 0; // Null-terminate the string

            // Recursively delete this new path (whether it's a file or a sub-directory)
            empty_and_delete(buf);
        }
        close(fd);

        // Now that the contents are gone, we can safely delete the directory itself!
        if(unlink(path) < 0) {
        printf(RED "deldir: failed to delete directory %s\n" RESET, path);
        }
    }
}



int main(int argc, char *argv[])
{
    if(argc!=2){
        printf(YELLOW "Usage: deldir <dirname>\n" RESET);
        exit(1);
    }

    empty_and_delete(argv[1]);
    printf(GREEN "Successfully deleted directory & its contents: %s\n" RESET, argv[1]);
    exit(0);
}