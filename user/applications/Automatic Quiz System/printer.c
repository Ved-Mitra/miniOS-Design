// sudo apt-get install libcups2-dev

#include <cups/cups.h>
#include <stdio.h>

int main()
{
    // Name of the file to print
    const char *filename = "sample.txt";
    // Name of the printer (NULL for the default printer)
    const char *printer = NULL;

    // Check if CUPS server is running and get the default printer if none specified
    if ((printer = cupsGetDefault()) == NULL)
    {
        fprintf(stderr, "Error: No default printer available\n");
        return 1;
    }

    printf("Default printer: %s\n", printer);
    printf("File to print: %s\n", filename);

    // Add the job to the default printer queue
    int job_id = cupsPrintFile(printer, filename, "C Program Print Job", 0, NULL);

    if (job_id == 0)
    {
        fprintf(stderr, "Failed to print file: %s\n", cupsLastErrorString());
        return 1;
    }

    printf("Print job successfully submitted. Job ID: %d\n", job_id);
    return 0;
}