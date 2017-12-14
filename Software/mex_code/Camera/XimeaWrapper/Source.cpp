/*
Ximea Matlab Wrapper
Programmed by Shay Ohayon
DiCarlo Lab @ MIT

Revision History
Version 0.1 02/23/2017

#define WIN32 1
*/
#include <stdio.h>
#include "../Ximea/API/xiapi.h"
#include "mex.h"
#include <Windows.h>
#include <queue>
#include <deque>

#define MIN(a,b) (a)<(b)?(a):(b)
#define MAX(a,b) (a)>(b)?(a):(b)
bool calledOnce = false;


using namespace std;


template<typename T, typename Container = std::deque<T> >
class iterable_queue : public std::queue<T, Container>
{
public:
	typedef typename Container::iterator iterator;
	typedef typename Container::const_iterator const_iterator;

	iterator begin() { return this->c.begin(); }
	iterator end() { return this->c.end(); }
	const_iterator begin() const { return this->c.begin(); }
	const_iterator end() const { return this->c.end(); }
};



class XimeaWrapper {
public:
	XimeaWrapper();
	~XimeaWrapper();
	bool isInitialized();
	bool init(int x0, int y0, int _width, int _height);
	int getWidth();
	int getHeight();
	bool softwareTrigger();
	void frameCallback(XI_IMG* pImage);
	bool setGain(float value);
	float getGain();
	void setAutoExposure(bool value);
	bool getAutoExposure();
	int getNumImagesInBuffer();
	void setExposure(float value);
	float getExposure();
	int copyAndClearBuffer(unsigned char *imageBufferPtr, int N);
	int getBytesPerPixel();
	void clearBuffer();
	int getNumTrigs();
	void resetTriggerCounter();
	//float getFrameRate();
	void setFrameRate(float Rate);
	void setTrigger(bool state);
	//int pokeLastFrames(unsigned char *imageBufferPtr, int N);
	//int copyBuffer16Bit(unsigned char *imageBufferPtr, int N);
	void printStats();
	unsigned long numTrig;
	bool triggerEnabled;
	void startAveraging(int numFrames, bool ReconstructionMode);
	void stopAveraging();
	bool inAveragingMode();
	bool successfulAveraging();
	//void printError(Error error);
	void setTriggerMode(bool external);
	void lockMutex();
	void unlockMutex();
	XI_IMG*  computePhase();
	bool stopThread;
	HANDLE xiH;
	int width, height;
private:
	void averageImages(XI_IMG *A, XI_IMG *B, int iter);
	int copyAndClearBuffer16Bit(unsigned char *imageBufferPtr, int N);

	int bytesPerPixel;
	void release();

	XI_IMG TempImages[3];
	iterable_queue<XI_IMG*>::iterator averagingIterator;
	bool averagingMode;
	int averagingBlockSize;
	bool initialized;
	bool deviceOpened;
	bool streaming;
	int lastResult;
	bool triggered;
	HANDLE ghMutex;
	
	unsigned long maxImagesInBuffer;
	int mutexCount;
	unsigned long trigsSinceBufferRead;
	iterable_queue<XI_IMG*> imageQueue;
	int imageFrameCounter;

	bool printError(XI_RETURN res, char *error);
	void startPoolingThread();
	bool reconstructionMode;

	DWORD   dwThreadId;
	HANDLE  hThread;


};

typedef struct
{
	XimeaWrapper* cam;
} ThreadParams, *pThreadParams;



DWORD WINAPI MyThreadFunction(LPVOID lpParam)
{
	pThreadParams pData = (pThreadParams)lpParam;
	XI_IMG image;
	memset(&image, 0, sizeof(image));
	image.size = sizeof(XI_IMG);
	int TIMOUT_MS = 500;
	while (true)
	{
		if (pData->cam->stopThread)
			break;

		XI_RETURN stat = XI_OK;
		stat = xiGetImage(pData->cam->xiH, TIMOUT_MS, &image);
		if (stat == XI_OK)
		{
			pData->cam->lockMutex();
			XI_IMG *deepCopy = new XI_IMG;
			*deepCopy = image;

			long imgSize = deepCopy->height*deepCopy->width * 2; // assume 10 bit
			deepCopy->bp = new unsigned char[imgSize];
			memcpy(deepCopy->bp, image.bp, imgSize);

			pData->cam->frameCallback(deepCopy);
			pData->cam->unlockMutex();

		}
	}
	return 0;
}



