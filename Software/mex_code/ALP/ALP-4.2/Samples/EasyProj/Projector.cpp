//
// Projector.cpp
//

#include "StdAfx.h"
#include "Projector.h"

// error codes of CProjector
const int PROJECTOR_ERROR									= 5001;
const int PROJECTOR_NOT_CONNECTED							= 5002;
const int PROJECTOR_ERROR_SEQ_NOT_VALID						= 5003;
const int PROJECTOR_ERROR_ALREADY_ALLOCATED					= 5010;
const int PROJECTOR_ERROR_SEQ_IMG_SIZE						= 5015;
// text messages for the error codes of CProjector
const wchar_t* MSG_PROJECTOR_ERROR							= L"ERROR";
const wchar_t* MSG_PROJECTOR_NOT_CONNECTED					= L"The projector is not connected.";
const wchar_t* MSG_PROJECTOR_ERROR_SEQ_NOT_VALID			= L"The sequence is not valid.";
const wchar_t* MSG_PROJECTOR_ERROR_ALREADY_ALLOCATED		= L"The object is already allocated.";
const wchar_t* MSG_PROJECTOR_ERROR_SEQ_IMG_SIZE				= L"Sequence image has wrong size.";

// text messages for the error codes of the ALP api
const wchar_t* MSG_OK										= L"Ok";
const wchar_t* NO_ERROR_MSG_AVAILABLE						= L"No Error message available for this error code.";
const wchar_t* ERROR_MSG_GENERAL							= L"ERROR";
const wchar_t* ERROR_MSG_ALP_NOT_ONLINE						= L"The specified ALP has not been found or is not ready.";
const wchar_t* ERROR_MSG_ALP_NOT_IDLE						= L"The ALP is not in idle state.";
const wchar_t* ERROR_MSG_ALP_NOT_AVAILABLE					= L"The specified ALP identifier is not valid.";
const wchar_t* ERROR_MSG_ALP_NOT_READY						= L"The specified ALP is already allocated.";
const wchar_t* ERROR_MSG_ALP_PARM_INVALID					= L"One of the parameters is invalid.";
const wchar_t* ERROR_MSG_ALP_ADDR_INVALID					= L"Error accessing user data.";
const wchar_t* ERROR_MSG_ALP_MEMORY_FULL					= L"The requested memory is not available.";
const wchar_t* ERROR_MSG_ALP_SEQ_IN_USE						= L"The sequence specified is currently in use.";
const wchar_t* ERROR_MSG_ALP_HALTED							= L"The ALP has been stopped while image data transfer was active.";
const wchar_t* ERROR_MSG_ALP_ERROR_INIT						= L"Initialization error.";
const wchar_t* ERROR_MSG_ALP_ERROR_COMM						= L"Communication error.";
const wchar_t* ERROR_MSG_ALP_DEVICE_REMOVED					= L"The specified ALP has been removed.";
const wchar_t* ERROR_MSG_ALP_NOT_CONFIGURED					= L"The onboard FPGA is unconfigured.";
const wchar_t* ERROR_MSG_ALP_LOADER_VERSION					= L"The function is not supported by this version of the driver file VlxUsbLd.sys.";
const wchar_t* ERROR_MSG_ALP_ERROR_POWER_DOWN				= L"Waking up the DMD from PWR_FLOAT did not work (ALP_DMD_POWER_FLOAT.";



CProjector::CProjector(void)
	: m_DeviceID(ALP_INVALID_ID)
	, m_SequenceID(0)
	, m_ImageIdx(0)
	, m_width(0)
	, m_height(0)
	, m_Led1(m_DeviceID)
{
}


CProjector::~CProjector(void)
{
}


