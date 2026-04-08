//code to print timer along with the QUIZ
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <time.h>

static int countdown(int seconds)
{
    while (seconds > 0)
    {
        printf("Time remaining: %d seconds\n", seconds);
        Sleep(1000); // Sleep for 1 second
        seconds--;
        system("cls");
    }
    return 1;//to tell the main_code source code that time is up
}
int main()
{
    int seconds;
    
    // Ask user for countdown time in seconds
    /*printf("Enter the time for countdown (in seconds): ");
    if (scanf("%d", &seconds) != 1 || seconds <= 0) {
        printf("Invalid input. Please enter a positive integer.\n");
        return 1;
    }*/
    
    printf("Starting countdown...\n");
    time_t time_start=time(NULL);
    Sleep(5000);
    time_t now=time(NULL);
    printf("%ld",45-(now-time_start));
    
    return 0;
}
