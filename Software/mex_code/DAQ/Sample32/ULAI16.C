/*ULAI16.C****************************************************************

File:                         ULAI16.C

Library Call Demonstrated:    cbAInScan(), SHUNTCAL mode

Purpose:                      Executes the bridge nulling and shunt calibration 
							  procedure for a specified channel  

Demonstration:                Displays the offset and gain adjustment factors.
                          
Other Library Calls:          cbErrHandling()

Special Requirements:         Board 0 must support bridge measurement and
							  the shunt resistor is connected between
							  AI+ and Ex- internally

Copyright (c) 1995-2009, Measurement Computing Corp.
All Rights Reserved.
***************************************************************************/


/* Include files */
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "..\cbw.h"

typedef enum
{
        FullBridgeI = 0, FullBridgeII, FullBridgeIII,
        HalfBridgeI, HalfBridgeII,
        QuarterBridgeI, QuarterBridgeII
} StrainConfig;


/* Prototypes */
void ClearScreen (void);
void GetTextCursor (int *x, int *y);
void MoveCursor (int x, int y);
double CalculateStrain(StrainConfig strainCfg, double u, double gageFactor, double poissonRatio);

void main ()
   {
   /* Variable Declarations */
   int I;
   int BoardNum = 0;
   int ULStat = 0;
   int Chan = 0;
   int Gain = NOTUSED;
   long Count = 1000;
   long Rate = 1000;
   HANDLE MemHandle = 0;
   double ADData[1000];
   unsigned Options;

   StrainConfig StrainConfiguration = QuarterBridgeI;

   double InitialVoltage = 0.0;	//Bridge output voltage in the unloaded condition. This value is subtracted from any measurements before scaling equations are applied. 		
   double VInitial = 0.0;
   double OffsetAdjustmentFactor = 0.0;
   double GainAdjustmentFactor = 0.0;
   double Total = 0.0;
   double VOffset = 0.0;
   double RShunt = 100000;			// Resistance of Shunt Resistor
   double RGage = 350;				// Gage Resistance 
   double VExcitation = 2.5;		// Excitation voltage
   double GageFactor = 2;
   double PoissonRatio = 0;
   double VActualBridge;			// Actual bridge voltage
   double REffective;				// Effective resistance
   double VSimulatedBridge;			// Simulated bridge voltage
   double MeasuredStrain;
   double SimulatedStrain;

   float    RevLevel = (float)CURRENTREVNUM;

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

    /* set up the display screen */
    ClearScreen();

	VInitial = InitialVoltage / VExcitation;

	// Calculate the offset adjusment factor on a resting gage in software

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

    Options = SCALEDATA;
    ULStat = cbAInScan (BoardNum, Chan, Chan, Count, &Rate,
                                            Gain, ADData, Options);

	for ( I = 0; I < Count; I++)
		Total = Total + ADData [I];

	VOffset = Total / Count; 

	VOffset = VOffset - VInitial;

    OffsetAdjustmentFactor = CalculateStrain(StrainConfiguration, VOffset, GageFactor, PoissonRatio);

	printf ("Offset Adjustment\n");

	printf ("     Meaured Strain: %.9f\n\n", OffsetAdjustmentFactor);

	
	//	Enable Shunt Calibration Circuit and Collect the values and
	//  Calculate the Actual Bridge Voltage

	Options = SCALEDATA | SHUNTCAL;
    ULStat = cbAInScan (BoardNum, Chan, Chan, Count, &Rate,
                                            Gain, ADData, Options);

	Total = 0.0;

	for ( I = 0; I < Count; I++)
		Total = Total + ADData [I];

	VActualBridge = Total / Count;

	VActualBridge = VActualBridge - VInitial;

    MeasuredStrain = CalculateStrain(StrainConfiguration, VActualBridge, GageFactor, PoissonRatio);

	// Calculate the Simulated Bridge Voltage with a shunt resistor

	REffective = (RGage * RShunt)/(RGage + RShunt);

	VSimulatedBridge =(REffective / (REffective + RGage) - 0.5); 

    SimulatedStrain = CalculateStrain(StrainConfiguration, VSimulatedBridge, GageFactor, PoissonRatio);

	printf ("Gain Adjustment \n");

	printf ("     Simulated Strain: %.9f\n", SimulatedStrain);

	printf ("     Meaured Strain: %.9f\n", MeasuredStrain);

	GainAdjustmentFactor = SimulatedStrain / (MeasuredStrain - OffsetAdjustmentFactor);

	printf ("     Gain Adjustment Factor: %.9f\n", GainAdjustmentFactor);

}

double CalculateStrain(StrainConfig strainCfg, double u, double gageFactor, double poissonRatio)
{
        double starin = 0;
        switch (strainCfg)
        {
            case FullBridgeI:
                starin = (-u) / gageFactor;
                break;
            case FullBridgeII:
                starin = (-2 * u) / (gageFactor * (1 + poissonRatio));
                break;
            case FullBridgeIII:
                starin = (-2 * u) / (gageFactor * ((poissonRatio + 1) - (u * (poissonRatio - 1))));
                break;
            case HalfBridgeI:
                starin = (-4 * u) / (gageFactor * ((poissonRatio + 1) - 2 * u * (poissonRatio - 1)));
                break;
            case HalfBridgeII:
                starin = (-2 * u) / gageFactor;
                break;
            case QuarterBridgeI:
            case QuarterBridgeII:
                starin = (-4 * u) / (gageFactor * ((1 + 2 * u)));
                break;
        }

        return starin;
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