void XimeaWrapper::frameCallback(XI_IMG *pImage)
{
	triggered = true;
	numTrig++;
	trigsSinceBufferRead++;

	int averagingIteration = (numTrig - 1) / averagingBlockSize;
	if (!averagingMode || averagingIteration == 0)
	{
		imageQueue.push(pImage);
		averagingIterator = imageQueue.begin();
	}
	else
	{

		// we are averaging images. Buffer size never exceeds averagingBlockSize
		// the image we need to manipulate is actually  (numTrig-1) % averagingBlockSize
		// first, operate on the image pointed by averagingIterator
		// then increase iterator.
		averageImages(*averagingIterator, pImage, averagingIteration);
		delete pImage;

		averagingIterator++;
		if (averagingIterator == imageQueue.end())
			averagingIterator = imageQueue.begin();

	}


	if (imageQueue.size() > maxImagesInBuffer)
	{
		XI_IMG *p = imageQueue.front();
		delete p;
		imageQueue.pop();
	}

}



void XimeaWrapper::startPoolingThread()
{
	pThreadParams pThreadInput = (pThreadParams)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sizeof(ThreadParams));
	pThreadInput->cam = this;
	this->stopThread = false;
	this->hThread = CreateThread(
		NULL,                   // default security attributes
		0,                      // use default stack size  
		MyThreadFunction,       // thread function name
		pThreadInput,          // argument to thread function 
		0,                      // use default creation flags 
		&this->dwThreadId);   // returns the thread identifier 

}


bool XimeaWrapper::inAveragingMode()
{
	return averagingMode;
}

bool XimeaWrapper::successfulAveraging()
{
	return numTrig % averagingBlockSize == 0;
}

void XimeaWrapper::startAveraging(int numFrames, bool ReconstructionMode)
{
	lockMutex();
	clearBuffer();
	averagingBlockSize = numFrames;
	averagingMode = true;
	reconstructionMode = ReconstructionMode;
	resetTriggerCounter();
	unlockMutex();
}

void XimeaWrapper::stopAveraging()
{
	averagingMode = false;
	reconstructionMode = false;
}

bool XimeaWrapper::printError(XI_RETURN res, char *error)
{
	if (res != XI_OK) {
		mexPrintf("Error encountered: %s\n", error);
		return true;
	}
	return false;
}

bool XimeaWrapper::isInitialized()
{
	return initialized;
}

void XimeaWrapper::setTrigger(bool state)
{
	triggerEnabled = state;
}

void XimeaWrapper::setFrameRate(float Rate)
{
}


void XimeaWrapper::setExposure(float value)
{
	XI_RETURN stat = XI_OK;
	long ExposureMicroseconds = value * 1000000.0;
	stat = xiSetParamInt(xiH, XI_PRM_EXPOSURE, ExposureMicroseconds);
	printError(stat, "xiSetParam (exposure set)");
}

void XimeaWrapper::resetTriggerCounter()
{
	numTrig = 0;

}
int XimeaWrapper::getNumTrigs()
{
	return numTrig;
}

int XimeaWrapper::getBytesPerPixel()
{
	return bytesPerPixel;
}

int XimeaWrapper::getNumImagesInBuffer()
{
	int n;
	lockMutex();
	n = (int)imageQueue.size();
	unlockMutex();
	return n;
}



float XimeaWrapper::getExposure()
{
	int explo;
	XI_RETURN stat = XI_OK;
	stat = xiGetParamInt(xiH, XI_PRM_EXPOSURE, &explo);
	printError(stat, "xiGetParam (exposure get)");

	float exposureSec = (float)explo / 1000000.0;
	return exposureSec;
}

