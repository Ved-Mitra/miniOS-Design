#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int main(int argc,char *argv[]){
    char buf[512];
    int n;
    
    // Poll continuously for new syslog messages
    while(1){
        n = syslogread(buf, sizeof(buf));
        if(n > 0){
            write(1, buf, n);
        } else if(n < 0){
            printf(RED "Error reading from syslog\n" RESET);
            break;
        } else {
            pause(10); // Pause briefly before checking for new logs again
        }
    }
    exit(0);
}