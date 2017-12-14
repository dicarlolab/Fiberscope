//
// Projector.h
//
#pragma once

// include header for ViALUX ALP
#include "../inc/alp.h"

// possible modifications:
// /D USE_TRIGGER_DELAY (applicable only in ALP_SLAVE_MODE)

class CProjector
{
public:
	// ALP synch properties
	struct CSynchProperties
	{
		long	Polarity;		// active level out: ALP_LEVEL_HIGH, ALP_LEVEL_LOW
		long	TriggerInEdge;			// active edge in: ALP_EDGE_FALLING, ALP_EDGE_RISING

		CSynchProperties()
		{	// Construction: default values
			Polarity = ALP_LEVEL_HIGH;		// default: ALP_LEVEL_HIGH
			TriggerInEdge   = ALP_EDGE_FALLING;	// default: ALP_EDGE_FALLING
		}

		CSynchProperties(long OutputPolarity, long InputEdge)
		{
			Polarity = OutputPolarity;
			TriggerInEdge   = InputEdge;
		}
	};


	// ALP device properties and state
	struct CDevProperties : public CSynchProperties
	{
		long	SerialNumber;		// serial number of the ALP (im EEPROM)
		long	FreeMemory;			// available memory for sequences (number of pictures)

		CDevProperties()
		{	// Initialization
			SerialNumber = 0x00;
			FreeMemory   = 0;
		}
	};

	// ALP timing properties
	struct CTimingEx
	{
		long	IlluminateTime;		// [탎] time while an image is visible
		long	PictureTime;		// [탎] period time between the starts of two following pictures: 
									//      PictureTime = IlluminateTime + DarkTime
		long	SynchDelay;		// [탎] delay between synch output and appearance of the image (master mode)
		long	SynchPulseWidth;	// [탎] pulse with of the synch signal
#ifdef USE_TRIGGER_DELAY
		long	TriggerInDelay;			// [탎] delay between synch input (trigger) and appearance of the image (slave mode)
#endif
		long	BitNum;				// [Bit Planes] Gray Scale Resolution
		bool	Uninterrupted;		// requires BitNum==1

		CTimingEx()
		{	// Initialization
			IlluminateTime	= ALP_DEFAULT;
			PictureTime		= ALP_DEFAULT;
			SynchDelay	= 0;
			SynchPulseWidth = 0;
#ifdef USE_TRIGGER_DELAY
			TriggerInDelay			= 0;
#endif
			BitNum = 0;
			Uninterrupted = false;
		};

		CTimingEx(long Illuminate, long Picture, long OutDelay=0, long PulseWidth=0, long InDelay=0, long BitNum=0, bool Uninterrupted=false)
		{	// avoid negative values
			IlluminateTime	= __max(0L, Illuminate);
			PictureTime		= __max(0L, Picture);
			SynchDelay	= __max(0L, OutDelay);
			SynchPulseWidth = __max(0L, PulseWidth);
#ifdef USE_TRIGGER_DELAY
			TriggerInDelay			= __max(0L, InDelay);
#else
			_ASSERT( 0==InDelay ); UNREFERENCED_PARAMETER(InDelay);
#endif
			this->BitNum = BitNum;
			this->Uninterrupted = Uninterrupted;
		}

		// Compare
		BOOL operator == (const CTimingEx &Timing) const
		{
			if (IlluminateTime    != Timing.IlluminateTime) return FALSE;
			if (PictureTime       != Timing.PictureTime) return FALSE;
			if (SynchDelay      != Timing.SynchDelay) return FALSE;
			if (SynchPulseWidth != Timing.SynchPulseWidth) return FALSE;
#ifdef USE_TRIGGER_DELAY
			if (TriggerInDelay           != Timing.TriggerInDelay) return FALSE;
#endif
			if (BitNum != Timing.BitNum) return FALSE;
			if (Uninterrupted != Timing.Uninterrupted) return FALSE;
			return TRUE;
		}
		BOOL operator != (const CTimingEx &Timing) const
		{
			return !(*this == Timing);
		}
	};