void XimeaWrapper::setAutoExposure(bool value)
{
}


bool XimeaWrapper::getAutoExposure()
{
	return false;
}


bool XimeaWrapper::setGain(float value)
{
	XI_RETURN stat = XI_OK;
	stat = xiSetParamFloat(xiH, XI_PRM_GAIN, value);
	printError(stat, "xiSetParam (gain set)");
	return stat == XI_OK;
}



float XimeaWrapper::getGain()
{
	XI_RETURN stat = XI_OK;
	float value;
	stat = xiGetParamFloat(xiH, XI_PRM_GAIN, &value);
	printError(stat, "xiGetParam (gain get)");
	return value;
}



void XimeaWrapper::lockMutex()
{
	mutexCount++;
	int dwWaitResult = WaitForSingleObject(
		ghMutex,    // handle to mutex
		INFINITE);  // no time-out interval
}

void XimeaWrapper::unlockMutex()
{
	ReleaseMutex(ghMutex);
	mutexCount--;
}

bool XimeaWrapper::softwareTrigger()
{
	xiSetParamInt(xiH, XI_PRM_TRG_SOFTWARE, 0);
	return true;
}

void XimeaWrapper::averageImages(XI_IMG *A, XI_IMG *B, int iter)
{
	// running average. Keep result in A.
	unsigned short *dataA = (unsigned short*)A->bp;
	unsigned short *dataB = (unsigned short*)B->bp;

	long numPixels = A->width * A->height;
	for (long counter = 0; counter<numPixels; counter++)
	{
		unsigned short pA = dataA[counter];
		unsigned short pB = dataB[counter];

		unsigned short avgValue = float((iter)* pA + pB) / (float)(iter + 1);
		dataA[counter] = avgValue;
	}
}

void XimeaWrapper::clearBuffer()
{
	lockMutex();
	int N = imageQueue.size();
	for (int k = 0; k < N; k++)
	{
		XI_IMG *p = imageQueue.front();
		delete p;
		imageQueue.pop();
	}
	unlockMutex();
}

int XimeaWrapper::copyAndClearBuffer16Bit(unsigned char *imageBufferPtr, int N)
{
	unsigned short *imageBufferIntPtr = (unsigned short *)imageBufferPtr;
	int tmp = sizeof(unsigned short);
	tmp = tmp;
	lockMutex();
	int numCopied = 0;

	int numToCopy = MIN(imageQueue.size(), N);
	int FirstImageTrig = (numToCopy > 0) ? (imageQueue.front())->nframe : -1;
	unsigned short Pixel = 0;
	for (long k = 0; k<numToCopy; k++)
	{
		XI_IMG *I = imageQueue.front();

		unsigned short *data16bits = (unsigned short*)I->bp;
		long long offset = ((long long)width*(long long)height*k);

		long numBytesToCopy = I->height * I->width * 2;
		// Assume no data packing....
		memcpy(imageBufferIntPtr + offset, data16bits, numBytesToCopy);
		
		int counter = 0;
		for (long y = 0; y<height; y++)
		{
		for (long x = 0; x<width; x++)
		{

		Pixel = data16bits[counter];
		//Pixel = Pixel >> 4;	// move the upper 12 bit to the right, so we have 0..4095 gray scales.
		imageBufferIntPtr[offset + (long long)((y)+x*(long)height)] = Pixel;
		counter++;
		}
		}
		

		imageQueue.pop();
		delete I;
	}
	unlockMutex();

	return FirstImageTrig;
}



/*
int XimeaWrapper::pokeLastFrames(unsigned char *imageBufferPtr, int N)
{
return copyBuffer16Bit(imageBufferPtr, N);
}
*/

int XimeaWrapper::copyAndClearBuffer(unsigned char *imageBufferPtr, int N)
{
	trigsSinceBufferRead = 0;
	return copyAndClearBuffer16Bit(imageBufferPtr, N);
}


int XimeaWrapper::getWidth()
{
	return width;
}

int XimeaWrapper::getHeight()
{
	return height;
}




