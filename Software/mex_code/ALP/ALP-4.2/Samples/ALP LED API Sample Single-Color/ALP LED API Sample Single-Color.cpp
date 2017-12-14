// ALP LED API Sample Single-Color.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "alp.h"
#include "AlpUserInterface.h"
#include "AlpFrames.h"
#include <conio.h>

// Error handling policy: Quit, whenever an ALP error happens.
// VERIFY_ALP also echoes each successfull ALP API call (in contrast to VERIFY_ALP_NO_ECHO)
#define VERIFY_ALP( AlpApiCall ) \
	if (AlpError(AlpApiCall, _T(#AlpApiCall), true)) { Pause(); return 1; }
#define VERIFY_ALP_NO_ECHO( AlpApiCall ) \
	if (AlpError(AlpApiCall, _T(#AlpApiCall), false)) { Pause(); return 1; }

int _tmain(int /* argc */, _TCHAR* /* argv */[])
{
	ALP_ID AlpDevId, AlpSeqId, AlpLedId;
	long nDmdWidth(0), nDmdHeight(0);

// General ALP API stuff //////////////////////////////////////////////////////
	// Initialize the ALP device
	VERIFY_ALP( AlpDevAlloc( 0, 0, &AlpDevId ) );
	VERIFY_ALP( AlpDevInquire( AlpDevId, ALP_DEV_DISPLAY_WIDTH, &nDmdWidth ) );
	VERIFY_ALP( AlpDevInquire( AlpDevId, ALP_DEV_DISPLAY_HEIGHT, &nDmdHeight ) );
	_tprintf( _T("Note: DMD size: %i x %i pixels\r\n"), nDmdWidth, nDmdHeight );

	// Initialize image data (completely done in during construction of the ImageData variable)
	const long nFrames=5;
	CAlpFramesMovingSquare ImageData(nFrames, nDmdWidth, nDmdHeight);

	// Allocate a sequence and load data
	VERIFY_ALP( AlpSeqAlloc( AlpDevId, 1, nFrames, &AlpSeqId ) );
	VERIFY_ALP( AlpSeqPut( AlpDevId, AlpSeqId, 0, nFrames, ImageData(0) ) );
	VERIFY_ALP( AlpSeqTiming( AlpDevId, AlpSeqId,
		0, 200000,	// 200ms, i.e. 5Hz
		0, 0, 0 ) );

// LED Stuff //////////////////////////////////////////////////////////////////
	// Initialize a LED.
	// Note: The LED type cannot be detected automatically.
	// It is important that the user enters the correct type.
	// This affects parameters like maximum allowed continuous
	// forward current, but also calculation of junction temperature
	// depends on the correct LED type.
	_tprintf( _T("\r\nPlease enter the correct type of the connected LED\r\n") );
	long const LedType = AlpLedTypePrompt();
	VERIFY_ALP( AlpLedAlloc( AlpDevId, LedType, NULL, &AlpLedId ) );

	// Just for information: inquire the allowed continuous forward current of this LED type
	long nLedContCurrent_mA(0);
	VERIFY_ALP( AlpLedInquire( AlpDevId, AlpLedId, ALP_LED_SET_CURRENT, &nLedContCurrent_mA ) );
	_tprintf( _T("Note: This LED can be driven with continuous current of %0.1f A\r\n"), (double)nLedContCurrent_mA/1000 );
	// Report the configuration of this HLD. These parameters could be used for AlpLedAlloc.
	// Single-Color configurations usually have bus addresses 24, 64.
	tAlpHldPt120AllocParams LedParams;
	VERIFY_ALP( AlpLedInquireEx( AlpDevId, AlpLedId, ALP_LED_ALLOC_PARAMS, &LedParams ) );
	_tprintf( _T("Note: The LED driver has I2C bus addresses DAC=%i, ADC=%i\r\n"), LedParams.I2cDacAddr, LedParams.I2cAdcAddr);

	// User enters percentage for LED brightness:
	// Note: this application limits input values to 100 percent,
	//	whilst the API allows overdriving the LED
	_tprintf( _T("\r\nEnter requested brightness. ") );
	long nLedBrightness_Percent(AlpPercentPrompt(_T("Percent (0..100): ")));
	_tprintf( _T("Note: Expected current at %i%% is %0.1f A\r\n"), nLedBrightness_Percent,
		(double)nLedBrightness_Percent/100 * (double)nLedContCurrent_mA/1000 );

	// Switch LED on
	VERIFY_ALP( AlpLedControl( AlpDevId, AlpLedId, ALP_LED_BRIGHTNESS, nLedBrightness_Percent ) );

	// Start continuous display
	VERIFY_ALP( AlpProjStartCont( AlpDevId, AlpSeqId ) );

	// Monitor LED current and temperature (run until a key has been hit, or until "break;")
	_tprintf( _T("\r\nPress a key to stop projection.\r\n") );
	while (0 == _kbhit()) {
		long nLedCurrent_mA(0), nLedJunctionTemp(0);
		Sleep( 1000 );	// wait 1 second
		
		// Inquire measurements:
		VERIFY_ALP_NO_ECHO( AlpLedInquire( AlpDevId, AlpLedId, ALP_LED_MEASURED_CURRENT, &nLedCurrent_mA ) );
		VERIFY_ALP_NO_ECHO( AlpLedInquire( AlpDevId, AlpLedId, ALP_LED_TEMPERATURE_JUNCTION, &nLedJunctionTemp ) );

		// Report values.
		// Current unit: mA, temperature unit: 1°C/256
		_tprintf( _T("Note: Actual LED current=%0.1f A; Junction Temperature=%0.1f °C\r"),
			(double)nLedCurrent_mA/1000, (double)nLedJunctionTemp/256 );

		// If the temperature sensor is disconnected from the HLD, then
		// very low temperatures (below -200°C or so) are reported
		if (nLedJunctionTemp<0)
			_tprintf( _T("\nWarning: It seems like the thermistor cable is not properly connected.\r") );

		// Switch off at 100°C (generally, LEDs can stand much
		// higher temperatures, but this differs between LED types)
		if (nLedJunctionTemp>100*256) {
			_tprintf( _T("\nWarning: LED becomes quite hot. Stopping.\r") );
			break;
		}
	}
	_tprintf( _T("\r\n\r\n") );	// blank line

	// Clean up
	VERIFY_ALP( AlpDevHalt(AlpDevId) );
	VERIFY_ALP( AlpDevFree(AlpDevId) );	// this also switches the LED off
	_tprintf( _T("Finished.\r\n") );
	Pause();
	return 0;
}

