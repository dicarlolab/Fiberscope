/*
	This sample is provided as-is, without any warranty.

	Please always consult the ALP-4 high-speed API description when
	customizing this program. It contains a detailled specification
	of all Alp... functions.

	(c) 2007 ViALUX GmbH. All rights reserved.
*/

// BlackWhiteSample.cpp : Defines the entry point for the console application.
//

#include <TCHAR.h>
#include <windows.h>
#include <conio.h>
#include <stdio.h>
#include "alp.h"

int _tmain(int /*argc*/, _TCHAR** /* *argv[]*/)
{
	ALP_ID nDevId, nSeqId;
	long nDmdType, nSizeX, nSizeY;
	long nReturn;
	const long nPictureTime = 20000;	// 20 ms, i.e. 50 Hz frame rate
	UCHAR *pImageData = NULL;

	// Allocate the ALP high-speed device
	if (ALP_OK != AlpDevAlloc( ALP_DEFAULT, ALP_DEFAULT, &nDevId )) return 1;

	// Inquire DMD type
	if (ALP_OK != AlpDevInquire( nDevId, ALP_DEV_DMDTYPE, &nDmdType )) return 1;
	switch (nDmdType) {
	case ALP_DMDTYPE_XGA_055A :
	case ALP_DMDTYPE_XGA_055X :
	case ALP_DMDTYPE_XGA_07A :
		nSizeX = 1024; nSizeY = 768;
		break;
	case ALP_DMDTYPE_DISCONNECT :
	case ALP_DMDTYPE_1080P_095A :
		nSizeX = 1920; nSizeY = 1080;
		break;
	case ALP_DMDTYPE_WUXGA_096A :
		nSizeX = 1920; nSizeY = 1200;
		break;
	default:
		// unsupported DMD type
		return 1;
	}

	// Allocate a sequence of two binary frames
	if (ALP_OK != AlpSeqAlloc( nDevId, 1, 2, &nSeqId )) return 1;

	// Create images
	pImageData = (UCHAR*) malloc( 2*nSizeX*nSizeY );
	if (NULL == pImageData) return 1;
	FillMemory( pImageData, nSizeX*nSizeY, 0x80 );				// white
	FillMemory( pImageData+nSizeX*nSizeY, nSizeX*nSizeY, 0x00 );		// black

	// Transmit images into ALP memory
	nReturn = AlpSeqPut( nDevId, nSeqId, 0, 2, pImageData );
	free( pImageData );
	if (ALP_OK != nReturn) return 1;

	// Set up image timing
	// For highest frame rate, first switch to binary uninterrupted
	// mode (ALP_BIN_UNINTERRUPTED) by using AlpDevControl.
	if (ALP_OK != AlpSeqTiming( nDevId, nSeqId, ALP_DEFAULT, nPictureTime,
		ALP_DEFAULT, ALP_DEFAULT, ALP_DEFAULT ) ) return 1;

	// Start sequence
	if (ALP_OK != AlpProjStartCont( nDevId, nSeqId )) return 1;

	// Wait for key stroke
	_tprintf( _T("Press any key to stop ALP projection") );
	do { _getch(); } while (_kbhit()) ;
	

	// Done
	AlpDevHalt( nDevId );
	AlpDevFree( nDevId );

	return 0;
}

