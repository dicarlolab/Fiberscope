/*
Point Grey Matlab Wrapper
Programmed by Shay Ohayon
DiCarlo Lab @ MIT

Revision History
Version 0.1 03/25/2015

*/
#include <stdio.h>
#include "mex.h"
#include "FlyCapture2.h"
#include <Windows.h>
#include <queue>
#include <deque>

#define MIN(a,b) (a)<(b)?(a):(b)
#define MAX(a,b) (a)>(b)?(a):(b)
bool calledOnce = false;


using namespace FlyCapture2;
using namespace std;


class myImage : public Image
{
public:
	int frameCounter;
};


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



class PTwrapper {
public:
	PTwrapper();
	~PTwrapper();
	bool isInitialized();
	bool init(int x0, int y0, int _width, int _height, int _mode);
	int getWidth();
	int getHeight();
	bool softwareTrigger();
	void frameCallback(myImage* pImage);
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
	float getFrameRate();
	void setFrameRate(float Rate);
	void setTrigger(bool state);
	int pokeLastFrames(unsigned char *imageBufferPtr, int N);
	int copyBuffer16Bit(unsigned char *imageBufferPtr, int N);
	void printStats();
	unsigned long numTrig;
	bool triggerEnabled;
	void startAveraging(int numFrames, bool ReconstructionMode);
	void stopAveraging();
	bool inAveragingMode();
	bool successfulAveraging();
	void printError(Error error);
	void setTriggerMode(bool external);
	void lockMutex();
	void unlockMutex();
	myImage*  computePhase();

private:
	void averageImages(myImage *A, myImage *B, int iter);
	int copyAndClearBuffer8Bit(unsigned char *imageBufferPtr, int N);
	int copyAndClearBuffer16Bit(unsigned char *imageBufferPtr, int N);

	int bytesPerPixel;
	void release();

	myImage TempImages[3];
	iterable_queue<myImage*>::iterator averagingIterator;
	bool averagingMode;
	int averagingBlockSize;
	bool initialized;
	bool deviceOpened;
	bool streaming;
	int lastResult;
	bool triggered;
	HANDLE ghMutex;
	int width, height;
	unsigned long maxImagesInBuffer;
	int mutexCount;
	unsigned long trigsSinceBufferRead;
	iterable_queue<myImage*> imageQueue;
	int imageFrameCounter;
	Camera cam;
	Error error;
	BusManager busMgr;
	bool reconstructionMode;

};


bool PTwrapper::inAveragingMode()
{
	return averagingMode;
}

bool PTwrapper::successfulAveraging()
{
	return numTrig % averagingBlockSize == 0;
}

void PTwrapper::startAveraging(int numFrames, bool ReconstructionMode)
{
	lockMutex();
	clearBuffer();
	averagingBlockSize = numFrames;
	averagingMode = true;
	reconstructionMode = ReconstructionMode;
	resetTriggerCounter();
	unlockMutex();
}

void PTwrapper::stopAveraging()
{
	averagingMode = false;
	reconstructionMode = false;
}

void PTwrapper::printError(Error error)
{
	mexPrintf("%s\n", error.GetDescription());
}

bool PTwrapper::isInitialized()
{
	return initialized;
}

void PTwrapper::setTrigger(bool state)
{
	triggerEnabled = state;
}

void PTwrapper::setFrameRate(float Rate)
{
}


void PTwrapper::setExposure(float value)
{
	Property shutterProp(SHUTTER);
	error = cam.GetProperty(&shutterProp);
	shutterProp.absControl = true;
	shutterProp.absValue = value;
	shutterProp.autoManualMode = false;
	shutterProp.onOff = true;
	error = cam.SetProperty(&shutterProp);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return;
	}
}

void PTwrapper::resetTriggerCounter()
{
	numTrig = 0;

}
int PTwrapper::getNumTrigs()
{
	return numTrig;
}
int PTwrapper::getBytesPerPixel()
{
	return bytesPerPixel;
}

int PTwrapper::getNumImagesInBuffer()
{
	int n;
	lockMutex();
	n = (int)imageQueue.size();
	unlockMutex();
	return n;
}



float PTwrapper::getExposure()
{
	Property shutterProp(SHUTTER);
	error = cam.GetProperty(&shutterProp);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	return shutterProp.absValue;
}