// get the textmessage for a certain error code
void CProjector::GetErrorMessage(const int errorCode, wchar_t *errorText, const int nChars) const
{
	if(nChars <= 0)												return;
	if(errorText == nullptr )									return;
	if(::IsBadWritePtr(errorText, nChars*sizeof(*errorText)))	return;

	const wchar_t* pErrMsg = ERROR_MSG_GENERAL;
	switch( errorCode)
	{
	case ALP_OK:				pErrMsg = MSG_OK; break;
	case ALP_NOT_ONLINE:		pErrMsg = ERROR_MSG_ALP_NOT_ONLINE; break;
	case ALP_NOT_IDLE:			pErrMsg = ERROR_MSG_ALP_NOT_IDLE; break;
	case ALP_NOT_AVAILABLE:		pErrMsg = ERROR_MSG_ALP_NOT_AVAILABLE; break;
	case ALP_NOT_READY:			pErrMsg = ERROR_MSG_ALP_NOT_READY; break;
	case ALP_PARM_INVALID:		pErrMsg = ERROR_MSG_ALP_PARM_INVALID; break;
	case ALP_ADDR_INVALID:		pErrMsg = ERROR_MSG_ALP_ADDR_INVALID; break;
	case ALP_MEMORY_FULL:		pErrMsg = ERROR_MSG_ALP_MEMORY_FULL; break;
	case ALP_SEQ_IN_USE:		pErrMsg = ERROR_MSG_ALP_SEQ_IN_USE; break;
	case ALP_HALTED:			pErrMsg = ERROR_MSG_ALP_HALTED; break;
	case ALP_ERROR_INIT:		pErrMsg = ERROR_MSG_ALP_ERROR_INIT; break;
	case ALP_ERROR_COMM:		pErrMsg = ERROR_MSG_ALP_ERROR_COMM; break;
	case ALP_DEVICE_REMOVED:	pErrMsg = ERROR_MSG_ALP_DEVICE_REMOVED; break;
	case ALP_NOT_CONFIGURED:	pErrMsg = ERROR_MSG_ALP_NOT_CONFIGURED; break;
	case ALP_LOADER_VERSION:	pErrMsg = ERROR_MSG_ALP_LOADER_VERSION; break;
	case ALP_ERROR_POWER_DOWN:	pErrMsg = ERROR_MSG_ALP_ERROR_POWER_DOWN; break;

	case PROJECTOR_ERROR:							pErrMsg = MSG_PROJECTOR_ERROR; break;
	case PROJECTOR_NOT_CONNECTED:					pErrMsg = MSG_PROJECTOR_NOT_CONNECTED; break;
	case PROJECTOR_ERROR_SEQ_NOT_VALID:				pErrMsg = MSG_PROJECTOR_ERROR_SEQ_NOT_VALID; break;
	case PROJECTOR_ERROR_ALREADY_ALLOCATED:			pErrMsg = MSG_PROJECTOR_ERROR_ALREADY_ALLOCATED; break;
	case PROJECTOR_ERROR_SEQ_IMG_SIZE:				pErrMsg = MSG_PROJECTOR_ERROR_SEQ_IMG_SIZE; break;

	default:					pErrMsg = NO_ERROR_MSG_AVAILABLE; break;
	}

	wcscpy_s( errorText, nChars, pErrMsg);
}


// allocate and initialize the projector
int CProjector::Alloc(void)
{
	if (ALP_INVALID_ID != m_DeviceID)
		return PROJECTOR_ERROR_ALREADY_ALLOCATED;
	
	m_DeviceID = ALP_INVALID_ID;
	m_ImageIdx = 0;
	long lRet = AlpDevAlloc( 0, ALP_DEFAULT, &m_DeviceID);				// call the api function AlpDevAlloc()
	if( ALP_OK != lRet)
		m_DeviceID = ALP_INVALID_ID;
	else
	{
		// Get the dimensions of the DMD
		long lVal = 0;
		if( ALP_OK == AlpDevInquire( m_DeviceID, ALP_DEV_DISPLAY_WIDTH, &lVal))		// call the api function AlpDevInquire
			SetWidth( lVal);
		if( ALP_OK == AlpDevInquire( m_DeviceID, ALP_DEV_DISPLAY_HEIGHT, &lVal))	// call the api function AlpDevInquire
			SetHeight( lVal);
	}
	return lRet;
}


// free the projector
int CProjector::Free(void)
{
	long lRet = AlpDevFree( m_DeviceID);								// call the api function AlpDevFree()
	if( ALP_OK == lRet)
	{
		m_DeviceID = ALP_INVALID_ID;
		m_SequenceID = 0;
		m_ImageIdx = 0;
		m_width = 0;
		m_height = 0;
		m_Led1.Free();
	}
	return lRet;
}


// true, if the projector was successfully initialized
bool CProjector::IsConnected(void) const
{
	return m_DeviceID != ALP_INVALID_ID;
}


