#include <stdio.h>
#include <mex.h>
#include <math.h>
#include <cbw.h>
#include <mmsystem.h>

#define MAX_BOARDS 3

#define MAX(a,b)(a)>(b)?(a):(b)
#define MIN(a,b)(a)<(b)?(a):(b)
class DAQBoard
{
public:
	DAQBoard(int BoardNum);
	bool allocate(long len, int numCh=1);
	// Allocate  buffer of size BufferLength (must be multiples of usb packet size (31 bytes)
	// also, defines the numSpots, which is the size of a single "frame", or number of
	// spots that will be scanned. Each spot can be potentioally over sampled by  afactor of 
	// OverSampling using secondary Arduino circuit. Thus, the total number of samples 
	// in a given frame NumSpots*OverSampling
	bool voltageOut(int channel, int voltage);
	long getNumSamplesAcquired();
	bool startContinuousAcqusitionExtClock(int LowChan, int HighChan,int voltInputRange, bool singleEnded);
	bool startContinuousAcqusitionFixedRateTrigger(long Rate, int voltInputRange, bool singleEnded, bool trig);
	bool stopContinuousAcqusition();
	int readAnalog(int channel,int voltInputRange, bool singleEnded = true);
	long getLastFrameRead();
	int getBufferDimensions();
	int resetCounters();
	ULONG readCounter(int CounterNum);

	void setAcqusitionParams(
		int _numChannels,
		int _numPlanes,
		long _numFrames,
		int _overSampling,
		int _numSpotsPerPlane
		);
	~DAQBoard();
	WORD *get16BitBuffer();
	void getAverageFrameSignal(long frame, double *avg);
	// note, avg needs to be allocated outside, and be 1xNumSpots in length (i.e, 8*NumSpots bytes).
	long getNumberOfUnreadFrames();
	long getBufferSize();
	long getLastFullyAcquiredFrame();
	//void getParsedBuffer(mxArray *plhs[]);
	void getBuffer(mxArray *plhs[]);
	int getNumChannels();
	int getNumPlanes();
	long getNumSpotsPerPlane();
	
private:
	int VoltageRangeToEnum(int voltInputRange,bool singleEnded);
	
	long lastFrameRead;
	bool HighResAD;
	unsigned long samplesPerFrame;
	unsigned long samplesPerPlane;
	unsigned long samplesPerSpot;

	bool initialized;

	int numChannels;
	int numPlanes;
	long numFrames;
	int overSampling;
	int numSpotsPerPlane; 

	int outRange;
	int boardNum;
	long bufferLength;
	bool background;
	HANDLE memHandle;
	WORD *data16bit;
	DWORD *data32bit;
};

int DAQBoard::resetCounters()
{
	/* Reset the starting value to the counter with cbCLoad32()
	Parameters:
	BoardNum    :the number used by CB.CFG to describe this board
	RegName     :the counter to be loading with the starting value
	LoadValue   :the starting value to place in the counter */
	int LoadValue = 0;   /* Event Counters can only be reset to 0 */
	int RegName = LOADREG1;
	int ULStat;
	ULStat = cbCLoad32(boardNum, LOADREG0, LoadValue);
	ULStat = cbCLoad32(boardNum, LOADREG1, LoadValue);
	return ULStat;
}

ULONG DAQBoard::readCounter(int CounterNum)
{
	ULONG Count=0;
	int ULStat = cbCIn32(boardNum, CounterNum, &Count);
	return Count;
}

long DAQBoard::getNumSpotsPerPlane()
{
	return numSpotsPerPlane;
}

int DAQBoard::getNumPlanes()
{
	return this->numPlanes;
}

int DAQBoard::getNumChannels()
{
	return numChannels;
}


void DAQBoard::setAcqusitionParams(
	int _numChannels,
	int _numPlanes,
	long _numFrames,
	int _overSampling,
	int _numSpotsPerPlane
	)
{
	numChannels = _numChannels;
	numPlanes = _numPlanes;
	numFrames = _numFrames;
	overSampling = _overSampling;
	numSpotsPerPlane = _numSpotsPerPlane;

	samplesPerSpot = overSampling * numChannels;
	samplesPerPlane = numSpotsPerPlane * samplesPerSpot;
	samplesPerFrame = numPlanes * samplesPerPlane;
	lastFrameRead = -1;

}

