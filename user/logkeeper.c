#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int main(int argc,char *argv[]){
    char buf[512];
    int n;
    while((n=syslogread(buf,sizeof(buf)))>0){
        write(1,buf,n);
    }
    if(n<0){
        printf(RED "Error reading from syslog\n" RESET);
    }
    exit(0);
}