void PTwrapper::setAutoExposure(bool value)
{
}


bool PTwrapper::getAutoExposure()
{
	return false;
}


bool PTwrapper::setGain(float value)
{
	Property Prop(GAIN);
	error = cam.GetProperty(&Prop);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}

	Prop.absControl = true;
	Prop.absValue = value;
	Prop.autoManualMode = false;
	Prop.onOff = true; // On ?

	error = cam.SetProperty(&Prop);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	return true;
}



float PTwrapper::getGain()
{
	Property Prop(GAIN);
	error = cam.GetProperty(&Prop);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return -1;
	}
	return Prop.absValue;
}



void PTwrapper::lockMutex()
{
	mutexCount++;
	int dwWaitResult = WaitForSingleObject(
		ghMutex,    // handle to mutex
		INFINITE);  // no time-out interval
}

void PTwrapper::unlockMutex()
{
	ReleaseMutex(ghMutex);
	mutexCount--;
}

bool PTwrapper::softwareTrigger()
{
	error = cam.FireSoftwareTrigger();

	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}

	return true;
}

void PTwrapper::averageImages(myImage *A, myImage *B, int iter)
{
	// running average. Keep result in A.
	unsigned short *dataA = (unsigned short*)A->GetData();
	unsigned short *dataB = (unsigned short*)B->GetData();


	for (long counter = 0; counter<height*width; counter++)
	{
		unsigned short pA = dataA[counter] >> 4; // move the upper 12 bit to the right, so we have 0..4095 gray scales.
		unsigned short pB = dataB[counter] >> 4; // move the upper 12 bit to the right, so we have 0..4095 gray scales.

		unsigned short avgValue = float((iter)* pA + pB) / (float)(iter + 1);
		dataA[counter] = avgValue << 4;
	}
}


myImage* PTwrapper::computePhase()
{
	const float PI = 3.1415926536;
	// running average. Keep result in A.
	unsigned short *dataA = (unsigned short*)TempImages[0].GetData();
	unsigned short *dataB = (unsigned short*)TempImages[1].GetData();
	unsigned short *dataC = (unsigned short*)TempImages[2].GetData();
	myImage* phaseImage = new myImage;
	phaseImage->DeepCopy(&TempImages[0]);

	unsigned short *dataOut = (unsigned short*)phaseImage->GetData();
	for (long counter = 0; counter<height*width; counter++)
	{
		unsigned short pA = dataA[counter] >> 4; // move the upper 12 bit to the right, so we have 0..4095 gray scales.
		unsigned short pB = dataB[counter] >> 4; // move the upper 12 bit to the right, so we have 0..4095 gray scales.
		unsigned short pC = dataB[counter] >> 4; // move the upper 12 bit to the right, so we have 0..4095 gray scales.

		float result = atan2(pB - pC, pA - pB);
		// result is between -pi and pi.
		// map it to be between 0 and 4095
		unsigned short quantizedValue = (result + PI) / (2 * PI) * 4095;
		dataOut[counter] = quantizedValue << 4;
	}
	return phaseImage;
}

void PTwrapper::frameCallback(myImage *pImage)
{
	triggered = true;
	numTrig++;
	trigsSinceBufferRead++;

	pImage->frameCounter = numTrig;
	int averagingIteration = (numTrig - 1) / averagingBlockSize;

	if (reconstructionMode)
	{
		// This mode assumes that the DMD gets three consequeitive phase shifted imageas (0,pi/2, 3*pi/2). 
		// the output will be the phase of the complex field. Values will be between 0..4095, but actually represent
		// the range of -PI..PI
		int averagingIteration3 = (numTrig - 1) / (averagingBlockSize * 3);

		int index3 = (numTrig - 1) % 3;
		TempImages[index3].DeepCopy(pImage);

		if (index3 == 2)
		{
			myImage *phaseImage = computePhase();
			// phase is now in phaseImage

			if (averagingIteration3 == 0)
			{
				imageQueue.push(phaseImage);
				averagingIterator = imageQueue.begin();
			}
			else
			{
				averageImages(*averagingIterator, phaseImage, averagingIteration3);
				delete phaseImage;

				averagingIterator++;
				if (averagingIterator == imageQueue.end())
					averagingIterator = imageQueue.begin();

			}


		}
		delete pImage;


	}
	else
	{
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
	}

	if (imageQueue.size() > maxImagesInBuffer)
	{
		myImage *p = imageQueue.front();
		delete p;
		imageQueue.pop();
	}

}