/*

void DAQBoard::getParsedBufferStartContinuousAcqusitionFixedRateTrigger(mxArray *plhs[])
{
	if (memHandle == nullptr)
	{
		mexPrintf("someone called getParsedBuffer after releasing memory?!?!?");
		return;
	}

	for (int frame = 0; frame < numFrames; frame++)
	{
		unsigned long frameOffset = frame * numPlanes*numSpotsPerPlane*overSampling*numChannels;
		for (int plane = 0; plane < numPlanes; plane++)
		{
			unsigned long planeOffset = plane * numSpotsPerPlane*overSampling*numChannels;
			for (int spot = 0; spot < numSpotsPerPlane; spot++)
			{
				unsigned long spotOffset = spot * overSampling*numChannels;
				for (int over = 0; over < overSampling; over++)
				{
					for (int ch = 0; ch < numChannels; ch++)
					{
						data16bit[frameOffset + planeOffset + spotOffset + over*numChannels + ch] = 1000 * frame + (ch+1)*spot;
					}
				}
			}
		}
	}
	
	for (unsigned long k = 0; k < numChannels* overSampling* numSpotsPerPlane* numPlanes* numFrames; k++)
		data16bit[k] = k;

	const int dim[5] = { numChannels, overSampling, numSpotsPerPlane, numPlanes, numFrames };
	plhs[0] = mxCreateNumericArray(5, dim, mxUINT16_CLASS, mxREAL);
	unsigned short* outputBuf = (unsigned short*)mxGetData(plhs[0]);
	memcpy(outputBuf, data16bit, numChannels* overSampling* numSpotsPerPlane* numPlanes* numFrames * sizeof(UINT16_T));


//	plhs[0] = mxCreateNumericArray(5, dim, mxDOUBLE_CLASS, mxREAL);
//	double* outputBuf = (double*)mxGetData(plhs[0]);
	//for (unsigned long k = 0; k < numChannels* overSampling* numSpotsPerPlane* numPlanes* numFrames; k++)
//		outputBuf[k] = k; // data16bit[k];
	
	for (int k = 0; k < numChannels, overSampling, numSpotsPerPlane, numPlanes, numFrames; k++)
		outputBuf[k] = data16bit[k];
		
}
*/


void DAQBoard::getBuffer(mxArray *plhs[])
{
	if (memHandle == nullptr)
	{
		mexPrintf("someone called getParsedBuffer after releasing memory?!?!?");
		return;
	}
	UINT16_T* outputBuf;

		// slow DAQ, split the data to 2D:
		// Y dimension: channels
		// X dimensions: time
	long tmp = (long)ceil((double)bufferLength / numChannels);
	const int dim[2] = { numChannels, tmp };
	plhs[0] = mxCreateNumericArray(2, dim, mxUINT16_CLASS, mxREAL);
	outputBuf = (UINT16_T*)mxGetData(plhs[0]);
	memcpy(outputBuf, data16bit, bufferLength * sizeof(UINT16_T));
	/*
	for (int k = 0; k < bufferLength; k++)
		outputBuf[k] = data16bit[k];
		*/
}

long DAQBoard::getLastFrameRead()
{
	return lastFrameRead;
}

void DAQBoard::getAverageFrameSignal(long frame, double *out)
{
	// This function returns the average signal for a desired "frame" (planes x spots x channels)
	
	if (memHandle == nullptr)
	{
		mexPrintf("someone called getAverageFrameSignal after releasing memory?!?!?");
		return;
	}
	WORD *raw = get16BitBuffer();

	long frameStartPos = frame*samplesPerFrame;
	
	for (int plane = 0; plane < numPlanes; plane++)
	{
		unsigned long planeOffsetInput = plane * numSpotsPerPlane * overSampling * numChannels;
		unsigned long planeOffsetOutput = plane * numSpotsPerPlane * numChannels;

		for (int spot = 0; spot < numSpotsPerPlane; spot++)
		{
			unsigned long spotOffsetInput = spot * numChannels * overSampling;
			unsigned long spotOffsetOutput = spot * numChannels;
			for (int channel = 0; channel < numChannels; channel++)
			{
				// calculate the average spot response.
				double avgSpotResponse = 0;
				for (int over = 0; over < overSampling; over++)
				{
					avgSpotResponse += raw[frameStartPos + planeOffsetInput + spotOffsetInput + over*numChannels + channel];
				}
 				avgSpotResponse /= overSampling;
				out[planeOffsetOutput + spotOffsetOutput + channel] = avgSpotResponse;
			}
		}
	}
	
		
	if (frame > lastFrameRead)
		lastFrameRead = frame;
	
	
}