// get the properties of the projector
int CProjector::GetDevProperties(CDevProperties &properties) const
{
	long lRet = ALP_OK;

	// Define a macro GET_DEV_PROP, which calls the api function AlpDevInquire().
#define	GET_DEV_PROP(parm, val)	\
	lRet = AlpDevInquire( m_DeviceID, parm, val); \
	if( ALP_OK != lRet)	\
		return lRet;

	// Use the macro
	GET_DEV_PROP(ALP_DEVICE_NUMBER, &properties.SerialNumber);
	GET_DEV_PROP(ALP_AVAIL_MEMORY, &properties.FreeMemory);
	GET_DEV_PROP(ALP_SYNCH_POLARITY, &properties.Polarity);
	GET_DEV_PROP(ALP_TRIGGER_EDGE, &properties.TriggerInEdge);
#undef	GET_DEV_PROP

	return ALP_OK;
}


// change the synch settings
int CProjector::SetSyncOutputMode(const long mode)
{
	long lRet = AlpDevControl( m_DeviceID, ALP_SYNCH_POLARITY, mode);	// call the api function AlpDevControl()

	return lRet;
}


// allocate and initialize a sequence
int CProjector::SequenceAlloc(const int Bitplanes, const int nPictures)
{
	if( m_SequenceID != 0)
		return PROJECTOR_ERROR_ALREADY_ALLOCATED;

	long lRet = AlpSeqAlloc( m_DeviceID, Bitplanes, nPictures, &m_SequenceID);	// call the api function AlpSeqAlloc()
	if( ALP_OK != lRet)
		m_SequenceID = 0;
	return lRet;
}


// free a sequence
int CProjector::SequenceFree(void)
{
	long lRet =  AlpSeqFree( m_DeviceID, m_SequenceID);					// call the api function AlpSeqFree()
	if( ALP_OK == lRet)
	{
		m_SequenceID = 0;
		m_ImageIdx = 0;
	}
	return lRet;
}


// true, if the sequence was successfully initialized
bool CProjector::IsValidSequence(void) const
{
	return IsConnected() == true && m_SequenceID != 0;
}


// get the properties of the sequence
int CProjector::GetSeqProperties(CTimingEx &timing) const
{
	CTimingEx	t;
	long lRet = ALP_OK;
#define	GET_SEQ_TIMING(parm, val) \
	lRet = AlpSeqInquire( m_DeviceID, m_SequenceID, parm, val);	\
	if( ALP_OK != lRet) \
		return lRet;

	GET_SEQ_TIMING(ALP_ILLUMINATE_TIME, &t.IlluminateTime);
	GET_SEQ_TIMING(ALP_PICTURE_TIME, &t.PictureTime);
	GET_SEQ_TIMING(ALP_SYNCH_DELAY, &t.SynchDelay);
	GET_SEQ_TIMING(ALP_SYNCH_PULSEWIDTH, &t.SynchPulseWidth);
#ifdef USE_TRIGGER_DELAY
	GET_SEQ_TIMING(ALP_TRIGGER_IN_DELAY, &t.TriggerInDelay);
#endif
	GET_SEQ_TIMING(ALP_BITNUM, &t.BitNum);
	long BinMode;
	GET_SEQ_TIMING(ALP_BIN_MODE, &BinMode);
#undef GET_SEQ_TIMING

	if (ALP_BIN_UNINTERRUPTED==BinMode)
		t.Uninterrupted = true;
	else
		t.Uninterrupted = false;

	// Take the value even after all calls of the macro.
	timing = t;

	return ALP_OK;
}


// change the properties of the sequence
int CProjector::SetSeqProperties(const CTimingEx &timing)
{
	long lRet = ALP_OK;

	long minIll  = ALP_DEFAULT;
	long minPic  = ALP_DEFAULT;
	long minDark = 0;

	lRet = GetSeqFastestTiming( timing.BitNum, timing.Uninterrupted, minPic, minIll );
	if( ALP_OK != lRet)
		return lRet;
	
	minDark = minPic - minIll;

	long	SynchDelay		= timing.SynchDelay;
	long	SynchPulseWidth	= timing.SynchPulseWidth;
	long	TriggerInDelay = ALP_DEFAULT;
#ifdef USE_TRIGGER_DELAY
	TriggerInDelay = timing.TriggerInDelay;
#endif

	long	IlluminateTime = (timing.IlluminateTime < 1) ? 0 : (timing.IlluminateTime);
	long	PictureTime    = (timing.PictureTime < 1) ? (timing.IlluminateTime + minDark + SynchDelay) : (timing.PictureTime);

	lRet = AlpSeqTiming( m_DeviceID, m_SequenceID,						// call the api function AlpSeqTiming()
			IlluminateTime,
			PictureTime,
			SynchDelay,
			SynchPulseWidth,
			TriggerInDelay);

	return lRet;
}