int PTwrapper::copyAndClearBuffer8Bit(unsigned char *imageBufferPtr, int N)
{
	lockMutex();
	int numToCopy = MIN(imageQueue.size(), N);
	int FirstImageTrig = (numToCopy > 0) ? (imageQueue.front())->frameCounter : -1;

	for (int k = 0; k<numToCopy; k++)
	{
		Image *I = imageQueue.front();
		unsigned char Pixel;
		unsigned char *data8bits = (unsigned char*)I->GetData();
		long long offset = ((long long)width*(long long)height*k);

		int counter = 0;
		for (long y = 0; y<height; y++)
		{
			for (long x = 0; x<width; x++)
			{

				Pixel = data8bits[counter];
				imageBufferPtr[offset + (long long)((y)+x*(long)height)] = Pixel;
				counter++;
			}
		}

		imageQueue.pop();
		delete I;
	}
	unlockMutex();
	return FirstImageTrig;
}

void PTwrapper::clearBuffer()
{
	lockMutex();
	int N = imageQueue.size();
	for (int k = 0; k < N; k++)
	{
		Image *p = imageQueue.front();
		delete p;
		imageQueue.pop();
	}
	unlockMutex();
}

int PTwrapper::copyBuffer16Bit(unsigned char *imageBufferPtr, int N)
{
	//        std::cout << *it << "\n";

	// copy the N-tuple images from the buffer, but keeps them there...
	// if an incomplete tuple exist, use the one before that...

	int startImage = N*(floor(imageQueue.size() / N) - 1);

	int numToCopy = MIN(imageQueue.size(), N);

	unsigned short *imageBufferIntPtr = (unsigned short *)imageBufferPtr;
	int tmp = sizeof(unsigned short);
	tmp = tmp;
	lockMutex();

	int cnt_in = 0;
	int cnt_out = 0;
	for (auto it = imageQueue.begin(); it != imageQueue.end(); it++)
	{
		if (cnt_in++ >= startImage)
		{
			if (cnt_out < numToCopy)
			{
				// copy image. store it in cnt_out
				Image *I = *it;
				unsigned short *data16bits = (unsigned short*)I->GetData();
				long long offset = ((long long)width*(long long)height*cnt_out);
				int counter = 0;
				for (long y = 0; y<height; y++)
				{
					for (long x = 0; x<width; x++)
					{

						unsigned short Pixel = data16bits[counter] >> 4; // move the upper 12 bit to the right, so we have 0..4095 gray scales.
						imageBufferIntPtr[offset + (long long)((y)+x*(long)height)] = Pixel;
						counter++;
					}
				}

				cnt_out++;
			}
		}

	}
	unlockMutex();
	return startImage;
}

