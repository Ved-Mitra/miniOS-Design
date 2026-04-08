/*
• Install OpenCV
• sudo apt update
• sudo apt install libopencv-dev
*/

#include <opencv2/opencv.h>
#include <stdio.h>

int main()
{
    // Create a VideoCapture object and open the input file
    // Change '0' to '1' or '2'
    // if you have multiple cameras to select which one to use
    CvCapture *capture = cvCaptureFromCAM(0);

    // Check if camera opened successfully
    if (!capture)
    {
        fprintf(stderr, "Error: Unable to open camera\n");
        return -1;
    }
    // Create a window for display.
    cvNamedWindow("Camera Output", CV_WINDOW_AUTOSIZE);

    // Read and display frames from the camera until a key is pressed
    while (1)
    {
        // Capture frame-by-frame
        IplImage *frame = cvQueryFrame(capture);

        // If the frame is empty, break immediately
        if (!frame)
            break;

        // Display the resulting frame
        cvShowImage("Camera Output", frame);

        // Press 27 (ESC) to exit
        char c = (char)cvWaitKey(25);
        if (c == 27)
            break;
    }

    // When everything done, release the video capture and write object
    cvReleaseCapture(&capture);
    cvDestroyWindow("Camera Output");
    return 0;
}