long DAQBoard::getNumberOfUnreadFrames()
{
	long framesAvailable = getLastFullyAcquiredFrame();
	if (framesAvailable < 0)
		return 0;
	if (lastFrameRead < 0)
		return framesAvailable;

	return framesAvailable - (lastFrameRead + 1); // frames are counted from zero
}

long DAQBoard::getLastFullyAcquiredFrame()
{
	int X = getNumSamplesAcquired();
	if (X < samplesPerFrame)
		return -1;

	return MIN(numFrames, (long)floor((double)X / samplesPerFrame));
}

int DAQBoard::VoltageRangeToEnum(int voltInputRange, bool singleEnded)
{
/*
#define BIP10VOLTS       1              // -10 to +10 Volts 
#define BIP5VOLTS        0              // -5 to +5 Volts 
#define BIP4VOLTS        16             // -4 to + 4 Volts 
#define BIP2PT5VOLTS     2              // -2.5 to +2.5 Volts 
#define BIP2VOLTS        14             // -2.0 to +2.0 Volts 
#define BIP1PT25VOLTS    3              // -1.25 to +1.25 Volts 
#define BIP1VOLTS        4              // -1 to +1 Volts 
*/
	int inRange;
	switch (voltInputRange)	{
	case 1:
		inRange = singleEnded ? UNI1VOLTS : BIP1VOLTS;
		break;
	case 2:
		inRange = singleEnded ? UNI2VOLTS : BIP2VOLTS;
		break;
	case 5:
		inRange = singleEnded ? UNI5VOLTS : BIP5VOLTS;
		break;
	case 10:
		inRange = singleEnded ? UNI10VOLTS : BIP10VOLTS;
		break;
	default:
		return -1;
	}
	return inRange;
}

int DAQBoard::readAnalog(int channel, int voltInputRange, bool singleEnded)
{

	USHORT value;
	int ULStat = cbAIn(boardNum, channel, VoltageRangeToEnum(voltInputRange, singleEnded), &value);
	if (ULStat == NOERRORS)
		return value;
	mexPrintf("Error encountered, %d\n",ULStat);
	return -1000;
}

long DAQBoard::getBufferSize()
{
	return bufferLength;
}


bool DAQBoard::startContinuousAcqusitionExtClock(int LowChan, int HighChan, int voltInputRange, bool singleEnded)
{
	if (!initialized)
		return false;

	if (background)
	{
		// already running. Probably called to reset buffer. Stop acqusition.
		int ULStat = cbStopBackground(boardNum, AIFUNCTION);
	}

	long Rate = 8000000; // ignored
	unsigned Options = CONVERTDATA + BACKGROUND + BLOCKIO + EXTCLOCK;// CONVERTDATA + BACKGROUND + CONTINUOUS + BLOCKIO + EXTCLOCK; // SINGLEIO 
	int numChannelsToCollect = (HighChan - LowChan + 1);

	mexPrintf("Collecting %d channels: total %d samples (%d per channel)...\n", numChannelsToCollect, bufferLength, bufferLength / numChannelsToCollect);
	int ULStat = cbAInScan(boardNum, LowChan, HighChan, bufferLength, &Rate, VoltageRangeToEnum(voltInputRange, singleEnded), memHandle, Options);
	numChannels = HighChan-LowChan+1;

	if (ULStat != NOERRORS)
	{
		mexPrintf("Error scanning (%d)\n",ULStat);
	}
	background = ULStat == NOERRORS;

	return ULStat == NOERRORS;
}


bool DAQBoard::startContinuousAcqusitionFixedRateTrigger(long Rate, int voltInputRange, bool singleEnded, bool trig)
{
	if (!initialized)
		return false;

	if (background)
	{
		// already running. Probably called to reset buffer. Stop acqusition.
		int ULStat = cbStopBackground(boardNum, AIFUNCTION);
	}

	
	unsigned Options = CONVERTDATA + BACKGROUND + BLOCKIO ; // SINGLEIO 
	if (trig)
	{
		Options += EXTTRIGGER;
	}
	int ULStat = cbAInScan(boardNum, 0, numChannels-1, bufferLength, &Rate, VoltageRangeToEnum(voltInputRange, singleEnded), memHandle, Options);
	background = ULStat == NOERRORS;

	return ULStat == NOERRORS;
}


WORD* DAQBoard::get16BitBuffer()
{
	return data16bit;
}