int PTwrapper::copyAndClearBuffer16Bit(unsigned char *imageBufferPtr, int N)
{
	unsigned short *imageBufferIntPtr = (unsigned short *)imageBufferPtr;
	int tmp = sizeof(unsigned short);
	tmp = tmp;
	lockMutex();
	int numCopied = 0;

	int numToCopy = MIN(imageQueue.size(), N);
	int FirstImageTrig = (numToCopy > 0) ? (imageQueue.front())->frameCounter : -1;
	unsigned short Pixel = 0;
	for (long k = 0; k<numToCopy; k++)
	{
		Image *I = imageQueue.front();

		unsigned short *data16bits = (unsigned short*)I->GetData();
		long long offset = ((long long)width*(long long)height*k);

		int counter = 0;
		for (long y = 0; y<height; y++)
		{
			for (long x = 0; x<width; x++)
			{

				Pixel = data16bits[counter];
				Pixel = Pixel >> 4;	// move the upper 12 bit to the right, so we have 0..4095 gray scales.
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




int PTwrapper::pokeLastFrames(unsigned char *imageBufferPtr, int N)
{
	if (bytesPerPixel == 1)
		return -1; // TODO
	else if (bytesPerPixel == 2)
		return copyBuffer16Bit(imageBufferPtr, N);
	else
		return -1;

}

int PTwrapper::copyAndClearBuffer(unsigned char *imageBufferPtr, int N)
{
	trigsSinceBufferRead = 0;
	if (bytesPerPixel == 1)
		return copyAndClearBuffer8Bit(imageBufferPtr, N);
	else if (bytesPerPixel == 2)
		return copyAndClearBuffer16Bit(imageBufferPtr, N);
	else
		return -1;
}


int PTwrapper::getWidth()
{
	return width;
}

int PTwrapper::getHeight()
{
	return height;
}



float PTwrapper::getFrameRate()
{
	// Set Frame Rate
	Property framerateProp(FRAME_RATE);
	error = cam.GetProperty(&framerateProp);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return -1;
	}
	return framerateProp.absValue;
}


void PTwrapper::release()
{
	if (streaming)
	{
		// stop streaming...
		triggerEnabled = false;
		unlockMutex();
		Sleep(300); // wait for all threads to finish reading... (?)

		mexPrintf("Stopping capture...");
		error = cam.StopCapture();
		if (error != PGRERROR_OK)
		{
			printError(error);
		}
		streaming = false;
		mexPrintf("OK!\n");
	}
	Sleep(1000); // wait for all threads to finish writing... (?)


	if (initialized)
	{
		if (deviceOpened)
		{
			mexPrintf("Disconnecting camera...");
			error = cam.Disconnect();
			if (error != PGRERROR_OK)
			{
				printError(error);
			}
			mexPrintf("OK!\n");
		}

		mexPrintf("Closing mutex...");
		CloseHandle(ghMutex);
		mexPrintf("OK!\n");
		ghMutex = NULL;
		initialized = false;
	}
	mexPrintf("Release sequence finished!\n");
}


void OnImageGrabbed(Image* pImage, const void* pCallbackData)
{
	PTwrapper *cls = (PTwrapper*)pCallbackData;
	if (cls->triggerEnabled)
	{
		cls->lockMutex();
		myImage *deepcopy = new myImage;
		deepcopy->DeepCopy(pImage);
		cls->frameCallback(deepcopy);
		cls->unlockMutex();
	}
}




bool PTwrapper::init(int x0 = 0, int y0 = 0, int _width = 640, int _height = 480, int _mode = MODE_7)
{
	if (initialized)
		return true;

	FC2Version fc2Version;
	Utilities::GetLibraryVersion(&fc2Version);
	mexPrintf("FlyCapture2 library version: %d.%d.%d.%d\n", fc2Version.major, fc2Version.minor, fc2Version.type, fc2Version.build);

	mexPrintf("Quering number of cameras...");
	unsigned int numCameras;
	error = busMgr.GetNumOfCameras(&numCameras);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	if (numCameras == 0)
	{
		mexPrintf("No cameras detected\n");
		return false;
	}
	mexPrintf("%d cameras found.\n", numCameras);
	// Assume only one camera is connected....

	PGRGuid guid;
	error = busMgr.GetCameraFromIndex(0, &guid);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}

	// Connect to a camera
	mexPrintf("Connecting to camera...");

	error = cam.Connect(&guid);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	mexPrintf("OK\n");

	Sleep(500);

	// Set trigger
	mexPrintf("Setting external triggering mode...");

	TriggerMode triggerMode;     // Get current trigger settings
	error = cam.GetTriggerMode(&triggerMode);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}

	// Set camera to trigger mode 14 (overlapped)
	triggerMode.onOff = true;
	triggerMode.mode = 14;
	triggerMode.polarity = 1; // when line goes HIGH
	triggerMode.parameter = 0;
	triggerMode.source = 0;  // use GPIO 0
	error = cam.SetTriggerMode(&triggerMode);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	mexPrintf("OK\n");

	/*
	TriggerDelay delayParams;
	cam.GetTriggerDelay(&delayParams);
	delayParams.absValue = 0;
	cam.SetTriggerDelay(&delayParams, false);

	*/


	mexPrintf("Turning off auto exposure...");
	// Set Auto Exposure to OFF
	Property Prop(AUTO_EXPOSURE);
	error = cam.GetProperty(&Prop);
	Prop.autoManualMode = false;
	Prop.onOff = false;
	error = cam.SetProperty(&Prop);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	mexPrintf("OK\n");

	mexPrintf("Turning off auto gain...");
	// Set Auto Exposure to OFF
	Property gainProp(GAIN);
	error = cam.GetProperty(&gainProp);
	gainProp.autoManualMode = false;
	gainProp.onOff = false;
	error = cam.SetProperty(&gainProp);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	mexPrintf("OK\n");

	mexPrintf("Turning off gamma...");
	// Set Auto Exposure to OFF
	Property gammaProp(GAMMA);
	error = cam.GetProperty(&gammaProp);
	gammaProp.autoManualMode = false;
	gammaProp.onOff = false;
	error = cam.SetProperty(&gammaProp);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	mexPrintf("OK\n");


	bytesPerPixel = 2; // 12 bit ADC

	width = _width;
	height = _height;

	maxImagesInBuffer = (long)15 * 1e9 / (width*height*bytesPerPixel); // 15GB (!)
	mexPrintf("Allowing maximum 15GB of memory, or %d 16 bit images.\n", maxImagesInBuffer);


	// Set frame rate to maximum (?)
	// Set Imaging mode to high sensitivity, low read noise (mode 7)
	Format7ImageSettings fmt7ImageSettings;
	// MODE_0
	fmt7ImageSettings.mode = (Mode)_mode; // Low read noise mode (?)
	fmt7ImageSettings.height = height; //1200;
	fmt7ImageSettings.width = width; //1920;
	fmt7ImageSettings.offsetX = x0;
	fmt7ImageSettings.offsetY = y0;
	fmt7ImageSettings.pixelFormat = PIXEL_FORMAT_RAW16; // Packet size = 49680

	mexPrintf("Requesting resolution [%d x %d] with offset [%d x %d].\n", width, height, x0, y0);

	bool isValid;
	Format7PacketInfo fmt7PacketInfo;

	// Validate the settings to make sure that they are valid
	error = cam.ValidateFormat7Settings(&fmt7ImageSettings, &isValid, &fmt7PacketInfo);
	if (error != PGRERROR_OK || !isValid)
	{
		printError(error);
		return false;
	}


	mexPrintf("Setting format 7 configuration using %d packet size...", fmt7PacketInfo.recommendedBytesPerPacket);

	// Set the settings to the camera
	error = cam.SetFormat7Configuration(&fmt7ImageSettings, fmt7PacketInfo.recommendedBytesPerPacket);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	mexPrintf("OK\n");

	//error = cam.SetVideoModeAndFrameRate(VIDEOMODE_FORMAT7, FRAMERATE_FORMAT7); (?)


	deviceOpened = true;

	// Start capturing images
	mexPrintf("Starting capture...");
	error = cam.StartCapture(OnImageGrabbed, this);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return false;
	}
	mexPrintf("OK\n");


	bool use12Bits = true;

	streaming = true;
	initialized = true;
	mexPrintf("Camera initialized and in capture mode\n");
	return true;
}

