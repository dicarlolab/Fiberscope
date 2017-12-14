#include "AlpFrames.h"
#include <crtdbg.h>
#include <memory.h>

// For ceil and floor
#include <stdio.h>
#include <math.h>

#define SingleColor false // Set for entire sheet to be red to test brightness intensity

// Variables
static int cnt = 0;
int SeqLen = 110;
//int Seq[4][110] = // Pattern in paper
//{{1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0},
// {1,0,1,0,0,1,1,0,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0},
// {1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0},
// {1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,1,1,0,1}};
int Seq[4][110] = // Simple alternating
{{1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0},
 {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0},
 {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0},
 {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0}};
int SpacingV = 20; // For vertical stripes (x dir)
int SpacingH = 20; // For horizontal stripes (y dir)


CAlpFrames::CAlpFrames(const long nFrameCount, const long nWidth, const long nHeight) :
	// initialize constant members
	m_nFrameCount(nFrameCount), m_nWidth(nWidth), m_nHeight(nHeight),
	m_pImageData(new char unsigned[nFrameCount*nWidth*nHeight])
{
	_ASSERT (nFrameCount>0 && nWidth>0 && nHeight>0);
	_ASSERT (m_pImageData!=NULL);
	// Initialize image data as solid black
	memset(m_pImageData, 0, nFrameCount*nWidth*nHeight);
}

CAlpFrames::~CAlpFrames(void)
{
	delete[] m_pImageData;
}

CAlpFramesMovingSquare::CAlpFramesMovingSquare(const long nFrameCount, const long nWidth, const long nHeight) :
	CAlpFrames(nFrameCount, nWidth, nHeight)
{
	for (long nFrame=0; nFrame<nFrameCount; nFrame++) 
	{
		if(SingleColor) // for calibrating brightness
		{
			FillRect(nFrame,0,0,nWidth-1,nHeight-1,255);
		}
		else
		{
			if(nFrame%2 == 0) // Even (Horizontal)
			{
				int NumH = (int)ceil(nHeight*1.0/SpacingH); // 1.0 so force ceil float
				for(int i=0; i<NumH-1; i++)
				{
					int j = i;
					while(j >= SeqLen) { j -= SeqLen; } // Account for more stripes than SeqLen
					if(Seq[nFrame/2][j] == 1) // only color 1's in Seq
					{
						FillRect(nFrame,0,i*SpacingH,nWidth-1,SpacingH,255);
					}
				}
					int j = NumH-1;
					while(j >= SeqLen) { j -= SeqLen; }
					if(Seq[nFrame/2][j] == 1) // For last stripe careful with index
					{
						FillRect(nFrame,0,(NumH-1)*SpacingH,nWidth-1,nHeight-1-(NumH-1)*SpacingH,255);
					}
			}
			else // Odd (Vertical)
			{
				int NumV = (int)ceil(nWidth*1.0/SpacingV); // 1.0 so force ceil float
				for(int i=0; i<NumV-1; i++)
				{
					int j = i;
					while(j >= SeqLen) { j -= SeqLen; } // Account for more stripes than SeqLen
					if(Seq[(nFrame-1)/2][j] == 1) // only color 1's in Seq
					{
						FillRect(nFrame,i*SpacingV,0,SpacingV,nHeight-1,255);
					}
				}
					int j = NumV-1;
					while(j >= SeqLen) { j -= SeqLen; }
					if(Seq[nFrame/2][j] == 1) // For last stripe careful with index
					{
						FillRect(nFrame,(NumV-1)*SpacingV,0,nWidth-1-(NumV-1)*SpacingV,nHeight-1,255);
					}
			}
		}
	}
}


char unsigned* CAlpFrames::operator()(const long nFrameNumber)
{
	_ASSERT (nFrameNumber>=0 && nFrameNumber<m_nFrameCount);
	return m_pImageData+nFrameNumber*m_nWidth*m_nHeight;
}

char unsigned& CAlpFrames::at(const long nFrameNumber, const long nX, const long nY)
{
	_ASSERT (nFrameNumber>=0 && nFrameNumber<m_nFrameCount
		&& nX>=0 && nX<m_nWidth
		&& nY>=0 && nY<m_nHeight);

	return m_pImageData
		[nFrameNumber*m_nWidth*m_nHeight
		+nY*m_nWidth
		+nX];
}

void CAlpFrames::FillRect(const long nFrameNumber,
	const long nLeft, const long nTop,
	const long nRectWidth, const long nRectHeight,
	const char unsigned PixelValue)
{
	long const nBottom=nTop+nRectHeight-1;
	_ASSERT (nFrameNumber>=0 && nFrameNumber<m_nFrameCount);
	_ASSERT( 0<=nLeft && 0<nRectWidth && nLeft+nRectWidth<=m_nWidth );
	_ASSERT( 0<=nTop && nTop<=nBottom && nBottom<m_nHeight );
	// row by row: set the area starting from nLeft to PixelValue
	for (long nY=nTop; nY<=nBottom; nY++)
		memset(&at(nFrameNumber, nLeft, nY), PixelValue, nRectWidth);
}