// change number of bit planes. Get the possible max timing
int CProjector::GetSeqFastestTiming( const long BitNum, const bool Uninterrupted, long &MinPicTime, long &MinIllTime )
{
	long lRet = ALP_OK;

	lRet = AlpSeqControl( m_DeviceID, m_SequenceID, ALP_BITNUM, BitNum );	// call the api function AlpSeqControl
	if( ALP_OK != lRet) return lRet;
	lRet = AlpSeqControl( m_DeviceID, m_SequenceID, ALP_BIN_MODE, Uninterrupted?ALP_BIN_UNINTERRUPTED:ALP_BIN_NORMAL );
	if( ALP_OK != lRet) return lRet;

	lRet = AlpSeqInquire( m_DeviceID, m_SequenceID, ALP_MIN_PICTURE_TIME, &MinPicTime);	// call the api function AlpSeqInquire
	_ASSERT( ALP_OK == lRet);

	lRet = AlpSeqInquire( m_DeviceID, m_SequenceID, ALP_MIN_ILLUMINATE_TIME, &MinIllTime);	// call the api function AlpSeqInquire
	_ASSERT( ALP_OK == lRet);

	return ALP_OK;
}

// select maximum possible gray scale (ALP_BITNUM) for a given frame timing
int CProjector::SelectMaxBitnum( IN OUT CTimingEx &timing )
{
	long lRet = ALP_OK;

	// Try 8 downto 2 bit gray-scale display:
	AlpSeqControl( m_DeviceID, m_SequenceID, ALP_BIN_MODE, ALP_BIN_NORMAL );
	for (timing.BitNum=8; timing.BitNum>=2; timing.BitNum--) {
		// First select this ALP_BITNUM (AlpSeqControl), then test it (AlpSeqTiming)
		lRet = AlpSeqControl( m_DeviceID, m_SequenceID, ALP_BITNUM, timing.BitNum );
		if (ALP_OK != lRet) return lRet;

		// Please note: the ALP API automatically adjusts inconsistent parameters,
		// and PictureTime has precedence over IlluminateTime. The ALP API description contains detailed notes.
		lRet = AlpSeqTiming( m_DeviceID, m_SequenceID, timing.IlluminateTime, timing.PictureTime, timing.SynchDelay, timing.SynchPulseWidth,
#ifdef USE_TRIGGER_DELAY
			timing.TriggerInDelay
#else
			ALP_DEFAULT
#endif
			);
		if (ALP_OK==lRet) return ALP_OK;				// found first (highest) possible BITNUM
	}

	// Skip 1-bit ALP_BIN_NORMAL mode, because uninterrupted binary mode is faster (by avoiding dark phase between frames)

	// Try 1-bit uninterrupted display (fastest possible mode)
	timing.BitNum=1;
	timing.Uninterrupted = true;

	lRet = AlpSeqControl( m_DeviceID, m_SequenceID, ALP_BITNUM, 1 );
	if (ALP_OK != lRet) return lRet;
	lRet = AlpSeqControl( m_DeviceID, m_SequenceID, ALP_BIN_MODE, ALP_BIN_UNINTERRUPTED );
	if (ALP_OK != lRet) return lRet;

	lRet = AlpSeqTiming( m_DeviceID, m_SequenceID, timing.IlluminateTime, timing.PictureTime, timing.SynchDelay, ALP_DEFAULT, ALP_DEFAULT );
	if (ALP_OK==lRet) return ALP_OK;

	return lRet;	// error
}