PTwrapper::PTwrapper() : initialized(false), deviceOpened(false), streaming(false), triggered(false), numTrig(0), width(0), height(0), bytesPerPixel(2)
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

void PTwrapper::printStats()
{
	CameraStats stat;
	cam.GetStats(&stat);
	mexPrintf("Timestamp %d\n", stat.timeStamp);
	mexPrintf("Power is %d\n", stat.cameraPowerUp);
	mexPrintf("Num Corrupted %d\n", stat.imageCorrupt);
	mexPrintf("Driver Dropped %d\n", stat.imageDriverDropped);
	mexPrintf("Images Dropped %d\n", stat.imageDropped);
	mexPrintf("Temperature %d\n", stat.temperature);
	mexPrintf("Port Errors %d\n", stat.portErrors);

}



void PTwrapper::setTriggerMode(bool external)
{
	// Start capturing images
	mexPrintf("Stopping capture...");
	cam.StopCapture();

	// Set trigger
	if (external)
		mexPrintf("Setting external triggering mode...");
	else
		mexPrintf("Setting internal triggering mode...");

	TriggerMode triggerMode;     // Get current trigger settings
	error = cam.GetTriggerMode(&triggerMode);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return;
	}

	// Set camera to trigger mode 0 (why not 14?)
	triggerMode.onOff = external;
	triggerMode.mode = 14;
	triggerMode.polarity = 1; // when line goes HIGH
	triggerMode.parameter = 0;
	triggerMode.source = 0;  // use GPIO 0
	error = cam.SetTriggerMode(&triggerMode);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return;
	}


	error = cam.StartCapture(OnImageGrabbed, this);
	if (error != PGRERROR_OK)
	{
		printError(error);
		return;
	}
	mexPrintf("OK\n");

}