long DAQBoard::getNumSamplesAcquired()
{
	if (!initialized)
		return -3;

	short Status = RUNNING;
	long CurCount;
	long CurIndex;
	int ULStat = cbGetStatus(boardNum, &Status, &CurCount, &CurIndex, AIFUNCTION);
	if (ULStat == NOERRORS)
		return CurCount;
	else
		return -2;
}

bool DAQBoard::voltageOut(int channel, int voltage)
{
	int ULStat = cbAOut(boardNum, channel, outRange, voltage);
	return (ULStat == NOERRORS);
}



bool DAQBoard::allocate(long len, int numCh)
{
	numChannels = numCh;
	/*
	numSpots = NumSpots;
	overSampling = OverSampling;
	numChannels = NumChannels;
	lastFrameRead = -1;
	numSamplesPerChannel = NumSamplesPerChannel;
	bufferLength = overSampling*numSamplesPerChannel*numChannels;

	maxNumberOfFrames = bufferLength / FrameSize;
	frameSize = FrameSize;
	if (bufferLength % packetSize != 0) {// buffer is a multiple of USB buffer packet
		mexPrintf("buffer size is not a multiple of packet size (%d)",packetSize);
		return false;
	}
	*/
	bufferLength = len;
	cbErrHandling(DONTPRINT, DONTSTOP);
	int ADRes;

	float    RevLevel = (float)CURRENTREVNUM;
	int ULStat = cbDeclareRevision(&RevLevel);
	if (ULStat != NOERRORS)
		return false;

	// Get the resolution of A/D 
	ULStat  = cbGetConfig(BOARDINFO, boardNum, 0, BIADRES, &ADRes);
	if (ULStat != NOERRORS) {
		mexPrintf("Error getting configuation of board %d (error = %d)\n",boardNum,ULStat );
		return false;
	}
	
	// check If the resolution of A/D is higher than 16 bit. If it is, then the A/D is high resolution. 
	HighResAD = ADRes > 16;

	if (memHandle != nullptr)
	{
		cbWinBufFree(memHandle);
		memHandle = nullptr;
	}

	// allocate memory
	if (HighResAD)
	{
		memHandle = cbWinBufAlloc32(bufferLength);
		data32bit = (DWORD*)memHandle;
	}
	else
	{
		memHandle = cbWinBufAlloc(bufferLength );
		data16bit = (WORD*)memHandle;
	}

	if (!memHandle)  
	{
		mexPrintf("Error Allocating memory\n");
		return false;
	}
	initialized = true;
	return true;
}

bool DAQBoard::stopContinuousAcqusition()
{
	int ULStat;
	if (background)
		ULStat = cbStopBackground(boardNum, AIFUNCTION);
	return true;
}


DAQBoard::~DAQBoard()
{
	int ULStat;
	if (background)
		ULStat = cbStopBackground(boardNum, AIFUNCTION);

	if (memHandle != nullptr)
	{
		cbWinBufFree(memHandle);
		memHandle = nullptr;
	}
}
DAQBoard::DAQBoard(int BoardNum)
{
	boardNum = BoardNum;
	memHandle = 0;
	numChannels = 0;
	data16bit = nullptr;
	data32bit = nullptr;
	background = false;
	initialized = false;
	samplesPerFrame = samplesPerPlane = samplesPerSpot = bufferLength = numFrames = numSpotsPerPlane = overSampling = numPlanes = lastFrameRead = overSampling = -1;
	

}

typedef DAQBoard* pDAQBoard;

pDAQBoard* DAQBoards = nullptr;
bool boardsAllocated = false;

void exitFunction()
{
	if (DAQBoards != nullptr)
	{
		for (int k = 0; k < MAX_BOARDS; k++)
		{
			if (DAQBoards[k] != NULL)
				delete(DAQBoards[k]);
		}
		delete DAQBoards;
		DAQBoards = nullptr;
	}
	boardsAllocated = false;
}

void fnPrintUsage()
{
	mexPrintf("Usage:\n");
	mexPrintf("fnDAQusb(command, param)\n");
	mexPrintf("\n");
	mexPrintf("Commands are: \n");
	mexPrintf("	Init - Call once before doing anything!\n");
	mexPrintf(" Release - Call once when shutting down\n");
	mexPrintf("	OutputVoltage(board, channel, value\n");
	mexPrintf("	Allocate(board, bufferSize)\n");
	mexPrintf("	AllocateFrames(board, bufferSize)\n");
	mexPrintf("	StartContinuousAcqusitionWithTrigger(board, channel)\n");
	mexPrintf("	StartContinuousAcqusition(board, channel, rate)\n");
	mexPrintf("	GetBuffer(board, numSamples[optional])\n");
	//mexPrintf("	GetParsedBuffer(board, numSamples[optional])\n");
	mexPrintf(" GetNumSamplesAcquiried(board)\n");
	
}