// add an image to the sequence
int CProjector::AddImage(BYTE *pImageData, const int width, const int height)
{
	if( GetWidth() != width	||	GetHeight() != height)
		return PROJECTOR_ERROR_SEQ_IMG_SIZE;

	long lRet = AlpSeqPut( m_DeviceID, m_SequenceID, m_ImageIdx, 1, pImageData);	// call the api function AlpSeqPut()
	if( ALP_OK == lRet)
		m_ImageIdx ++;

	return lRet;
}


// start the continously projection of the sequence
int CProjector::ProjStartContinuous(void)
{
	int lRet = AlpProjStartCont(m_DeviceID, m_SequenceID);				// call the api function AlpProjStartCont()

	return lRet;
}


// Is the projection running!
bool CProjector::IsProjection(void) const
{
	if (!IsConnected()) return false;

	long state = 0;
	try
	{
		if( ALP_OK == AlpProjInquire(m_DeviceID, ALP_PROJ_STATE, &state)	// call the api function AlpProjInquire()
		&&	ALP_PROJ_ACTIVE == state)
			return true;
	}
	catch (...)
	{
	}
	return false;
}


// stop the projection
int CProjector::ProjStop(void)
{
	int lRet = AlpProjHalt(m_DeviceID);									// call the api function AlpProjHalt()
																		// Stop the running projection after the current sequence is finshed.
	if( ALP_OK == lRet)
		lRet = AlpDevHalt(m_DeviceID);									// call the api function AlpDevHalt()
																		// Stop the running projection immediately.
	return lRet;
}


// Create the LED device
CProjector::CLed &CProjector::Led(int nIndex)
{
	switch (nIndex)
	{
	default: throw;
	case 1: return m_Led1;
	}
}


// set the gate for LED control
int CProjector::SetSynchGate( long nGateIndex, tAlpDynSynchOutGate &GateConfig )
{
	return AlpDevControlEx( m_DeviceID, ALP_DEV_DYN_SYNCH_OUT1_GATE+nGateIndex-1, &GateConfig );	// call the api function AlpDevControlEx()
}
////////////////////////////////////////////////////////////////////////////////


// test the existence of a LED
bool CProjector::TestLedExistence()
{
	bool bLedWasAlreadyValid = m_Led1.IsValid();

	if( !bLedWasAlreadyValid)
		m_Led1.Alloc( ALP_HLD_PT120_RED, 0);


	m_Led1.SetBrightness( 10);
	Sleep( 100);

	bool bRet = false;
	if( 1000 < m_Led1.GetMeasuredCurrent())
		bRet = true;

	m_Led1.SetBrightness( 0);

	if( !bLedWasAlreadyValid)
		m_Led1.Free();

	return bRet;
}


CProjector::CLed::CLed(ALP_ID &AlpDevice)
	: m_AlpDevice(AlpDevice)
	, m_LedId(ALP_INVALID_ID)
{
}


int CProjector::CLed::Alloc (long AlpLedType, int nI2cIndex)
{
	if (ALP_INVALID_ID!=m_LedId) return PROJECTOR_ERROR_ALREADY_ALLOCATED;

	tAlpHldPt120AllocParams I2cAddr;
	I2cAddr.I2cDacAddr = 0x18+2*nI2cIndex;
	I2cAddr.I2cAdcAddr = 0x40+2*nI2cIndex;
	return AlpLedAlloc( m_AlpDevice, AlpLedType, &I2cAddr, &m_LedId );	// call the api function AlpLedAlloc()
}


int CProjector::CLed::Free ()
{
	long nAlpRet = AlpLedFree( m_AlpDevice, m_LedId );
	m_LedId = ALP_INVALID_ID;
	return nAlpRet;
}


bool CProjector::CLed::IsValid()
{
	return ALP_INVALID_ID != m_LedId;
}


int CProjector::CLed::SetBrightness (int nPercent)
{
	if( 0 > nPercent) nPercent = 0;
	if( 100 < nPercent) nPercent = 100;
	return AlpLedControl( m_AlpDevice, m_LedId, ALP_LED_BRIGHTNESS, nPercent );	// call the api function AlpLedControl()
}

long CProjector::CLed::GetMeasuredCurrent()
{
	long lMeasuredCurrent = 0L;
	AlpLedInquire( m_AlpDevice, m_LedId, ALP_LED_MEASURED_CURRENT, &lMeasuredCurrent);	// call the api function AlpLedInquire()
	return lMeasuredCurrent;
}