PTwrapper::~PTwrapper()
{
	release();
}



PTwrapper *camera = nullptr;


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
	if (mxGetString(prhs[0], Command, StringLength) != 0){
		mexErrMsgTxt("\nError extracting the command.\n");
		return;
	}
	else if (strcmp(Command, "Init") == 0) {
		mexAtExit(exitFunction);
		if (camera != nullptr)
			delete camera;

		camera = new PTwrapper();
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
		camera = new PTwrapper();

		int x0 = (int)*(double*)mxGetPr(prhs[1]);
		int y0 = (int)*(double*)mxGetPr(prhs[2]);

		int w = (int)*(double*)mxGetPr(prhs[3]);
		int h = (int)*(double*)mxGetPr(prhs[4]);
		int mode = MODE_7;
		if (nrhs > 4) {
			mode = (int)*(double*)mxGetPr(prhs[5]);
			mexPrintf("Using mode %d\n", mode);
		}
		bool Success = camera->init(x0, y0, w, h, mode);
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

		if (camera->getBytesPerPixel() == 1)
			imageBuffer = mxCreateNumericArray(3, dim, mxUINT8_CLASS, mxREAL);
		else if (camera->getBytesPerPixel() == 2)
			imageBuffer = mxCreateNumericArray(3, dim, mxUINT16_CLASS, mxREAL);

		if (imageBuffer == nullptr)
		{
			mexPrintf("Error allocating memory for buffer.\n");
		}

		unsigned char*imageBufferPtr = (unsigned char*)mxGetData(imageBuffer);

		plhs[0] = imageBuffer;
		plhs[1] = mxCreateDoubleScalar(camera->copyAndClearBuffer(imageBufferPtr, N));
	}
	else if (strcmp(Command, "PokeLastImageTuple") == 0) {
		if (nrhs < 1)
		{
			mexPrintf("Error - please specify tuple size.\n");
			return;
		}

		int w = camera->getWidth();
		int h = camera->getHeight();
		int requestedNumberOfImages = (int)*(double*)mxGetPr(prhs[1]);

		mwSize dim[3] = { h, w, requestedNumberOfImages };
		mxArray* imageBuffer;

		if (camera->getBytesPerPixel() == 1)
			imageBuffer = mxCreateNumericArray(3, dim, mxUINT8_CLASS, mxREAL);
		else if (camera->getBytesPerPixel() == 2)
			imageBuffer = mxCreateNumericArray(3, dim, mxUINT16_CLASS, mxREAL);

		unsigned char*imageBufferPtr = (unsigned char*)mxGetData(imageBuffer);

		int startFrame = camera->pokeLastFrames(imageBufferPtr, requestedNumberOfImages);
		plhs[0] = imageBuffer;
		plhs[1] = mxCreateDoubleScalar(startFrame);
	}
	else if (strcmp(Command, "PeekLastImage") == 0) {
		int w = camera->getWidth();
		int h = camera->getHeight();
		int N = camera->getNumImagesInBuffer();
		mwSize dim[3] = { h, w, N };
		mxArray* imageBuffer;

		if (camera->getBytesPerPixel() == 1)
			imageBuffer = mxCreateNumericArray(3, dim, mxUINT8_CLASS, mxREAL);
		else if (camera->getBytesPerPixel() == 2)
			imageBuffer = mxCreateNumericArray(3, dim, mxUINT16_CLASS, mxREAL);

		if (N > 0) {
			unsigned char*imageBufferPtr = (unsigned char*)mxGetData(imageBuffer);
			int startFrame = camera->pokeLastFrames(imageBufferPtr, 1);
			plhs[0] = imageBuffer;
			plhs[1] = mxCreateDoubleScalar(startFrame);
		}

	}


	else if (strcmp(Command, "SetExposure") == 0)
	{

		float exposureSec = (float)*(double*)mxGetPr(prhs[1]);
		float exposureMS = (float)exposureSec*1000.0;
		camera->setExposure(exposureMS);
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

		float exposureMS = (float)camera->getExposure();
		float exposureSec = (float)exposureMS / 1000.0;
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
	else  if (strcmp(Command, "getFrameRate") == 0)
	{
		plhs[0] = mxCreateDoubleScalar(camera->getFrameRate());
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

