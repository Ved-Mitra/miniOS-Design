#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/color.h"

int vars[26]; //a-z variable

void skip_whitespace(char **p) {
    while (**p == ' ' || **p == '\t') (*p)++;
}

int expr(char **p);

int factor(char **p) {
    int val = 0;
    skip_whitespace(p);
    if (**p == '(') {
        (*p)++;
        val = expr(p);
        skip_whitespace(p);
        if (**p == ')') (*p)++;
    } else if (**p >= 'a' && **p <= 'z') {
        val = vars[**p - 'a'];
        (*p)++;
    } else if (**p >= '0' && **p <= '9') {
        while (**p >= '0' && **p <= '9') {
            val = val * 10 + (**p - '0');
            (*p)++;
        }
    } else if (**p == '-') {
        (*p)++;
        val = -factor(p);
    }
    skip_whitespace(p);
    return val;
}

int term(char **p) {
    int val = factor(p);
    while (1) {
        skip_whitespace(p);
        if (**p == '*') {
            (*p)++;
            val *= factor(p);
        } else if (**p == '/') {
            (*p)++;
            int d = factor(p);
            if (d == 0) {
                printf("Error: Division by zero\n");
                return 0;
            }
            val /= d;
        } else if (**p == '%') {
            (*p)++;
            int d = factor(p);
            if (d == 0) {
                printf("Error: Modulo by zero\n");
                return 0;
            }
            val %= d;
        } else {
            break;
        }
    }
    return val;
}

int expr(char **p) {
    int val = term(p);
    while (1) {
        skip_whitespace(p);
        if (**p == '+') {
            (*p)++;
            val += term(p);
        } else if (**p == '-') {
            (*p)++;
            val -= term(p);
        } else {
            break;
        }
    }
    return val;
}

void evaluate(char *line) {
    char *p = line;
    skip_whitespace(&p);
    if (*p == 0 || *p == '\n') return;

    // Check for variable assignment (e.g. a=2+1 or a = 2+1)
    int dest_var = -1;
    char *q = p;
    if (*q >= 'a' && *q <= 'z') {
        q++;
        skip_whitespace(&q);
        if (*q == '=') {
            dest_var = *p - 'a';
            q++;
            p = q; // Move p to after the '='
        }
    }

    int result = expr(&p);

    if (dest_var != -1) {
        vars[dest_var] = result;
        printf("%c = %d\n", 'a' + dest_var, result);
    } else {
        printf("%d\n", result);
    }
}

int main(int argc, char *argv[]) {
    char buf[128];
    for (int i = 0; i < 26; i++) vars[i] = 0;

    printf(CYAN "Calculator\n" RESET);
    printf(CYAN "Type expressions (e.g., 2+1, a=2+1). Type 'quit' to exit.\n" RESET);

    while (1) {
        printf("cal> ");
        memset(buf, 0, sizeof(buf));
        gets(buf, sizeof(buf));
        
        if (buf[0] == 0) break;
        
        // Remove newline character
        for(int i = 0; i < sizeof(buf); i++) {
            if(buf[i] == '\n' || buf[i] == '\r') {
                buf[i] = 0;
                break;
            }
        }

        if (strcmp(buf, "quit") == 0 || strcmp(buf, "exit") == 0) {
            break;
        }
        
        // Evaluate if not empty
        if (buf[0] != 0) {
            evaluate(buf);
        }
    }
    exit(0);
}