void XimeaWrapper::release()
{
	if (streaming)
	{
		// stop streaming...
		triggerEnabled = false;
		stopThread = true;
		unlockMutex();
		Sleep(600); // wait for all threads to finish reading... (?)

		mexPrintf("Stopping capture...");
		xiStopAcquisition(this->xiH);

		streaming = false;
		mexPrintf("OK!\n");
	}
	Sleep(100); // wait for all threads to finish writing... (?)

	if (initialized)
	{
		if (deviceOpened)
		{
			xiCloseDevice(this->xiH);
		}

		mexPrintf("Closing mutex...");
		CloseHandle(ghMutex);
		mexPrintf("OK!\n");
		ghMutex = NULL;
		initialized = false;
	}
	mexPrintf("Release sequence finished!\n");
}




bool XimeaWrapper::init(int x0 = 0, int y0 = 0, int _width = 1280, int _height = 1024)
{
	if (initialized)
		return true;

	DWORD NumberDevices;
	XI_RETURN stat = xiGetNumberDevices(&NumberDevices);
	if (NumberDevices == 0) {
		mexPrintf("No XiMEA cameras found. Aborting\r\n");
		return false;
	}

	// pick first device.
	DWORD DevId = 0;

	stat = xiOpenDevice(DevId, &this->xiH);
	if (stat != XI_OK)
	{
		mexPrintf("Cannot open device %d\r\n", DevId);
		return false;
	}

	xiSetParamInt(this->xiH, XI_PRM_SHUTTER_TYPE, XI_SHUTTER_GLOBAL);
	xiSetParamInt(this->xiH, XI_PRM_IMAGE_DATA_FORMAT, XI_RAW16);
	xiSetParamInt(this->xiH, XI_PRM_OUTPUT_DATA_BIT_DEPTH, 10);
	xiSetParamInt(this->xiH, XI_PRM_TRG_SOURCE, XI_TRG_EDGE_RISING);
	// no auto white balance
	printError(xiSetParamInt(this->xiH, XI_PRM_AUTO_WB, 0), "Setting White Balance");
	// no auto exposure
	printError(xiSetParamInt(this->xiH, XI_PRM_AEAG, 0), "Setting Auto Exposure");



	int width_inc;
	int height_inc;
	xiGetParamInt(this->xiH, XI_PRM_HEIGHT XI_PRM_INFO_INCREMENT, &height_inc);
	width_inc = 16;

	mexPrintf("Requesting ROI [%d,%d,%d,%d]\r\n", x0, y0, _width, _height);
	int offset_x = (x0 / width_inc) * width_inc;
	int offset_y = (y0 / height_inc) * height_inc;
	int image_width = (_width / height_inc) * height_inc;
	int image_height = (_height / height_inc) * height_inc;
	mexPrintf("Attempting to set ROI: [%d,%d,%d,%d]\r\n", offset_x, offset_y, image_width, image_height);
	bool bError = false;
	bError |= printError(xiSetParamInt(this->xiH, XI_PRM_WIDTH, image_width), "Set Image Width");
	bError |= printError(xiSetParamInt(this->xiH, XI_PRM_HEIGHT, image_height), "Set Image Height");

	bError |=printError(xiSetParamInt(this->xiH, XI_PRM_OFFSET_X, offset_x), "Set Offset X");
	bError |= printError(xiSetParamInt(this->xiH, XI_PRM_OFFSET_Y, offset_y), "Set Offset Y");
	if (bError)
	{
		mexPrintf("Aborting and closing camera.\r\n");
		stat = xiCloseDevice(this->xiH);
		return false;
	}

	width = image_width;
	height = image_height;

	bytesPerPixel = 2; // 10 bit ADC



	maxImagesInBuffer = (long)15 * 1e9 / (width*height*bytesPerPixel); // 15GB (!)
	mexPrintf("Allowing maximum 15GB of memory, or %d 16 bit images.\n", maxImagesInBuffer);


	deviceOpened = true;


	stat = xiStartAcquisition(this->xiH);
	if (stat != XI_OK)
	{
		xiCloseDevice(this->xiH);
		return false;
	}

	xiSetParamInt(0, XI_PRM_DEBUG_LEVEL, XI_DL_FATAL);
	streaming = true;
	initialized = true;
	mexPrintf("Camera initialized and in capture mode\n");
	startPoolingThread();
	return true;
}

