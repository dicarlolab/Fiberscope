#pragma once

// class CAlpFrames:
// - manage storage of Image Data for one or more DMD frames.
// - provide some basic methods for accessing these data (at, (), FillRect)
// - Error handling: To keep things simple in this sample,
//	 parameter validation uses only debug checks (_ASSERT macro)
// class CAlpFramesMovingSquare:
// - specialization of CAlpFrames (just to remove its code from the main function)
// - initializes image data with a bright square moving diagonally over the DMD

class CAlpFrames
{
	CAlpFrames const & operator=(CAlpFrames const & rhs); // hidden, not required
public:
	CAlpFrames(const long nFrameCount, const long nWidth, const long nHeight);
	~CAlpFrames(void);

	// This conversion operator returns a pointer to the image data of a frame.
	// nFrameNumber, nX, nY are zero-based indexes.
	char unsigned *operator()(const long nFrameNumber);
	// access a single pixel
	char unsigned &at(const long nFrameNumber, const long nX, const long nY);
	
	// Drawing routine
	void FillRect(const long nFrameNumber,
		const long nLeft, const long nTop,
		const long nWidth, const long nHeight,
		const char unsigned PixelValue);

	// These members contain parameters, supplied during construction.
	const long m_nFrameCount, m_nWidth, m_nHeight;

private:
	// pointer to the data
	char unsigned *const m_pImageData;
};

class CAlpFramesMovingSquare : public CAlpFrames
{
public:
	CAlpFramesMovingSquare(const long nFrameCount, const long nWidth, const long nHeight);
};
