// ALP LED API Sample Multi-Color.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "alp.h"
#include "AlpUserInterface.h"
#include "AlpFrames.h"
#include <crtdbg.h>

// Error handling policy: Quit, whenever an ALP error happens.
// VERIFY_ALP also echoes each successfull ALP API call (in contrast to VERIFY_ALP_NO_ECHO)
#define VERIFY_ALP( AlpApiCall ) \
	if (AlpError(AlpApiCall, _T(#AlpApiCall), true)) { Pause(); return 1; }
#define VERIFY_ALP_NO_ECHO( AlpApiCall ) \
	if (AlpError(AlpApiCall, _T(#AlpApiCall), false)) { Pause(); return 1; }

int _tmain(int /* argc */, _TCHAR* /* argv */[])
{
	// As of the time of writing this, ALP supports up to 3 gated synch outputs.
	// This (and the set of LED driver I2C addresses) restricts the number of LEDs that
	// can be controlled by a single ALP:
	long const nMaxLedCount=3;
	long nLedCount=0;	// number of LEDs actually in use (up to nMaxLedCount)

	ALP_ID AlpDevId, AlpSeqId, AlpLedId[nMaxLedCount];
	long nLedBusNumbers[nMaxLedCount]; // The Bus Number reflects the
		// configuration of the LED drivers control data bus: it
		// translates to I2C addresses, and it selects the according
		// gated synchronization signal.
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
	long const nPicTimeInMs = Choice( _T("Use Low or High frame rate?"), _T("LH"), true )==_T('H')
		?2		// user pressed 'H': 2ms (500Hz)
		:200;	// user pressed 'L' or ESC: 200ms (5Hz)
	_tprintf( _T("Note: Sequence timing: PicTime=%i ms, i.e. Frame rate=%i fps\r\n"),
		nPicTimeInMs, 1000/nPicTimeInMs );	// convert ms to Hz
	VERIFY_ALP( AlpSeqAlloc( AlpDevId, 1, nFrames, &AlpSeqId ) );
	VERIFY_ALP( AlpSeqPut( AlpDevId, AlpSeqId, 0, nFrames, ImageData(0) ) );
	VERIFY_ALP( AlpSeqTiming( AlpDevId, AlpSeqId,
		0, nPicTimeInMs*1000,	// convert ms to µs
		0, 0, 0 ) );

// LED Initialization Stuff ///////////////////////////////////////////////////
	// Initialize up to "nMaxLedCount" LEDs.
	for (long nLedBusNumber=0; nLedBusNumber<nMaxLedCount; nLedBusNumber++) {
		// Report the configuration of this HLD. These parameters are
		// used for AlpLedAlloc and can be inquired using AlpLedInquireEx.
		tAlpHldPt120AllocParams LedParams={24+2*nLedBusNumber, 64+2*nLedBusNumber};
		_tprintf( _T("\r\nNote: Initializing LED driver #%i at I2C bus addresses DAC=%i, ADC=%i\r\n"),
			nLedBusNumber, LedParams.I2cDacAddr, LedParams.I2cAdcAddr);

		// Note: The LED type cannot be detected automatically.
		// It is important that the user enters the correct type.
		// This affects parameters like maximum allowed continuous
		// forward current, but also calculation of junction temperature
		// depends on the correct LED type.
		_tprintf( _T("Please enter the correct type of the connected LED#%i! ")
			_T("ESC skips this LED.\r\n"), nLedBusNumber );
		long const LedType = AlpLedTypePrompt();
		if (0==LedType)
			continue;	// skip this LED, because the user has pressed ESC

		// Use this LED and Increment number of available LEDs.
		long const nLedIndex = nLedCount;
		nLedBusNumbers[nLedIndex] = nLedBusNumber;
		nLedCount++;

		// AlpLedAlloc allows to have UserStructPtr==NULL. In this case it traverses known
		// I2C bus addresses. We could rely on their order as attached at the bus. But
		// imagine the case that the first LED (say, the red one) has an issue like
		// power-down or disconnected. Then AlpLedAlloc would continue searching and
		// find the second LED, assuming that this is the red one.
		// So we want to explicitly supply I2C bus addresses of multi-LED systems.
		// Valid Addresses can be obtained from the ALP-4 high-speed API description.
		VERIFY_ALP( AlpLedAlloc( AlpDevId, LedType, &LedParams, &AlpLedId[nLedIndex] ) );

		// Just for information: inquire the allowed continuous forward current of this LED type
		long nLedContCurrent_mA(0);
		VERIFY_ALP( AlpLedInquire( AlpDevId, AlpLedId[nLedIndex], ALP_LED_SET_CURRENT, &nLedContCurrent_mA ) );
		_tprintf( _T("Note: LED#%i can be driven with continuous current of %0.1f A\r\n"),
			nLedBusNumber, (double)nLedContCurrent_mA/1000 );

		// User enters percentage for LED brightness:
		// Note: this application limits input values to 100 percent,
		//	whilst the API allows overdriving the LED
		_tprintf( _T("\r\nEnter requested brightness for LED#%i. "), nLedBusNumber );
		long nLedBrightness_Percent(AlpPercentPrompt(_T("Percent (0..100): ")));
		_tprintf( _T("Note: Expected current at %i%% is %0.1f A\r\n"), nLedBrightness_Percent,
			(double)nLedBrightness_Percent/100 * (double)nLedContCurrent_mA/1000 );

		// Switch LED on
		VERIFY_ALP( AlpLedControl( AlpDevId, AlpLedId[nLedIndex], ALP_LED_BRIGHTNESS, nLedBrightness_Percent ) );
	}

// Gated Synch Stuff //////////////////////////////////////////////////////////
	for (long nLedIndex=0; nLedIndex<nLedCount; nLedIndex++) {
		// Each LED driver is connected to its own gated synchronization signal.

		// Fill out the tAlpDynSynchOutGate data structure:
		tAlpDynSynchOutGate AlpSynchGate;
		_ASSERT( sizeof(AlpSynchGate) == 18 );	// verify that the compiler correctly aligns members of this structure
		memset( &AlpSynchGate, 0, sizeof(AlpSynchGate) );	// Initialize: reset all 18 bytes to "zero"

		// The trigger input of the ViALUX HLD has high-active polarity, '1' pulses switch the LED on:
		AlpSynchGate.Polarity = 1;
		// set the synch periodicity according to the sequence
		AlpSynchGate.Period = nFrames;

		// The gate "opens" with a periodicity according the number of available LEDs (round-robin).
		// Example (Three LEDs): Switch the Synch Pulse on for frames
		//    0, 3, 6 ... (1st LED, i.e. LED#0)
		// or 1, 4, 7 ... (2nd LED, i.e. LED#1)
		// or 2, 5, 8 ... (3rd LED, i.e. LED#2)
		// Example (Two LEDs): Switch the Synch Pulse on for frames
		//    0, 2, 4 ... (1st LED, e.g. LED#0 or LED#1)
		// or 1, 3, 5 ... (2nd LED, e.g. LED#1 or LED#2)
		for (long nFrameNumber=nLedIndex;		// set the first bright frame of this LED
			nFrameNumber<AlpSynchGate.Period;	// stop at period, because "Gates" above Period are ignored
			nFrameNumber += nLedCount)			// period of pulses
			AlpSynchGate.Gate[nFrameNumber] = 1;	// open the gate and send a synch pulse to the LED driver

		// Now set up gated synch.
		// Polarity (and optionally OutputEnable) will work immediately,
		// because ALP is currently idle. Else it would
		// become effective after the next AlpProjHalt or AlpProjStart.
		VERIFY_ALP( AlpDevControlEx( AlpDevId, ALP_DEV_DYN_SYNCH_OUT1_GATE+nLedBusNumbers[nLedIndex], &AlpSynchGate ) );
		// The control types for SYNCH_OUT1, 2, and 3 are direct successors of each other.
		// This allows the simplification above "ALP_DEV_DYN_SYNCH_OUT1_GATE + BusNumber."
		// Let the compiler check that this assumption is met:
		_ASSERT( ALP_DEV_DYN_SYNCH_OUT2_GATE == ALP_DEV_DYN_SYNCH_OUT1_GATE+1 );
		_ASSERT( ALP_DEV_DYN_SYNCH_OUT3_GATE == ALP_DEV_DYN_SYNCH_OUT1_GATE+2 );
	}

	// Start continuous display
	VERIFY_ALP( AlpProjStartCont( AlpDevId, AlpSeqId ) );

// LED Monitoring Stuff ///////////////////////////////////////////////////////
	// Monitor LED current and temperature (run until a key has been hit, or until "break;")
	_tprintf( _T("\r\nPress a key to stop projection.\r\n") );
	CConsolePosition const CursorPosition;	// store cursor position
	bool bEmergencyStop = false;
	while (0 == _kbhit() && !bEmergencyStop) {
		// The current cycles through different LEDs, controlled by gated synch.
		// In order to measured this, we need some oversampling (this wait time < PictureTime, see AlpSeqTiming above)
		Sleep( 50 );	// wait 50 ms

		CursorPosition.Restore();		
		for (long nLedIndex=0; nLedIndex<nLedCount; nLedIndex++) {
			long nLedCurrent_mA(0), nLedJunctionTemp(0), nLedRefTemp(0);
			_ASSERT( ALP_INVALID_ID != AlpLedId[nLedIndex] );

			// Inquire measurements:
			VERIFY_ALP_NO_ECHO( AlpLedInquire( AlpDevId, AlpLedId[nLedIndex], ALP_LED_MEASURED_CURRENT, &nLedCurrent_mA ) );
			VERIFY_ALP_NO_ECHO( AlpLedInquire( AlpDevId, AlpLedId[nLedIndex], ALP_LED_TEMPERATURE_JUNCTION, &nLedJunctionTemp ) );
			VERIFY_ALP_NO_ECHO( AlpLedInquire( AlpDevId, AlpLedId[nLedIndex], ALP_LED_TEMPERATURE_REF, &nLedRefTemp ) );

			// Report values.
			// Current unit: mA, temperature unit: 1°C/256
			_tprintf( _T("Note: Actual LED#%i current=%4.1f A; T_junction=%5.1f °C, T_ref=%5.1f °C\r\n"),
				nLedBusNumbers[nLedIndex], (double)nLedCurrent_mA/1000,
				(double)nLedJunctionTemp/256, (double)nLedRefTemp/256 );

			// If the temperature sensor is disconnected from the HLD, then
			// very low temperatures (below -200°C or so) are measured
			// The "Single-Color" ALP LED API sample outputs a warning message in this case.

			// Switch off at 100°C (generally, LEDs can stand much
			// higher temperatures, but this differs between LED types)
			if (nLedJunctionTemp>100*256) {
				_tprintf( _T("Warning: LED becomes quite hot. Stopping.\r\n") );
				bEmergencyStop = true;
			}
		}
	}
	_tprintf( _T("\r\n\r\n") );	// blank line

	// Clean up
	VERIFY_ALP( AlpDevHalt(AlpDevId) );
	VERIFY_ALP( AlpDevFree(AlpDevId) );	// this also switches the LEDs off
	_tprintf( _T("Finished.\r\n") );
	Pause();
	return 0;
}

