/*ULAI12.C****************************************************************

File:                         ULAI12.C

Library Call Demonstrated:    cbAInScan(), EXTCLOCK option

Purpose:                      Scans a range of A/D Input Channels and stores
                              the sample data in an array at a sample rate
                              specified by an external clock.

Demonstration:                Displays the analog input on two channels.

Other Library Calls:          cbErrHandling()

Special Requirements:         Board 0 must have an A/D converter and
                              support the EXTCLOCK option.
                              Analog signals on two input channels.
                              Freq. on trigger 0 input.

Copyright (c) 1995-2002, Measurement Computing Corp.
All Rights Reserved.
***************************************************************************/


/* Include files */
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "..\cbw.h"


/* Prototypes */
void ClearScreen (void);
void GetTextCursor (int *x, int *y);
void MoveCursor (int x, int y);


void main ()
    {
    /* Variable Declarations */
    int Row, Col, I, J;
    int BoardNum = 0;
    int ULStat = 0;
    int LowChan = 0;
    int HighChan = 1;
    int Gain = BIP5VOLTS;
    long Count = 100;
    long Rate = 1;
	HANDLE MemHandle = 0;
    WORD *ADData;
	DWORD *ADData32;
    unsigned Options;
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
		MemHandle = cbWinBufAlloc32(Count);
		ADData32 = (DWORD*) MemHandle;
		}
	else
		{
		MemHandle = cbWinBufAlloc(Count);
		ADData = (WORD*) MemHandle;
		}

    if (!MemHandle)    /* Make sure it is a valid pointer */
        {
        printf("\nout of memory\n");
        exit(1);
        }

    /* set up the display screen */
    ClearScreen();
    printf ("Demonstration of cbAInScan() using EXTCLOCK option.\n\n");
    printf ("NOTE: The EXTCLOCK option ignores the rate parameter and\n");
    printf ("      looks for an external clock at the trigger input.\n\n");
    printf ("Please wait.  Collecting data...\n\n");

    /* Collect the values with cbAInScan()
        Parameters:
             BoardNum    :the number used by CB.CFG to describe this board
             LowChan     :low channel of the scan
             HighChan    :high channel of the scan
             Count       :the total number of A/D samples to collect
             Rate        :sample rate in samples per second
             Gain        :the gain for the board
             DataBuffer[]:the array for the collected data values
             Options     :data collection options */
    Count = 100;
    Options = CONVERTDATA + EXTCLOCK;
    ULStat = cbAInScan (BoardNum, LowChan, HighChan, Count, &Rate,
                                            Gain, MemHandle, Options);

    /* display the data */
    for (J = 0; J <= 1; J++)       /* loop through the channels */
        {
        printf ("\nThe first 5 values on Channel %d are ", J);
        GetTextCursor (&Col, &Row);

        for (I = 0; I < 5; I++)   /* loop through the values & print */
            {
            MoveCursor (Col, Row + I);
			if(HighResAD)
				printf ("%8u", ADData32[ I * 2 + J]);
			else
				printf ("%4u", ADData[ I * 2 + J]);
            }
        printf ("\n");
        }

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

