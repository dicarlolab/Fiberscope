/*ULAI10.C================================================================

File:                         ULAI10.C

Library Call Demonstrated:    cbALoadQueue()

Purpose:                      Loads an A/D board's channel/gain queue.

Demonstration:                Prepares a channel/gain queue and loads it
                              to the board. An analog input function
                              is then called to show how the queue
                              values work.

Other Library Calls:          cbErrHandling()

Special Requirements:         Board 0 must have an A/D converter and
                              channel gain queue hardware.


Copyright (c) 1995-2002, Measurement Computing Corp.
All Rights Reserved.
=========================================================================*/


/* Include files */
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "..\cbw.h"


/* Prototypes */
void ClearScreen (void);
void GetTextCursor (int *x, int *y);
void MoveCursor (int x, int y);


#define NumChans  4
#define NUMPOINTS 10

void main ()
    {
    /* Variable Declarations */
    int ULStat = 0;
	int BoardNum = 0;
    int  i, LowChan, HighChan, Gain, Options, SampleNum, Chan;
    long Count, Rate;
	HANDLE MemHandle = 0;
    WORD *ADData;
	DWORD *ADData32;
    short ChanArray[NumChans];
    short GainArray[NumChans];
    float    RevLevel = (float)CURRENTREVNUM;
	BOOL HighResAD = FALSE;
	int  ADRes;

    /* Declare UL Revision Level */
    ULStat = cbDeclareRevision(&RevLevel);

    /* Initiate error handling
        Parameters:
            PRINTALL :all warnings and errors encountered will be printed
            DONTSTOP :program will continue even if error occurs.
                     Note that STOPALL and STOPFATAL are only effective in 
                     Windows applications, not Console applications. 
   */
    cbErrHandling (PRINTALL, DONTSTOP);

	 /* Get the resolution of A/D */
	cbGetConfig(BOARDINFO, BoardNum, 0, BIADRES, &ADRes);
	
	/* check If the resolution of A/D is higher than 16 bit.
       If it is, then the A/D is high resolution. */
	if(ADRes > 16)
		HighResAD = TRUE;

	/*  set aside memory to hold data */
	if(HighResAD)
		{
		MemHandle = cbWinBufAlloc32(NUMPOINTS*NumChans);
		ADData32 = (DWORD*) MemHandle;
		}
	else
		{
		MemHandle = cbWinBufAlloc(NUMPOINTS*NumChans);
		ADData = (WORD*) MemHandle;
		}

    if (!MemHandle)    /* Make sure it is a valid pointer */
        {
        printf("\nout of memory\n");
        exit(1);
        }

    /* set up the display screen */
    ClearScreen();
    printf ("Demonstration of cbALoadQueue()\n\n");

    /* load the arrays with values */
    ChanArray[0] = 0;
    GainArray[0] = BIP10VOLTS;

    ChanArray[1] = 1;
    GainArray[1] = BIP5VOLTS;

    ChanArray[2] = 2;
    GainArray[2] = BIP2PT5VOLTS;

    ChanArray[3] = 3;
    GainArray[3] = BIP1PT25VOLTS;

    /* load the channel/gain values into the queue
        Parameters:
            BoardNum    :the number used by CB.CFG to describe this board
            ChanArray[] :array of channel values
            GainArray[] :array of gain values
            Count       :the number of elements in the arrays (0=disable queue) */
    cbALoadQueue (BoardNum, ChanArray, GainArray, NumChans);

    /* call an analog input function to show how the gain queue values
       supercede those passed to the function
     Collect the values with cbAInScan()
        Parameters:
            BoardNum    :the number used by CB.CFG to describe this board
            LowChan     :the first channel of the scan
            HighChan    :the last channel of the scan
            NumCount    :the total number of A/D samples to collect
            Rate        :sample rate in samples per second
            Gain        :the gain for the board
            ADData[]    :the array for the collected data values
            Options     :data collection options  */

    LowChan = 0;        /* Channel numbers and gain are ignored */
    HighChan = 0;
    Gain = BIP5VOLTS;
    Count = NUMPOINTS * NumChans;
    Rate = 1000;                    /* sampling rate (samples per second) */
    Options = CONVERTDATA;          /* return data as 12-bit values */
    cbAInScan (BoardNum, LowChan, HighChan, Count, &Rate, Gain, MemHandle, Options);

    /* show the results */
    printf ("Here are the values returned, notice that the gain is different for\n");
    printf ("each channel. \n\n");

    printf ("    Channel Numbers\n");
    printf ("  0       1       2       3\n");
    printf ("+-10V   +-5V    +-2.5V  +-1.25V\n");
    printf ("----    ----    ----    ----\n");

    i = 0;
    for (SampleNum=0; SampleNum<NUMPOINTS; SampleNum++)
        {
        for (Chan=0; Chan<NumChans; Chan++)
			{
			if(HighResAD)
				printf ("%8u    ",ADData32[i++]);
			else
				printf ("%4u    ",ADData[i++]);
			}
        printf ("\n");
        }
    printf ("\n");

	cbWinBufFree(MemHandle);
}


/***************************************************************************
*
* Name:      ClearScreen
* Arguments: ---
* Returns:   ---
*
* Clears the screen.
*
***************************************************************************/

#define BIOS_VIDEO   0x10

void
ClearScreen (void)
{
	COORD coordOrg = {0, 0};
	DWORD dwWritten = 0;
	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	if (INVALID_HANDLE_VALUE != hConsole)
		FillConsoleOutputCharacter(hConsole, ' ', 80 * 50, coordOrg, &dwWritten);

	MoveCursor(0, 0);

    return;
}


/***************************************************************************
*
* Name:      MoveCursor
* Arguments: x,y - screen coordinates of new cursor position
* Returns:   ---
*
* Positions the cursor on screen.
*
***************************************************************************/


void
MoveCursor (int x, int y)
{
	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);

	if (INVALID_HANDLE_VALUE != hConsole)
	{
		COORD coordCursor;
		coordCursor.X = (short)x;
		coordCursor.Y = (short)y;
		SetConsoleCursorPosition(hConsole, coordCursor);
	}

    return;
}


/***************************************************************************
*
* Name:      GetTextCursor
* Arguments: x,y - screen coordinates of new cursor position
* Returns:   *x and *y
*
* Returns the current (text) cursor position.
*
***************************************************************************/

void
GetTextCursor (int *x, int *y)
{
	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	CONSOLE_SCREEN_BUFFER_INFO csbi;

	*x = -1;
	*y = -1;
	if (INVALID_HANDLE_VALUE != hConsole)
	{
		GetConsoleScreenBufferInfo(hConsole, &csbi);
		*x = csbi.dwCursorPosition.X;
		*y = csbi.dwCursorPosition.Y;
	}

    return;
}





