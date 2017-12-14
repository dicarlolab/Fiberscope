// ScrollingSample - Microsoft Win32 Console Application
//
// This is a part of the ALP application programming interface
// scrolling extension.
//
//	This sample is provided as-is, without any warranty.
//
//	Please always consult the ALP-4 high-speed API description when
//	customizing this program. It contains a detailled specification
//	of all Alp... functions.
//
// © 2008-2009 ViALUX GmbH. All rights reserved.
//
// Please see ReadMe.txt for details.

#include <windows.h>
#include <math.h>
#include <stdio.h>
#include "alp.h"

int main( int /*argc*/, char ** /*argv*/ ) {

	/////////////////////////////////////////////
	// Set up test parameters

	// nFrames
	//		This number of frames is generated, transmitted, and
	//		displayed in this scrolling example.
	//		The image data represents two alternating frames:
	//		- 1st, 3rd, 5th... frame: shaded arrow
	//		- 2nd, 4th, 6th... frame: shaded circle
	const long nFrames = 4;	// number of frames in this sample

	//	SerialNumber
	//		use the specified ALP, 0=next free device
	long nSerial = 0;

	//	LINE_INC, FIRSTFRAME, FIRSTLINE, LASTFRAME, LASTLINE
	//		use this parameter set for scrolling
	//		Frame numbers are limited to 0..nFrames-1 (see nFrames above)
	long nLineInc = 2,
		nFirstFrame = 0, nFirstLine = 0,
		nLastFrame = nFrames-1, nLastLine = 0;

	//	ALP_BITNUM and ALP_PICTURE_TIME
	//		use this gray value depth (0 for binary uninterrupted)
	//		and picture time (µs)
	long nBitNum = 8, nPicTime = 10000;

	//	ALP_SEQ_REPEAT
	//		display the sequence n times, 0 for infinite until user interrupt
	long nRepeat = 0;

	/////////////////////////////////////////////
	// Initialize ALP
	ALP_ID nAlpId;
	long nDmdFormat;
	printf( "Initialize ALP..." );
	if (ALP_OK != AlpDevAlloc( nSerial, ALP_DEFAULT, &nAlpId ) ||
		ALP_OK != AlpDevInquire( nAlpId, ALP_DEV_DMDTYPE, &nDmdFormat ))
	{
		printf( "error.\r\n" );
		return 1;
	} else
		printf( "success.\r\n" );


	/////////////////////////////////////////////
	// Initialize sequence of 2 frames, 8 bits
	ALP_ID nSeqId;
	printf( "Initialize sequence and set up timing..." );
	if (ALP_OK != AlpSeqAlloc( nAlpId, 8, nFrames, &nSeqId ))
	{
		printf( "error (AlpSeqAlloc).\r\n" );
		return 1;
	}
	if (// set ALP_BITNUM
		ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_BITNUM, 0==nBitNum?1:nBitNum ) ||
		// maybe set binary uninterrupted mode
		0==nBitNum &&
		ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_BIN_MODE, ALP_BIN_UNINTERRUPTED ) ||
		// set up timing, also activating the ALP_BITNUM and ALP_BIN_MODE setting
		ALP_OK != AlpSeqTiming( nAlpId, nSeqId, ALP_DEFAULT, nPicTime, ALP_DEFAULT, ALP_DEFAULT, ALP_DEFAULT )
		)
	{
		printf( "error (timing settings).\r\n" );
		return 1;
	}
	if (// set ALP_SEQ_REPEAT
		nRepeat>0 &&
		ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_SEQ_REPEAT, nRepeat ))
	{
		printf( "error (ALP_SEQ_REPEAT).\r\n" );
		return 1;
	} else
		printf( "success.\r\n" );

	/////////////////////////////////////////////
	// Check if scrolling is available, set up scrolling parameters
	if (ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_LINE_INC, 0 ))
	{
		printf( "Scrolling is not available in this alpD40.DLL version!\r\n" );
		return 1;
	}
	printf( "Set up scrolling parameters..." );
	if (ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_FIRSTFRAME, nFirstFrame ) ||
		ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_LASTFRAME, nLastFrame ) )
	{
		printf( "error (frame numbers).\r\n" );
		return 1;
	}
	if (ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_LINE_INC, nLineInc ) ||
		ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_FIRSTLINE, nFirstLine ) ||
		ALP_OK != AlpSeqControl( nAlpId, nSeqId, ALP_LASTLINE, nLastLine)
		)
	{
		printf( "error (scrolling settings).\r\n" );
		return 1;
	} else
		printf( "success.\r\n" );


	/////////////////////////////////////////////
	// Prepare and transmit image data: nFrames Images
	long nSizeX, nSizeY;
	UCHAR *pImages = NULL;

	switch (nDmdFormat) {
	case ALP_DMDTYPE_XGA_055X :
	case ALP_DMDTYPE_XGA_055A :
	case ALP_DMDTYPE_XGA_07A :
		nSizeX = 1024; nSizeY = 768;
		printf( "DMD format: XGA\r\n" );
		break;
	case ALP_DMDTYPE_DISCONNECT :
		nSizeX = 1920; nSizeY = 1080;
		printf( "DMD format: disconnected; emulate 1080P\r\n" );
		break;
	case ALP_DMDTYPE_1080P_095A :
		nSizeX = 1920; nSizeY = 1080;
		printf( "DMD format: 1080P\r\n" );
		break;
	case ALP_DMDTYPE_WUXGA_096A :
		nSizeX = 1920; nSizeY = 1200;
		printf( "DMD format: WUXGA\r\n" );
		break;
	default:
		printf( "Unsupported DMD format.\r\n" );
		return 1;
	}

	pImages = new UCHAR[nSizeX*nSizeY*nFrames];
	if (NULL == pImages) return 1;

	long nCurrent = 0, nX, nY;
	UCHAR nGray;

	// First frame (and all odd frames): shaded arrow (up direction)
	for (nY=0; nY<nSizeY; nY++) {	// loop through all lines of image data
		nGray = (UCHAR) (256*(nSizeY-1-nY)/nSizeY);
		for (nX=0; nX<nSizeX; nX++){// loop through all columns of image data

			// set pixel gray value depending on position (nX,nY)
			pImages[ (nCurrent*nSizeY+nY)*nSizeX + nX] =
				(nSizeX/2>nX+nY || nSizeX/2+nY<nX)
				? (UCHAR) 0			// nX (horizontal position) outside arrow shape
				: nGray;	// nX is inside arrow
		}
	}

	if (++nCurrent < nFrames)
	{
		// Second frame (and all even frames): a shaded circle
		long nRadius = nSizeY/2,
			nCenterX = nSizeX/2,
			nCenterY = nSizeY/2;
		long nSqrDistance;	// square distance (in pixels²) from center
		long nSqrRadius = nRadius*nRadius;
							// square radius (in pixels²) of the circle

		for (nY=0; nY<nSizeY; nY++) {
			for (nX=0; nX<nSizeX; nX++){
				nSqrDistance = (nCenterX-nX)*(nCenterX-nX) + (nCenterY-nY)*(nCenterY-nY);
				// set pixel gray value depending on position (nX,nY)
				if (nSqrDistance>nSqrRadius)
					pImages[ (nCurrent*nSizeY+nY)*nSizeX + nX] = 0;
				else {
					pImages[ (nCurrent*nSizeY+nY)*nSizeX + nX] =
						(UCHAR) (256*sqrt( (double) nSqrDistance )/(nRadius+1));
				}
			}
		}
	}
	while (++nCurrent < nFrames) {
		// odd image: copy from first one
		CopyMemory( pImages+nCurrent*nSizeY*nSizeX,
			pImages,
			nSizeY*nSizeX );
		if (++nCurrent == nFrames) break;

		// even image: copy from first one
		CopyMemory( pImages+nCurrent*nSizeY*nSizeX,
			pImages+nSizeY*nSizeX,
			nSizeY*nSizeX );
	}

	printf( "Transmit image data to ALP..." );
	if (ALP_OK != AlpSeqPut( nAlpId, nSeqId, ALP_DEFAULT, ALP_DEFAULT, pImages )) {
		printf( "error.\r\n" );
		return 1;
	} else
		printf( "success.\r\n" );

	delete[] pImages; pImages = NULL;

	/////////////////////////////////////////////
	// Run projection
	if (0 != nRepeat) {
		printf( "Start projection (%i times)...", nRepeat );
		if (ALP_OK != AlpProjStart( nAlpId, nSeqId ))
		{
			printf( "error (AlpProjStart).\r\n" );
			return 1;
		} else
			printf( "...started." );
		AlpProjWait( nAlpId );
		printf( "...finished.\r\n" );
	} else {
		printf( "Start projection (infinite times)..." );
		if (ALP_OK != AlpProjStartCont( nAlpId, nSeqId ))
		{
			printf( "error (AlpProjStartCont).\r\n" );
			return 1;
		} else
			printf( "...started.\r\n" );
	}

	/////////////////////////////////////////////
	// Clean
	printf( "Press return to fininsh.\r\n" );
#pragma warning( push )
#pragma warning( disable : 4996 )
	scanf( "x" );
#pragma warning( pop )
	AlpDevHalt( nAlpId );
	AlpSeqFree( nAlpId, nSeqId );
	AlpDevFree( nAlpId );

	return 0;
}