XimeaWrapper::XimeaWrapper() : initialized(false), deviceOpened(false), streaming(false), triggered(false), numTrig(0), width(0), height(0), bytesPerPixel(2)
{

	ghMutex = CreateMutex(
		NULL,              // default security attributes
		FALSE,             // initially not owned
		NULL);             // unnamed mutex
	maxImagesInBuffer = 25000; // 15GB (!)
	triggerEnabled = true;
	trigsSinceBufferRead = 0;
	averagingBlockSize = 1;
	mutexCount = 0;
	reconstructionMode = false;
	averagingMode = false;
}

void XimeaWrapper::printStats()
{
	/*CameraStats stat;
	cam.GetStats(&stat);
	mexPrintf("Timestamp %d\n", stat.timeStamp);
	mexPrintf("Power is %d\n", stat.cameraPowerUp);
	mexPrintf("Num Corrupted %d\n", stat.imageCorrupt);
	mexPrintf("Driver Dropped %d\n", stat.imageDriverDropped);
	mexPrintf("Images Dropped %d\n", stat.imageDropped);
	mexPrintf("Temperature %d\n", stat.temperature);
	mexPrintf("Port Errors %d\n", stat.portErrors);
	*/
}



void XimeaWrapper::setTriggerMode(bool external)
{
	// Start capturing images
	mexPrintf("Stopping capture...");


}

XimeaWrapper::~XimeaWrapper()
{
	release();
}



XimeaWrapper *camera = nullptr;


void exitFunction()
{
	if (camera != nullptr)
		delete camera;
}