void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[])
{
	if (nrhs < 1) {
		fnPrintUsage();
		return;
	}

	int StringLength = int(mxGetNumberOfElements(prhs[0])) + 1;
	char* Command = (char*)mxCalloc(StringLength, sizeof(char));

	if (mxGetString(prhs[0], Command, StringLength) != 0){
		mexErrMsgTxt("\nError extracting the command.\n");
		return;
	}
	else if (strcmp(Command, "IsInitialized") == 0) {
		plhs[0] = mxCreateLogicalScalar(boardsAllocated);
		return;
	}
	else if (strcmp(Command, "Init") == 0) {
		int board = int(*(double*)mxGetData(prhs[1]));

		if (DAQBoards == nullptr)
		{
			mexAtExit(exitFunction);
			DAQBoards = new pDAQBoard[MAX_BOARDS];
			for (int k = 0; k < MAX_BOARDS; k++)
			{
				DAQBoards[k] = NULL;
			}
		}

		DAQBoards[board] = new DAQBoard(board);
		boardsAllocated = true;

		plhs[0] = mxCreateDoubleScalar(1);
		return;
	}
	if (!boardsAllocated)
	{
		mexPrintf("Device released. Call Init First!\n");
		return;
	}
	 if (strcmp(Command, "OutputVoltage") == 0)
	{
		if (nrhs < 4)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}
		int board = int(*(double*)mxGetData(prhs[1]));
		int channel = int(*(double*)mxGetData(prhs[2]));
		int value = int(*(double*)mxGetData(prhs[3]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->voltageOut(channel, value));
	 }
	 else if (strcmp(Command, "Allocate") == 0)
	 {
		 if (nrhs < 4)
		 {
			 mexPrintf("Incorrect parameters\n");
			 return;
		 }

		 int board = int(*(double*)mxGetData(prhs[1]));

		 int numChannels = int(*(double*)mxGetData(prhs[2]));
		 if (numChannels <= 0) {
			 mexPrintf("Channel count needs to be positive\n");
			 return;
		 }
		 unsigned long numSamplesPerChannel = unsigned long(*(double*)mxGetData(prhs[3]));

		 if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		 plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->allocate(numChannels*numSamplesPerChannel, numChannels));
	 }
	else if (strcmp(Command, "AllocateFrames") == 0)
	{
		if (nrhs < 8)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));

		int numChannels = int(*(double*)mxGetData(prhs[2]));
		if (numChannels <= 0) {
			mexPrintf("Channel count needs to be positive\n");
			return;
		}
		long numPlanes = long(*(double*)mxGetData(prhs[3]));
		long numSpotsPerPlane = long(*(double*)mxGetData(prhs[4]));
		int overSampling = long(*(double*)mxGetData(prhs[5]));
		long numFrames = long(*(double*)mxGetData(prhs[6]));



		long packetSize = long(*(double*)mxGetData(prhs[7]));
		long numSamplesPerFrame = numChannels * numPlanes *  numSpotsPerPlane * overSampling;
		long totalDesiredSamples = numFrames * numSamplesPerFrame;
	
		long actualNumberSamplesToCollect = packetSize*ceil((double)totalDesiredSamples / (packetSize));
		mexPrintf("Allocating %d samples\n", actualNumberSamplesToCollect);

		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->allocate(actualNumberSamplesToCollect, numChannels));
		DAQBoards[board]->setAcqusitionParams(numChannels, numPlanes, numFrames, overSampling, numSpotsPerPlane);
	}
	else if (strcmp(Command, "StopContinuousAcqusition") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->stopContinuousAcqusition());
	}
	else if (strcmp(Command, "StartContinuousAcqusitionExtClock") == 0)
	{
		if (nrhs < 6)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		int Lowchannel = int(*(double*)mxGetData(prhs[2]));
		int Highchannel = int(*(double*)mxGetData(prhs[3]));
		int VoltageRange = int(*(double*)mxGetData(prhs[4]));
		bool singleEnded= bool(*(double*)mxGetData(prhs[5]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->startContinuousAcqusitionExtClock(Lowchannel, Highchannel, VoltageRange, singleEnded));
	}
	else if (strcmp(Command, "StartContinuousAcqusitionFixedRateTrigger") == 0)
	{
		if (nrhs < 5)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		long rate = long(*(double*)mxGetData(prhs[2]));
		int VoltageRange = int(*(double*)mxGetData(prhs[3]));
		bool SingleEnded = bool(*(double*)mxGetData(prhs[4]));

		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->startContinuousAcqusitionFixedRateTrigger(rate, VoltageRange, SingleEnded,true));
	}
	else if (strcmp(Command, "StartContinuousAcqusitionFixedRate") == 0)
	{
		if (nrhs < 5)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		long rate = long(*(double*)mxGetData(prhs[2]));
		int VoltageRange = int(*(double*)mxGetData(prhs[3]));
		bool SingleEnded = bool(*(double*)mxGetData(prhs[4]));

		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->startContinuousAcqusitionFixedRateTrigger(rate, VoltageRange, SingleEnded,false));
	}
	else if (strcmp(Command, "Release") == 0) 
	{
		exitFunction();
	}
	else if (strcmp(Command, "GetBuffer") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		DAQBoards[board]->getBuffer(plhs);
	}
	/*else if (strcmp(Command, "GetParsedBuffer") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		DAQBoards[board]->getParsedBuffer(plhs);
	}*/
	else if (strcmp(Command, "GetNumFramesAcquiried") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
     	if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }

		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->getLastFullyAcquiredFrame());
	}
	else if (strcmp(Command, "GetNumUnreadFrames") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
     	if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }

		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->getNumberOfUnreadFrames());

	} else if (strcmp(Command, "GetLastFrameRead") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }

		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->getLastFrameRead());
	}	else if (strcmp(Command, "GetFrames") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		// return all unread frames.
		int board = int(*(double*)mxGetData(prhs[1]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }

		int numUnreadFrames = DAQBoards[board]->getNumberOfUnreadFrames();
		long lastReadFrame = DAQBoards[board]->getLastFrameRead();
		if (numUnreadFrames == 0)
		{
			plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
			plhs[1] = mxCreateDoubleMatrix(0, 0, mxREAL);
			plhs[2] = mxCreateDoubleMatrix(0, 0, mxREAL);
			return;
		}
		plhs[1] = mxCreateDoubleScalar(lastReadFrame+1);
		const int dim[4] = { DAQBoards[board]->getNumChannels() , DAQBoards[board]->getNumSpotsPerPlane(),DAQBoards[board]->getNumPlanes(), numUnreadFrames};

		plhs[2] = mxCreateDoubleScalar(numUnreadFrames);

		unsigned long frmSize = DAQBoards[board]->getNumPlanes() * DAQBoards[board]->getNumSpotsPerPlane() * DAQBoards[board]->getNumChannels();
		plhs[0] = mxCreateNumericArray(4, dim, mxDOUBLE_CLASS, mxREAL);
		double* outputBuf = (double*)mxGetData(plhs[0]);

		for (unsigned long k = 0; k < numUnreadFrames; k++)
		{
			DAQBoards[board]->getAverageFrameSignal(k + lastReadFrame + 1, &outputBuf[k*frmSize]);
		}

	}
	else  if (strcmp(Command, "GetNumSamplesAcquiried") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->getNumSamplesAcquired());
	}
	else  if (strcmp(Command, "ResetCounters") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->resetCounters());
	}
	else  if (strcmp(Command, "ReadCounter") == 0)
	{
		if (nrhs < 2)
		{ 
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		int counter = int(*(double*)mxGetData(prhs[2]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->readCounter(counter));
	}
	else  if (strcmp(Command, "ReadCounters") == 0)
	{
		if (nrhs < 2)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		long count1 = DAQBoards[board]->readCounter(0);
		long count2 = DAQBoards[board]->readCounter(1);
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(count1);
		plhs[1] = mxCreateDoubleScalar(count2);
	}
	else  if (strcmp(Command, "ReadAnalog") == 0)
	{
		if (nrhs < 4)
		{
			mexPrintf("Incorrect parameters\n");
			return;
		}

		int board = int(*(double*)mxGetData(prhs[1]));
		int channel = int(*(double*)mxGetData(prhs[2]));
		int voltageRange = int(*(double*)mxGetData(prhs[3]));
		if (board < 0 || board >= MAX_BOARDS || !boardsAllocated) 		{ mexPrintf("Error calling DAQUSB\n"); plhs[0] = mxCreateDoubleScalar(0); return; }
		plhs[0] = mxCreateDoubleScalar(DAQBoards[board]->readAnalog(channel,voltageRange));
	}

	

}

