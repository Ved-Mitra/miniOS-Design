#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int main(int argc, char *argv[]) {
  printf(CYAN "Available OS Commands:\n" RESET);
  printf(CYAN "----------------------\n" RESET);
  printf(CYAN "ls       - List directory contents\n" RESET);
  printf(CYAN "cd       - Change current directory\n" RESET);
  printf(CYAN "cat      - Print file contents to the console\n" RESET);
  printf(CYAN "mkdir    - Create a new directory\n" RESET);
  printf(CYAN "mkfile   - Create an empty file\n" RESET);
  printf(CYAN "delfile  - Delete a file\n" RESET);
  printf(CYAN "help     - Show this help message\n" RESET);
  printf(CYAN "editfile - Edit a file (-a to append, -w to overwrite)\n" RESET);
  printf(CYAN "clear    - Clear the terminal screen\n" RESET);
  printf(CYAN "mv       - Move or rename a file/directory\n" RESET);
  printf(CYAN "cp       - Copy a file\n" RESET);
  printf(CYAN "deldir   - Delete a directory\n" RESET);
  
  exit(0);
}