	// Led device
	class CLed {
		ALP_ID &m_AlpDevice, m_LedId;
	public:
		CLed(ALP_ID &AlpDevice);
		int Alloc (long AlpLedType, int nI2cIndex);
		int Free ();
		bool IsValid();
		int SetBrightness (int nPercent);
		long GetMeasuredCurrent();
	};

	enum
	{
		LEDTYPE_0_NONE = 0,
		LEDTYPE_1_RED = ALP_HLD_PT120_RED,
		LEDTYPE_2_GREEN = ALP_HLD_PT120_GREEN,
		LEDTYPE_3_BLUE_TE = ALP_HLD_PT120TE_BLUE,
		LEDTYPE_4_UV = ALP_HLD_CBT90_UV,
		LEDTYPE_5_CBT_140_WHITE = ALP_HLD_CBT140_WHITE,
	} LedTypeID;

	int GetLedTypeByIndex( const int iLedIndex)
	{
		if( 0 > iLedIndex || 5 < iLedIndex)
			return LEDTYPE_0_NONE;

		switch( iLedIndex)
		{
		case 0: return LEDTYPE_0_NONE;
		case 1: return LEDTYPE_1_RED;
		case 2: return LEDTYPE_2_GREEN;
		case 3: return LEDTYPE_3_BLUE_TE;
		case 4: return LEDTYPE_4_UV;
		case 5: return LEDTYPE_5_CBT_140_WHITE;

		default: return LEDTYPE_0_NONE;
		}
	}


public:
	CProjector(void);
	~CProjector(void);
	// get the textmessage for a certain error code
	void GetErrorMessage(const int errorCode, wchar_t *errorText, const int nChars) const;
	// allocate and initialize the projector
	int Alloc(void);
	// free the projector
	int Free(void);
	// true, if the projector was successfully initialized
	bool IsConnected(void) const;
	// get the properties of the projector
	int GetDevProperties(CDevProperties &properties) const;
	// change the synch settings
	int SetSyncOutputMode(const long mode);
	// -----
	// allocate and initialize a sequence
	int SequenceAlloc(const int Bitplanes, const int nPictures);
	// free a sequence
	int SequenceFree(void);
	// true, if the sequence was successfully initialized
	bool IsValidSequence(void) const;
	// get the properties of the sequence
	int GetSeqProperties(CTimingEx &timing) const;
	// change the properties of the sequence
	int SetSeqProperties(const CTimingEx &timing);
	// change number of bit planes. Get the possible max timing
	int GetSeqFastestTiming( const long BitNum, const bool Uninterrupted, long &MinPicTime, long &MinIllTime );
	// select maximum possible gray scale (ALP_BITNUM) for a given frame timing
	int SelectMaxBitnum( IN OUT CTimingEx &timing );	// subsequent SetSeqProperties() not required
	// add an image to the sequence
	int AddImage(BYTE *pImageData, const int width, const int height);
	// start the continously projection of the sequence
	int ProjStartContinuous(void);
	// Is the projection running!
	bool IsProjection(void) const;
	// stop the projection
	int ProjStop(void);
	// [pixels] get dimensions of the DMD
	const int GetWidth() const			{ return m_width; }
	const int GetHeight() const			{ return m_height; }

	/* LED-Index and Gate-Index: 1..x */
	CLed &Led(int nIndex);
	// set the gate for LED control
	int SetSynchGate( long nGateIndex, tAlpDynSynchOutGate &GateConfig );
	// test the existence of a LED
	bool TestLedExistence();

private:
	void SetWidth(  const int width)	{ m_width = width;}
	void SetHeight( const int height)	{ m_height = height;}

private:
	// device ID
	unsigned long m_DeviceID;
	// sequence ID
	unsigned long m_SequenceID;
	// image index
	unsigned long m_ImageIdx;
	// dimensions ot the DMD
	int	m_width;
	int m_height;

	// first LED object
	CLed m_Led1;
};

