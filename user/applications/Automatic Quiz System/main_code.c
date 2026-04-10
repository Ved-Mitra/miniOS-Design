#include<stdio.h>
#include<ctype.h>
#include<stdlib.h>
#include<string.h>
#include<time.h>
#include<stdbool.h>
// #include<windows.h>
#include<math.h>
#include<unistd.h>
// #include"printer.c"
// #include"camera.c"

void createQuiz();//to create a quiz from predefined set of questions
void inputQuiz();//to create a quiz from the questions inputted by the instructor
void takeQuiz();//for the student to take the quiz
void ICQuiz(int);//for IC quiz
void IBQuiz(int);//for IB quiz
void IEQuiz(int);//for IE quiz
void MQuiz(int);//for Mathematics quiz
bool rename_file();//to convert file from .txt to .csv
void draw_histogram(int table[],char roll_no[][20], int n);//to print the histogram
int large(int*,int);//part of histogram
int isEven(int);//part of histogram
void clear_Quiz_present_folder();//to delete all the file in Quiz present folder
void clear_terminal();//to clear the terminal by system command according to the OS of the system
void timer_delay();//to produce a delay in timer
void clear_terminal()//DONE
{
    #if defined(_WIN32) || defined(_WIN64)
        system("cls");
    #elif defined(__linux__)
        system("clear");
    #elif defined(__APPLE__) || defined(__MACH__)
        system("clear");
    #endif
    return;
}
void timer_delay(int n)
{
    #if defined(_WIN32) || defined(_WIN64)
        Sleep(n*1000);
    #elif defined(__linux__)
        sleep(n);
    #elif defined(__APPLE__) || defined(__MACH__)
        sleep(n);
    #endif
    return;
}
#define FOREGROUND_BLUE      1
#define FOREGROUND_GREEN     2
#define FOREGROUND_RED       4
#define FOREGROUND_INTENSITY 8