void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[]) {


	if (nrhs == 0)
		return;
	int StringLength = int(mxGetNumberOfElements(prhs[0])) + 1;
	char* Command = new char[StringLength];
	if (mxGetString(prhs[0], Command, StringLength) != 0) {
		mexErrMsgTxt("\nError extracting the command.\n");
		return;
	}
	else if (strcmp(Command, "Init") == 0) {
		mexAtExit(exitFunction);
		if (camera != nullptr)
			delete camera;

		camera = new XimeaWrapper();
		bool Success = camera->init();
		plhs[0] = mxCreateDoubleScalar(Success);
		delete Command;

		return;
	}
	else if (strcmp(Command, "InitWithResolutionOffset") == 0) {
		mexAtExit(exitFunction);
		if (camera != nullptr)
			delete camera;
		if (nrhs < 4) {
			mexPrintf("Not enough parameters (x0,y0,width,height)\n");
			return;
		}
		camera = new XimeaWrapper();

		int x0 = (int)*(double*)mxGetPr(prhs[1]);
		int y0 = (int)*(double*)mxGetPr(prhs[2]);

		int w = (int)*(double*)mxGetPr(prhs[3]);
		int h = (int)*(double*)mxGetPr(prhs[4]);

		bool Success = camera->init(x0, y0, w, h);
		plhs[0] = mxCreateDoubleScalar(Success);
		delete Command;

		return;
	}

	if (strcmp(Command, "IsInitialized") == 0) {
		if (camera == nullptr)
			plhs[0] = mxCreateDoubleScalar(false);
		else
			plhs[0] = mxCreateDoubleScalar(camera->isInitialized());
		return;
	}

	if (camera == nullptr)
	{
		mexErrMsgTxt("You need to call Initialize first!.\n");
		delete Command;
		plhs[0] = mxCreateDoubleScalar(0);
		return;
	}

	if (strcmp(Command, "Release") == 0) {
		if (camera != nullptr)
		{
			delete camera;
			camera = NULL;
			mexPrintf("Camera handles released.\n");
		}
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else if (strcmp(Command, "SetTriggerMode") == 0)
	{
		bool external = *(bool*)mxGetData(prhs[1]);
		camera->setTriggerMode(external);
		plhs[0] = mxCreateDoubleScalar(1);
		return;
	}
	else if (strcmp(Command, "CameraStatus") == 0)
	{
		camera->printStats();
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else if (strcmp(Command, "GetImageBuffer") == 0) {
		if (camera->inAveragingMode())
		{
			int w = camera->getWidth();
			int h = camera->getHeight();
			mwSize dim[3] = { h, w, 0 };
			plhs[0] = mxCreateNumericArray(3, dim, mxUINT8_CLASS, mxREAL);
			mexPrintf("Please call Stop Averaging before calling get image buffer\n");
			return;
		}


		int N = camera->getNumImagesInBuffer();

		if (nrhs > 1)
		{
			// grab a subset of images
			int requestedNumberOfImages = (int)*(double*)mxGetPr(prhs[1]);
			N = MIN(N, requestedNumberOfImages);
		}

		int w = camera->getWidth();
		int h = camera->getHeight();
		mwSize dim[3] = { h, w, N };
		mxArray* imageBuffer;

		imageBuffer = mxCreateNumericArray(3, dim, mxUINT16_CLASS, mxREAL);

		if (imageBuffer == nullptr)
		{
			mexPrintf("Error allocating memory for buffer.\n");
		}

		unsigned char*imageBufferPtr = (unsigned char*)mxGetData(imageBuffer);

		plhs[0] = imageBuffer;
		plhs[1] = mxCreateDoubleScalar(camera->copyAndClearBuffer(imageBufferPtr, N));
	}

	else if (strcmp(Command, "SetExposure") == 0)
	{

		float exposureSec = (float)*(double*)mxGetPr(prhs[1]);
		camera->setExposure(exposureSec);
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else if (strcmp(Command, "StartAveraging") == 0)
	{
		int blockSize = (int)*(double*)mxGetPr(prhs[1]);
		bool Reconstruction = (bool)*(unsigned char*)mxGetPr(prhs[2]);
		camera->startAveraging(blockSize, Reconstruction);
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else if (strcmp(Command, "StopAveraging") == 0)
	{
		camera->stopAveraging();
		plhs[0] = mxCreateDoubleScalar(camera->successfulAveraging());
	}
	else if (strcmp(Command, "GetExposure") == 0)
	{

		float exposureSec = (float)camera->getExposure();
		plhs[0] = mxCreateDoubleScalar(exposureSec);
	}
	else if (strcmp(Command, "SetGain") == 0)
	{
		float gain = *(double*)mxGetPr(prhs[1]);
		camera->setGain(gain);
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else if (strcmp(Command, "GetGain") == 0)
	{
		plhs[0] = mxCreateDoubleScalar(camera->getGain());
	}
	else if (strcmp(Command, "GetBufferSize") == 0)
	{
		plhs[0] = mxCreateDoubleScalar(camera->getNumImagesInBuffer());
	}
	else if (strcmp(Command, "SoftwareTrigger") == 0)
	{
		camera->softwareTrigger();
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else  if (strcmp(Command, "ClearBuffer") == 0)
	{
		camera->clearBuffer();
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else  if (strcmp(Command, "ResetTriggerCounter") == 0)
	{
		camera->resetTriggerCounter();
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else  if (strcmp(Command, "TriggerOFF") == 0)
	{
		camera->setTrigger(false);
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else  if (strcmp(Command, "TriggerON") == 0)
	{
		camera->setTrigger(true);
		plhs[0] = mxCreateDoubleScalar(1);
	}
	else  if (strcmp(Command, "getNumTrigs") == 0)
	{
		plhs[0] = mxCreateDoubleScalar(camera->getNumTrigs());
	}

	else  if (strcmp(Command, "setFrameRate") == 0)
	{
		float rate = *(double*)mxGetPr(prhs[1]);
		camera->setFrameRate(rate);
		plhs[0] = mxCreateDoubleScalar(1);

	} 
	else {
		mexPrintf("Error. Unknown command\n");
	}
	


	delete Command;



}

