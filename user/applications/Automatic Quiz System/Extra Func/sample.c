#include <stdio.h>
#include <windows.h>

// Function to set the color
void SetColor(WORD color) {
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    SetConsoleTextAttribute(hConsole, color);
}

int main() {
    // Print red text
    SetColor(FOREGROUND_RED);
    printf("This is red text\n");

    // Print green text
    SetColor(FOREGROUND_GREEN);
    printf("This is green text\n");

    // Print blue text on a yellow background
    //SetColor(FOREGROUND_BLUE | BACKGROUND_YELLOW);
    printf("This is blue text on a yellow background\n");

    // Print white text on a red background
    //SetColor(FOREGROUND_WHITE | BACKGROUND_RED);
    printf("This is white text on a red background\n");

    // Reset to normal colors
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    printf("This is normal white text again\n");

    printf("\033[0;35m");
    printf("This text is purple\n");
    printf("\033[0m");

    printf("\033[0;36m");//CYAN text
    printf("This text is cyan\n");
    //printf("\033[0m");//White text
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    return 0;
}