void SetColor(int color)//To print coloured output in terminal
{
    if (color == (FOREGROUND_GREEN | FOREGROUND_INTENSITY)) {
        printf("\033[1;32m"); // Bright Green
    } else if (color == (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE)) {
        printf("\033[0m"); // Reset/White text
    } else if (color == (FOREGROUND_RED | FOREGROUND_GREEN)) {
        printf("\033[0;33m"); // Yellow
    } else if (color == FOREGROUND_RED) {
        printf("\033[0;31m"); // Red
    } else if (color == FOREGROUND_GREEN) {
        printf("\033[0;32m"); // Green
    } else {
        printf("\033[0m"); // Default Reset
    }
}
int main()//DONE
{
    char position;
    clear_terminal();//call to clear terminal function
    SetColor(FOREGROUND_GREEN | FOREGROUND_INTENSITY);//BRIGHT GREEN color
    printf("!!!!!!!!\tWELCOME TO THE AUTOMATIC QUIZ SYSTEM\t!!!!!!!!\n\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN);//YELLOW color
    printf("\nAre you a STUDENT or INSTRUCTOR, enter your position:\nS for student\nI for instructor\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    scanf("%c",&position);
    if(tolower(position)=='i')
    {
        clear_terminal();;//clearing the terminal for better input and output stream view
        printf("\033[0;36m");//CYAN text;
        printf("INSTRUCTOR\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        char choice[3];
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN);//YELLOW color
        printf("\nYou would like to create the QUIZ, USER-INPUTED OR PRE-DEFINED:\nEnter your choice\nUD for USER-DEFINED\nPD for PRE-DEFINED\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        scanf("%2s",choice);
        for(int i=0;i<strlen(choice);i++)//converting all letters of choice into lowercase
            choice[i]=tolower(choice[i]);
        if(strcmp(choice,"ud")==0)
        {
            clear_terminal();;//clearing the terminal for better input and output stream view
            printf("\033[0;36m");//CYAN text;
            printf("INSTRUCTOR\n");
            printf("USER-DEFINED QUIZ");
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            inputQuiz();
        }
        else if (strcmp(choice,"pd")==0)
        {
            clear_terminal();;//clearing the terminal for better input and output stream view
            printf("\033[0;36m");//CYAN text;
            printf("INSTRUCTOR\n");
            printf("PRE-DEFINED QUIZ");
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            createQuiz();
        }
        else
        {
            SetColor(FOREGROUND_RED);
            printf("Invalid Output");
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        }
    }
    else if(tolower(position)=='s')
    {
        clear_terminal();;//clearing the terminal for better input and output stream view
        printf("\033[0;36m");//CYAN text;
        printf("STUDENT\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        takeQuiz();
    }
    else
    {
        SetColor(FOREGROUND_RED);
        printf("Invalid Output");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    }
    return 0;
}
void takeQuiz()
{
    FILE *quiz,*second,*number,*answer,*result;
    quiz=fopen("Quiz.txt","r");
    answer=fopen("Answers.txt","r");
    second=fopen("Time.txt","r");
    number=fopen("number_of_students.txt","r");
    result=fopen("Result.txt","w");
    if(fgetc(quiz)==EOF)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Contact Instructor\nNO QUIZ IS PRESENT");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        fclose(number);//closing number file pointer
        fclose(second);//closing second file pointer
        fclose(answer);//closing answer file pointer
        fclose(result);//closing result file pointer
        fclose(quiz);
        return ;
    }
    if (quiz == NULL)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error: Could not open Quiz.txt.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        fclose(number);//closing number file pointer
        fclose(second);//closing second file pointer
        fclose(answer);//closing answer file pointer
        fclose(result);//closing result file pointer
        fclose(quiz);
        return;
    }
    if (answer == NULL)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error: Could not open Answer.txt.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        fclose(number);//closing number file pointer
        fclose(second);//closing second file pointer
        fclose(answer);//closing answer file pointer
        fclose(result);//closing result file pointer
        fclose(quiz);
        return;
    }
    if (second == NULL)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error: Could not open Time.txt.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        fclose(number);//closing number file pointer
        fclose(second);//closing second file pointer
        fclose(answer);//closing answer file pointer
        fclose(result);//closing result file pointer
        fclose(quiz);
        return;
    }
    if (number == NULL)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error: Could not open number_of_students.txt.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        fclose(number);//closing number file pointer
        fclose(second);//closing second file pointer
        fclose(answer);//closing answer file pointer
        fclose(result);//closing result file pointer
        fclose(quiz);
        return;
    }
    if (result == NULL)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error: Could not open Result.txt.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        fclose(number);//closing number file pointer
        fclose(second);//closing second file pointer
        fclose(answer);//closing answer file pointer
        fclose(result);//closing result file pointer
        fclose(quiz);
        return;
    }
    fclose(quiz);//closing the quiz file pointer
    char ch;
    int n=0;
    fscanf(number,"%d",&n);
    fclose(number);//closing number file pointer
    int sec=0;
    fscanf(second,"%d",&sec);//to store the Duration of the QUIZ
    fclose(second);//closing second file pointer
    char ans[25];//storing answer of each question in an array
    int index=0;
    while ((ch = fgetc(answer)) != EOF)//to move the file pointer in the Answer.txt to the next line
    {
        if (ch == '\n')
            break;
    }
    while((ch=fgetc(answer))!=EOF)//storing answer into ans array
    {
        //printf("%c ",ch);
        if(isalpha(ch) && ch!='A')
        {
            ans[index++]=ch;
        }
    }
    //Just adding headings to result
    fprintf(result,"NAME,ROLL NUMBER,");
    for(int k=0;k<index;k++)
        fprintf(result,"Question%d,",k+1);
    fprintf(result,"Total Marks,");
    fprintf(result,"\n");
    ans[index]='\0';//assigning null-terminator to mark the end of the answer array
    fclose(answer);//closing answer file pointer
    int score;//to store score of each student
    char name[50];//to store name of each student
    char roll_no[10];//to store the roll number of each student
    char option;//to store the option chosen by a student of each question
    int total_marks[n];//to store the total of all students marks
    char ID[n][20];//To store the roll number of each student for histogram program
    for(int i=0;i<n;i++)//for each student to take the quiz one by one
    {
        time_t time_start=time(NULL);//time start of Quiz
        score=0;
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN);//YELLOW text
        printf("Enter your name:\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        getchar();////to remove the \n from input stream
        fgets(name,50,stdin);
        name[strlen(name)-1]='\0';
        fprintf(result,"%s,",name);
        SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
        printf("Enter your Roll Number:\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        scanf("%s",roll_no);
        fprintf(result,"%s,",roll_no);
        strcpy(ID[i],roll_no);//copying the roll number
        for(int j=0;j<index;j++)//to print each question
        {
            char filename[40];
            snprintf(filename,40,"Quiz present/Q%d.txt",j+1);
            FILE *question=fopen(filename,"r");
            printf("\n\n\n");
            while((ch=fgetc(question))!=EOF)
            {
                printf("%c",ch);
            }
            time_t now=time(NULL);//present time passed in Quiz

            if((now-time_start)>=sec)
            {
                SetColor(FOREGROUND_RED);//RED color
                printf("TIME UP\n");
                SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
                printf("\033[0;36m");//CYAN text;//BLUE text
                printf("Your Quiz has been successfully submitted\nNext Student");
                SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
                for(int k=j;k<index;k++)//to leave the space for unanswered questions
                {
                    fprintf(result,",");
                }
                break;
            }
            SetColor(FOREGROUND_RED);//RED color
            printf("Enter only LOWERCASE option letters\n");
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
            printf("\nEnter your answer: \n");
            getchar();//to remove the \n from input stream
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            scanf("%c",&option);
            fprintf(result,"%c,",option);
            if(option==ans[j])
                score+=1;
            SetColor(FOREGROUND_RED);//RED color
            printf("\n\nTime Remaining = %ld",sec-(now-time_start));
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            fclose(question);
        }
        total_marks[i]=score;
        fprintf(result,"%d\n",score);
        SetColor(FOREGROUND_GREEN);//GREEN color
        printf("\n\nYour Quiz has been successfully submitted\nNext Student");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        timer_delay(1);
        clear_terminal();;//to clear the terminal so that another student cannot see the other student's answers
    }
    fclose(result);
    draw_histogram(total_marks,ID,n);
    if(rename_file())
    {
        SetColor(FOREGROUND_GREEN);//GREEN color
        printf("Result is Available in Excel Format");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    }
    else
    {
        SetColor(FOREGROUND_GREEN);//GREEN color
        printf("Result is Available in Txt Format");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    }
    fclose(quiz);
    fclose(result);
    timer_delay(6);
    return ;
}
bool rename_file()
{
    remove("Result.csv");
    if(rename("Result.txt","Result.csv")==0)
        return true;
    else
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("File rename not possible\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return false;
    }
}
void inputQuiz()//DONE
{
    clear_Quiz_present_folder();
    FILE *quiz,*ans,*number,*second,*number_of_questions;
    number_of_questions=fopen("number_of_Questions.txt","w");
    number=fopen("number_of_students.txt","w");
    ans=fopen("Answers.txt","w");
    quiz=fopen("Quiz.txt","w");
    second=fopen("Time.txt","w");
    if (quiz == NULL || ans == NULL || number == NULL || second == NULL)//chechking that desired files are proper opened
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error opening file!\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return;
    }
    char course[50],code[20],ch;
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("\nEnter the Course name:\n");//Asking for necessary information related to the course name and course code
    getchar();//to clear the input terminal of \n
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    fgets(course,50,stdin);
    course[strlen(course)-1]='\0'; 
    clear_terminal();;//clearing the terminal for better input and output stream view
    printf("\033[0;36m");//CYAN text;//BLUE text
    printf("%s Quiz\n",course);
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the Course code:\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    scanf("%20s",code);
    clear_terminal();;//clearing the terminal for better input and output stream view
    printf("\033[0;36m");//CYAN text;//BLUE text
    printf("%s Quiz\n",course);
    printf("%s\n",code);
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    fprintf(quiz,"\t\t\t\t\t\t%s\n",course);//storing necessary information in Quiz.txt
    fprintf(quiz,"\t\t\t\t\t\t\t\t\t%s\n\n",code);
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the number of questions in the QUIZ: ");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int n;
    scanf("%d",&n);
    if(n<=0)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Enter valid number of Questions");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return;
    }
    fprintf(number_of_questions,"%d",n);
    fprintf(ans,"Answers Key:\n");
    SetColor(FOREGROUND_RED);//RED color
    printf("Please enter MCQs only\nPlease end each Question with a \'$\' sign\n");//Question format 
    printf("Please enter answer in lowercase character a,b,c,d,.... only\n");//Answer format
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    for(int i=0;i<n;i++)
    {
        char filename[40];
        snprintf(filename,40,"Quiz present/Q%d.txt",i+1);
        FILE *question=fopen(filename,"w");
        SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
        printf("Enter the Question:\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        fprintf(quiz,"Q%d. ",i+1);
        while ((ch = getchar()) != '$' && ch != EOF)//to take characters one by one from the input stream stdbin and store in Quiz.txt
        {
            fputc(ch,quiz);
            fputc(ch,question);
        }
        fprintf(quiz,"\n\n");
        getchar();//Clear the newline character from the input buffer
        SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
        printf("Enter the Answer: ");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        //while(!isalpha(ch=getchar()))//Clear the newline character from the input buffer
        ch=getchar();
        fprintf(ans,"A%d. ",i+1);
        fputc(ch,ans);
        fprintf(ans,"\n");//to store the answer of next question in next line
        fclose(question);
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\t\"BEST OF LUCK\"");
    clear_terminal();;//clearing the terminal for better input and output stream view
    printf("\033[0;36m");//CYAN text;//BLUE text
    printf("%s Quiz\n",course);
    printf("%s\n",code);
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the Duration of the Quiz in Seconds:\n");//for countdown timer
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int seconds,number_of_students;
    scanf("%d",&seconds);
    fprintf(second,"%d",seconds);
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the number of students taking the Quiz:\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    scanf("%d",&number_of_students);
    fprintf(number,"%d",number_of_students);
    SetColor(FOREGROUND_GREEN);//GREEN color
    printf("QUIZ SUCCESSFULLY GENERATED");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    fclose(quiz);
    fclose(ans);
    fclose(number);
    fclose(second);
    fclose(number_of_questions);
    return ;
}
void createQuiz()//DONE
{
    clear_Quiz_present_folder();
    char subject[2];
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("\nEnter the number of questions(not more than 25) you want in the QUIZ: ");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int n;
    scanf("%d",&n);
    if(n>25 || n<1)
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Wrong Number of Questions");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return ;
    }
    FILE *number_of_questions;
    number_of_questions=fopen("number_of_Questions.txt","w");
    fprintf(number_of_questions,"%d",n);
    fclose(number_of_questions);
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("\nEnter the Subject whose Quiz you want to be generated: \nIE for Electrical\nIC for Computer Science\nM for Mathematics\nIB for Biotechnology\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    scanf("%2s",subject);
    for(int i=0;i<strlen(subject);i++)//to prevent any error
    {
        subject[i]=toupper(subject[i]);
    }
    if (strcmp(subject,"IE")==0)
    {
        clear_terminal();;//clearing the terminal for better input and output stream view
        printf("\033[0;36m");//CYAN text;//BLUE text
        printf("IE Quiz\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        IEQuiz(n);
    }
    else if(strcmp(subject,"IC")==0)
    {
        clear_terminal();;//clearing the terminal for better input and output stream view
        printf("\033[0;36m");//CYAN text;//BLUE text
        printf("IC Quiz\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        ICQuiz(n);
    }
    else if(strcmp(subject,"IB")==0)
    {
        clear_terminal();;//clearing the terminal for better input and output stream view
        printf("\033[0;36m");//CYAN text;//BLUE text
        printf("IB Quiz\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        IBQuiz(n);
    }
    else if(strcmp(subject,"M")==0)
    {
        clear_terminal();;//clearing the terminal for better input and output stream view
        printf("\033[0;36m");//CYAN text;//BLUE text
        printf("Mathematics Quiz\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        MQuiz(n);
    }
    else
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Invalid Subject");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    }
    timer_delay(1);
    return ;
}
void ICQuiz(int n)//DONE
{
    FILE *quiz,*ans,*number,*second;
    second=fopen("Time.txt","w");
    quiz=fopen("Quiz.txt","w");
    ans=fopen("Answers.txt","w");
    number=fopen("number_of_students.txt","w");
    if (quiz == NULL || ans == NULL)//Checking if files opened successfully 
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error opening quiz or answer file.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return ;
    }
    FILE *questions[25];
    for(int i=0;i<25;i++)//assigning file pointers for questions
    {
        char filename[20];
        snprintf(filename, sizeof(filename), "IC/Q%d.txt", i + 1);  // Generate filename for Q1.txt to Q25.txt
        questions[i]=fopen(filename,"r");
        if (questions[i] == NULL)//Checking if files opened successfully
        {
            SetColor(FOREGROUND_RED);//RED color
            printf("Error opening question file %s\n", filename);
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            return ;
        }
    }
    int q_no[n];//to store question numnber which get randomly selected
    srand(time(NULL));//Seed the random number generator
    for(int i=0;i<n;)//Storing random Question numbers out of 25 questions
    {
        int found=0;
        int random_number = rand() % 25 ;//generating random numbers between 0 and 24
        for(int j=0;j<i;j++)//Checking whether that q_no has not already being stored
        {
            if(q_no[j]==random_number)
            {
                found=1;
                break;
            }
        }
        if(!found)
            q_no[i++]=random_number;
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tIC QUIZ\n");
    fprintf(quiz,"\t\t\t\t\t\tIntroduction to Computer Science\n");
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tCSL1010\n\n");
    fprintf(ans,"Answers Key:");
    for(int i=0;i<n;i++)//to store the questions into Quiz.txt
    {
        char filename[40];
        snprintf(filename,40,"Quiz present/Q%d.txt",i+1);
        FILE *question=fopen(filename,"w");
        int question_index=q_no[i];
        char ch;
        fprintf(quiz,"Q%d. ",i+1);
        while((ch=fgetc(questions[question_index]))!=EOF && ch!='$')
        {
            fputc(ch,quiz);
            fputc(ch,question);
        }
        fprintf(quiz,"\n\n");
        if(ch=='$')//to store the answers into Answers.txt
        {
            while((ch=fgetc(questions[question_index]))!=EOF)
            {
                fputc(ch,ans);
                if(ch=='A')
                    fprintf(ans,"%d",i+1);
            }
        }
        fclose(question);
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\t\"BEST OF LUCK\"");
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("\nHow many Students will take this QUIZ: ");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int sn;
    scanf("%d",&sn);
    fprintf(number,"%d",sn);
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the Duration of the Quiz in Seconds:\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int seconds;
    scanf("%d",&seconds);
    fprintf(second,"%d",seconds);
    SetColor(FOREGROUND_GREEN);//GREEN color
    printf("QUIZ SUCCESSFULLY GENERATED");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    for(int i=0;i<25;i++)//closing all file pointers for question
        fclose(questions[i]);
    fclose(quiz);
    fclose(ans);
    fclose(second);
    return ;
}
void IBQuiz(int n)//DONE
{
    FILE *quiz,*ans,*number,*second;
    second=fopen("Time.txt","w");
    quiz=fopen("Quiz.txt","w");
    ans=fopen("Answers.txt","w");
    number=fopen("number_of_students.txt","w");
    if (quiz == NULL || ans == NULL)//Checking if files opened successfully 
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error opening quiz or answer file.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return ;
    }
    FILE *questions[25];
    for(int i=0;i<25;i++)//assigning file pointers for questions
    {
        char filename[20];
        snprintf(filename, sizeof(filename), "IB/Q%d.txt", i + 1);  // Generate filename for Q1.txt to Q25.txt
        questions[i]=fopen(filename,"r");
        if (questions[i] == NULL)//Checking if files opened successfully
        {
            SetColor(FOREGROUND_RED);//RED color
            printf("Error opening question file %s\n", filename);
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            return ;
        }
    }
    int q_no[n];//to store question numnber which get randomly selected
    srand(time(NULL));//Seed the random number generator
    for(int i=0;i<n;)//Storing random Question numbers out of 25 questions
    {
        int found=0;
        int random_number = rand() % 25 ;//generating random numbers between 0 and 24
        for(int j=0;j<i;j++)//Checking whether that q_no has not already being stored
        {
            if(q_no[j]==random_number)
            {
                found=1;
                break;
            }
        }
        if(!found)
            q_no[i++]=random_number;
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tIB QUIZ\n");
    fprintf(quiz,"\t\t\t\t\t\tIntroduction to Biotechnology\n");
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tBBL1010\n\n");
    fprintf(ans,"Answers Key:");
    for(int i=0;i<n;i++)//to store the questions into Quiz.txt
    {
        char filename[40];
        snprintf(filename,40,"Quiz present/Q%d.txt",i+1);
        FILE *question=fopen(filename,"w");
        int question_index=q_no[i];
        char ch;
        fprintf(quiz,"Q%d. ",i+1);
        while((ch=fgetc(questions[question_index]))!=EOF && ch!='$')
        {
            fputc(ch,quiz);
            fputc(ch,question);
        }
        fprintf(quiz,"\n\n");
        if(ch=='$')//to store the answers into Answers.txt
        {
            while((ch=fgetc(questions[question_index]))!=EOF)
            {
                fputc(ch,ans);
                if(ch=='A')
                    fprintf(ans,"%d",i+1);
            }
        }
        fclose(question);
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\t\"BEST OF LUCK\"");
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("\nHow many Students will take this QUIZ: ");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int sn;
    scanf("%d",&sn);
    fprintf(number,"%d",sn);
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the Duration of the Quiz in Seconds:\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int seconds;
    scanf("%d",&seconds);
    fprintf(second,"%d",seconds);
    SetColor(FOREGROUND_GREEN);//GREEN color
    printf("QUIZ SUCCESSFULLY GENERATED");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    for(int i=0;i<25;i++)//closing all file pointers for question
        fclose(questions[i]);
    fclose(quiz);
    fclose(ans);
    fclose(second);
    return ;
}
void IEQuiz(int n)//DONE
{
    FILE *quiz,*ans,*number,*second;
    second=fopen("Time.txt","w");
    quiz=fopen("Quiz.txt","w");
    ans=fopen("Answers.txt","w");
    number=fopen("number_of_students.txt","w");
    if (quiz == NULL || ans == NULL)//Checking if files opened successfully 
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error opening quiz or answer file.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return ;
    }
    FILE *questions[25];
    for(int i=0;i<25;i++)//assigning file pointers for questions
    {
        char filename[20];
        snprintf(filename, sizeof(filename), "IE/Q%d.txt", i + 1);  // Generate filename for Q1.txt to Q25.txt
        questions[i]=fopen(filename,"r");
        if (questions[i] == NULL)//Checking if files opened successfully
        {
            SetColor(FOREGROUND_RED);//RED color
            printf("Error opening question file %s\n", filename);
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            return ;
        }
    }
    int q_no[n];//to store question numnber which get randomly selected
    srand(time(NULL));//Seed the random number generator
    for(int i=0;i<n;)//Storing random Question numbers out of 25 questions
    {
        int found=0;
        int random_number = rand() % 25 ;//generating random numbers between 0 and 24
        for(int j=0;j<i;j++)//Checking whether that q_no has not already being stored
        {
            if(q_no[j]==random_number)
            {
                found=1;
                break;
            }
        }
        if(!found)
            q_no[i++]=random_number;
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tIE QUIZ\n");
    fprintf(quiz,"\t\t\t\t\t\tIntroduction to Electrical Engineering\n");
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tEEL1010\n\n");
    fprintf(ans,"Answers Key:");
    for(int i=0;i<n;i++)//to store the questions into Quiz.txt
    {
        char filename[40];
        snprintf(filename,40,"Quiz present/Q%d.txt",i+1);
        FILE *question=fopen(filename,"w");
        int question_index=q_no[i];
        char ch;
        fprintf(quiz,"Q%d. ",i+1);
        while((ch=fgetc(questions[question_index]))!=EOF && ch!='$')
        {
            fputc(ch,quiz);
            fputc(ch,question);
        }
        fprintf(quiz,"\n\n");
        if(ch=='$')//to store the answers into Answers.txt
        {
            while((ch=fgetc(questions[question_index]))!=EOF)
            {
                fputc(ch,ans);
                if(ch=='A')
                    fprintf(ans,"%d",i+1);
            }
        }
        fclose(question);
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\t\"BEST OF LUCK\"");
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("\nHow many Students will take this QUIZ: ");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int sn;
    scanf("%d",&sn);
    fprintf(number,"%d",sn);
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the Duration of the Quiz in Seconds:\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int seconds;
    scanf("%d",&seconds);
    fprintf(second,"%d",seconds);
    SetColor(FOREGROUND_GREEN);//GREEN color
    printf("QUIZ SUCCESSFULLY GENERATED");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    for(int i=0;i<25;i++)//closing all file pointers for question
        fclose(questions[i]);
    fclose(quiz);
    fclose(ans);
    fclose(second);
    return ;
}
void MQuiz(int n)//DONE
{
    FILE *quiz,*ans,*number,*second;
    second=fopen("Time.txt","w");
    quiz=fopen("Quiz.txt","w");
    ans=fopen("Answers.txt","w");
    number=fopen("number_of_students.txt","w");
    if (quiz == NULL || ans == NULL)//Checking if files opened successfully 
    {
        SetColor(FOREGROUND_RED);//RED color
        printf("Error opening quiz or answer file.\n");
        SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
        return ;
    }
    FILE *questions[25];
    for(int i=0;i<25;i++)//assigning file pointers for questions
    {
        char filename[20];
        snprintf(filename, sizeof(filename), "M/Q%d.txt", i + 1);  // Generate filename for Q1.txt to Q25.txt
        questions[i]=fopen(filename,"r");
        if (questions[i] == NULL)//Checking if files opened successfully
        {
            SetColor(FOREGROUND_RED);//RED color
            printf("Error opening question file %s\n", filename);
            SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
            return ;
        }
    }
    int q_no[n];//to store question numnber which get randomly selected
    srand(time(NULL));//Seed the random number generator
    for(int i=0;i<n;)//Storing random Question numbers out of 25 questions
    {
        int found=0;
        int random_number = rand() % 25 ;//generating random numbers between 0 and 24
        for(int j=0;j<i;j++)//Checking whether that q_no has not already being stored
        {
            if(q_no[j]==random_number)
            {
                found=1;
                break;
            }
        }
        if(!found)
            q_no[i++]=random_number;
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tMAthematics QUIZ\n");
    fprintf(quiz,"\t\t\t\t\t\t\t\t\tMAL1010\n\n");
    fprintf(ans,"Answers Key:");
    for(int i=0;i<n;i++)//to store the questions into Quiz.txt
    {
        char filename[40];
        snprintf(filename,40,"Quiz present/Q%d.txt",i+1);
        FILE *question=fopen(filename,"w");
        int question_index=q_no[i];
        char ch;
        fprintf(quiz,"Q%d. ",i+1);
        while((ch=fgetc(questions[question_index]))!=EOF && ch!='$')
        {
            fputc(ch,quiz);
            fputc(ch,question);
        }
        fprintf(quiz,"\n\n");
        if(ch=='$')//to store the answers into Answers.txt
        {
            while((ch=fgetc(questions[question_index]))!=EOF)
            {
                fputc(ch,ans);
                if(ch=='A')
                    fprintf(ans,"%d",i+1);
            }
        }
        fclose(question);
    }
    fprintf(quiz,"\t\t\t\t\t\t\t\t\t\"BEST OF LUCK\"");
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("\nHow many Students will take this QUIZ: ");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int sn;
    scanf("%d",&sn);
    fprintf(number,"%d",sn);
    SetColor(FOREGROUND_GREEN | FOREGROUND_RED);//YELLOW Text
    printf("Enter the Duration of the Quiz in Seconds:\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    int seconds;
    scanf("%d",&seconds);
    fprintf(second,"%d",seconds);
    SetColor(FOREGROUND_GREEN);//GREEN color
    printf("QUIZ SUCCESSFULLY GENERATED");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    for(int i=0;i<25;i++)//closing all file pointers for question
        fclose(questions[i]);
    fclose(quiz);
    fclose(ans);
    fclose(second);
    return ;
}
void clear_Quiz_present_folder()//deleting all the Questions before new Questions are generated
{
    FILE *clear;
    clear=fopen("number_of_Questions.txt","r");
    int n;
    fscanf(clear,"%d",&n);
    fclose(clear);
    for(int i=1;i<=n;i++)
    {
        char filename[40];
        snprintf(filename,20,"Quiz present/Q%d.txt",i);
        remove(filename);
    }
}
//Working to print the Histogram
void draw_histogram(int table[],char roll_no[][20],int n)
{
    printf("\033[0;36m");//CYAN text;//BLUE text
    printf("\nThe Graph is :\n\n");
    SetColor(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);  // White text
    /*
    BASIC STRUCTURE OF THE GRAPH
     10|             *
      9|     *       *
      8|     *   *   * 
      7|     *   *   *
      6| *   *   *   *  
      5| *   *   *   *   *
      4| *   *   *   *   *   *
      3| *   *   *   *   *   *   *
      2| *   *   *   *   *   *   *
      1| *   *   *   *   *   *   *
      0|___ ___ ___ ___ ___ ___ ___   
    */
   int i,j,k;
   int largest=strlen(roll_no[0]); //to return the largest number in table[]
   for(i=large(table,n);i>=0;i--) //to print the table
   {
        if(i>=0 && i<=9)
        {
            printf("0");
        }
        printf("%d|",i);
        for(j=0;j<n && i!=0;j++)
        {
            if(table[j]==i)
            {
                for(k=0;k<largest/2;k++)//to give perfect spacing
                    printf(" ");
                printf("*");
                for(k=0;k<largest/2-isEven(largest);k++)//to give perfect spacing
                    printf(" ");
                table[j]-=1;
                printf(" ");
            }
            else
            {
                for(k=0;k<=largest;k++)//to give perfect spacing
                    printf(" ");
            }
        }
        if(i!=0)
            printf("\n");
   }
   for(i=0;i<n;i++)  //to print   1|____ ____ ____ ____ ____ ____   .......
   {
        for(j=0;j<largest;j++)
            printf("_");
        printf(" ");
   }
   printf("\n");
   printf("  ");
   for(i=0;i<n;i++) //to print the roll number
   {
        int spaces=largest-strlen(roll_no[i]); 
        for(k=0;k<spaces/2;k++) //to give perfect spaces
            printf(" ");
        printf("%s",roll_no[i]);
        for(;k<=spaces;k++)
            printf(" ");
   }
   printf("\b"); //to remove the extra whitespace at the end
   printf("\n\n\n");//to clear indexing
   return;
}
int large(int arr[],int n)
{
    int largest=arr[0];
    for(int i=0;i<n;i++)
        if(largest<arr[i])
            largest=arr[i];
    return largest;
}
int isEven(int num)
{
    if(num%2==0)
        return 1;
    else
        return 0;
}