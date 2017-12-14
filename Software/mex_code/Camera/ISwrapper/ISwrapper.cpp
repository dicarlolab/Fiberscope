/*
The Image Source Matlab Wrapper
Programmed by Shay Ohayon
DiCarlo Lab @ MIT

Revision History
Version 0.1 7/11/2014  

*/
#include <stdio.h>
#include "mex.h"
#include "tisgrabber.h"
#include <Windows.h>
#include <queue>
#include <deque>

#define MIN(a,b) (a)<(b)?(a):(b)
#define MAX(a,b) (a)>(b)?(a):(b)
bool calledOnce = false;

template<typename T, typename Container=std::deque<T> >
class iterable_queue : public std::queue<T,Container>
{
public:
    typedef typename Container::iterator iterator;
    typedef typename Container::const_iterator const_iterator;

    iterator begin() { return this->c.begin(); }
    iterator end() { return this->c.end(); }
    const_iterator begin() const { return this->c.begin(); }
    const_iterator end() const { return this->c.end(); }
};
class Image {
public:
	Image();
	Image(const Image &I);
	Image(int _width, int _height, unsigned char *pRaw, unsigned long _frameNumber, unsigned long _frameNumberSinceBufferRead, int _bytesPerPixel);

	~Image();
	int width, height;
	unsigned long frameNumber;
	unsigned long frameNumberSinceBufferRead;
	unsigned char *pData;
	int bytesPerPixel;
};

Image::Image(const Image &I)
{
	frameNumberSinceBufferRead = I.frameNumberSinceBufferRead;
	width = I.width;
	height = I.height;
	frameNumber =I.frameNumber;
	bytesPerPixel = I.bytesPerPixel;
	pData = new unsigned char[I.width*I.height*bytesPerPixel];
	memcpy(pData,I.pData,width*height*bytesPerPixel);

}
Image::Image()
{
	pData = NULL;
}


Image::Image(int _width, int _height, unsigned char *pRaw, unsigned long _frameNumber, unsigned long _frameNumberSinceBufferRead, int _bytesPerPixel) : frameNumber(_frameNumber), width(_width), height(_height), bytesPerPixel(_bytesPerPixel), frameNumberSinceBufferRead(_frameNumberSinceBufferRead)
{
	pData = new unsigned char[width*height*bytesPerPixel];
	if (pRaw == NULL)
	{
		for (int k=0;k<width*height*bytesPerPixel;k++)
			pData[k] = 0;
	} else
	{
		memcpy(pData,pRaw,width*height*bytesPerPixel);
	}
}

Image::~Image()
{
	delete pData;
	pData = NULL;
}

class ISwrapper {
public:
		ISwrapper();
		~ISwrapper();
		bool isInitialized();
		bool init(char *deviceName, char *videoFormat);
		int getWidth();
		int getHeight();
		bool softwareTrigger();
		void frameCallback(HGRABBER hGrabber,unsigned char *pData,unsigned long frameNumber);
		void setGain(float value);
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

		unsigned long numTrig;
		bool triggerEnabled;

private:
	int copyAndClearBuffer8Bit(unsigned char *imageBufferPtr, int N);
	int copyAndClearBuffer16Bit(unsigned char *imageBufferPtr, int N);

	int bytesPerPixel;
	void release();
	void lockMutex();
	void unlockMutex();

	HGRABBER hGrabber;
	bool initialized;
	bool library_initialized;
	bool deviceOpened;
	bool streaming;
	int lastResult;
	bool triggered;
	HANDLE ghMutex; 
	int width, height;
	int maxImagesInBuffer;
	int mutexCount;
	unsigned long trigsSinceBufferRead;
	iterable_queue<Image*> imageQueue;
};

bool ISwrapper::isInitialized()
{
	return initialized;
}

void ISwrapper::setTrigger(bool state)
{
	triggerEnabled = state;
}

void ISwrapper::setFrameRate(float Rate)
{
	int RetVal = IC_SetFrameRate(hGrabber, Rate);
	bool success = RetVal == IC_SUCCESS;
}

float ISwrapper::getFrameRate()
{
	float rate = IC_GetFrameRate(hGrabber);
	return rate;
}

void ISwrapper::resetTriggerCounter()
{
	numTrig = 0;

}
int ISwrapper::getNumTrigs()
{
	return numTrig;
}
int ISwrapper::getBytesPerPixel()
{
	return bytesPerPixel;
}

int ISwrapper::getNumImagesInBuffer()
{
	int n;
	lockMutex();
	n = (int) imageQueue.size();
	unlockMutex();
	return n;
}

void ISwrapper::setExposure(float value)
{
//	IC_SetCameraProperty(hGrabber, PROP_CAM_EXPOSURE, value);
	IC_SetPropertyAbsoluteValue(hGrabber, "Exposure", "Value", value);

}

float ISwrapper::getExposure()
{
	//long value;
	float value;
	//lastResult = IC_GetCameraProperty(hGrabber, PROP_CAM_EXPOSURE, &value);
	lastResult = IC_GetPropertyAbsoluteValue(hGrabber, "Exposure", "Value", &value);
	assert(lastResult == IC_SUCCESS);
	value = MAX(0, value);
	return value;
}

void ISwrapper::setAutoExposure(bool value)
{
	IC_EnableAutoCameraProperty( hGrabber, PROP_CAM_EXPOSURE, value);
}


bool ISwrapper::getAutoExposure()
{
	int value;
	IC_GetAutoCameraProperty( hGrabber, PROP_CAM_EXPOSURE, &value);
	return value>0;
}


void ISwrapper::setGain(float value)
{
	IC_SetPropertyAbsoluteValue(hGrabber, "Gain", "Value",value);
	//IC_SetVideoProperty(hGrabber, PROP_VID_GAIN, value);
}

float ISwrapper::getGain()
{
	//long lValue;
	//lastResult = IC_GetVideoProperty(hGrabber, PROP_VID_GAIN, &lValue);
	float lValue;
	lastResult = IC_GetPropertyAbsoluteValue(hGrabber, "Gain","Value", &lValue);
	lValue = MIN(36.37, MAX(0, lValue));

	return lValue;
}




void CheckVideoProperty(HGRABBER hGrabber, char* szName, VIDEO_PROPERTY iProperty)
{
	mexPrintf("%s: ", szName);
	if (IC_IsVideoPropertyAvailable(hGrabber, iProperty))
	{
		long lMin, lMax, lValue;
		IC_VideoPropertyGetRange(hGrabber, iProperty, &lMin, &lMax);
		IC_GetVideoProperty(hGrabber, iProperty, &lValue);
		mexPrintf("(%d - %d) %d", lMin, lMax, lValue);

		if (IC_IsVideoPropertyAutoAvailable(hGrabber, iProperty))
		{
			int iOnOff;
			IC_GetAutoVideoProperty(hGrabber, iProperty, &iOnOff);
			if (iOnOff)
				mexPrintf(" Auto On");
			else
				mexPrintf(" Auto Off");
		}
	}
	else
	{
		printf("n/a");
	}
	printf("\n");

}


void ISwrapper::lockMutex()
{
	mutexCount++;
       int dwWaitResult = WaitForSingleObject( 
            ghMutex,    // handle to mutex
            INFINITE);  // no time-out interval
}

void ISwrapper::unlockMutex()
{
	ReleaseMutex(ghMutex);
	mutexCount--;
}

bool ISwrapper::softwareTrigger()
{
	return IC_SoftwareTrigger(hGrabber ) == IC_SUCCESS;
}


void ISwrapper::frameCallback(HGRABBER hGrabber,unsigned char *pData,unsigned long frameNumber)
{
	triggered = true;
	numTrig++;
	trigsSinceBufferRead++;
    lockMutex();
	Image *pImage = new Image(640, 480, pData, frameNumber, trigsSinceBufferRead,bytesPerPixel);

	imageQueue.push(pImage);
	if (imageQueue.size() > maxImagesInBuffer)
	{
		Image *p = imageQueue.front();
		delete p;
		imageQueue.pop();
	}
	unlockMutex();
}


int ISwrapper::copyAndClearBuffer8Bit(unsigned char *imageBufferPtr, int N)
{
	lockMutex();
	int numCopied = 0;
	int numToCopy =  MIN(imageQueue.size(),N);
	for (int k=0;k<numToCopy;k++)
	{
		Image *I = imageQueue.front();
		long long offset = (width*height*bytesPerPixel)*k;

		for (int y=0;y<height;y++)
		{
			for (int x=0;x<width;x++)
			{
				imageBufferPtr[offset + y+x*height]=I->pData[(height-y-1)*width+x];
			}
		}
		//memcpy(imageBufferPtr + (width*height*bytesPerPixel)*k,I->pData,width*height*bytesPerPixel);
		imageQueue.pop();
		delete I;
	}
	unlockMutex();
	return numToCopy;
}

void ISwrapper::clearBuffer()
{
	lockMutex();
	int M= imageQueue.size();
	for (int k = 0; k < M;k++)
	{
		Image *p = imageQueue.front();
		delete p;
		imageQueue.pop();
	}
	unlockMutex();
}

int ISwrapper::copyBuffer16Bit(unsigned char *imageBufferPtr, int N)
{
 //        std::cout << *it << "\n";

	// copy the N-tuple images from the buffer, but keeps them there...
	// if an incomplete tuple exist, use the one before that...

    int startImage =N*(floor(imageQueue.size()/N)-1);

	int numToCopy =  MIN(imageQueue.size(),N);

	unsigned short *imageBufferIntPtr = (unsigned short *)imageBufferPtr;
	int tmp = sizeof(unsigned short);
	tmp=tmp;
	lockMutex();

   int cnt_in=0;
   int cnt_out=0;
   for (auto it=imageQueue.begin(); it!=imageQueue.end();it++)
   {
	   if (cnt_in++ >= startImage)
	   {
		   if  (cnt_out < numToCopy)
		   {
			   // copy image. store it in cnt_out
			   Image *I = *it;
			   unsigned short *data16bits = (unsigned short*) I->pData;
			   long long offset = ((long long )width*(long long )height*cnt_out);
			   int counter = 0;
			   for (long y=0;y<height;y++)
			   {
				   for (long x=0;x<width;x++)
				   {

					   unsigned short Pixel = data16bits[counter] >> 4; // move the upper 12 bit to the right, so we have 0..4095 gray scales.
					   imageBufferIntPtr[offset + (long long)((y)+x*(long)height)]=Pixel;
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
int ISwrapper::copyAndClearBuffer16Bit(unsigned char *imageBufferPtr, int N)
{
	unsigned short *imageBufferIntPtr = (unsigned short *)imageBufferPtr;
	int tmp = sizeof(unsigned short);
	tmp=tmp;
	lockMutex();
	int numCopied = 0;
	
	int numToCopy = MIN(imageQueue.size(),N);
	
	unsigned short Pixel;
	for (long k=0;k<numToCopy;k++)
	{
		Image *I = imageQueue.front();

		long long offset = ((long long )width*(long long )height*k);

		int counter = 0;
		
		for (long y=0;y<height;y++)
		{
			for (long x=0;x<width;x++)
			{
					memcpy( &Pixel, I->pData + counter,2);
					Pixel = Pixel >>4;	// move the upper 12 bit to the right, so we have 0..4095 gray scales.
	  			    imageBufferIntPtr[offset + (long long)((y)+x*(long)height)]=Pixel;
					counter+=2;
			}
		}
		imageQueue.pop();
		delete I;
	}
	unlockMutex();
	return numToCopy;
}




int ISwrapper::pokeLastFrames(unsigned char *imageBufferPtr, int N)
{
	if (bytesPerPixel == 1)
		return -1; // TODO
	else if (bytesPerPixel == 2)
		return copyBuffer16Bit(imageBufferPtr,N);
	else
		return -1;

}
int ISwrapper::copyAndClearBuffer(unsigned char *imageBufferPtr, int N)
{
	trigsSinceBufferRead = 0;

	if (bytesPerPixel == 1)
		return copyAndClearBuffer8Bit(imageBufferPtr,N);
	else if (bytesPerPixel == 2)
		return copyAndClearBuffer16Bit(imageBufferPtr,N);
	else
		return -1;
}

void  _cdecl TriggerCallback(HGRABBER hGrabber, unsigned char* pData, unsigned long frameNumber, void* Data)
{
	ISwrapper *cls = (ISwrapper*)Data;
	if (cls->triggerEnabled) 
	{
		cls->numTrig = frameNumber;
		cls->frameCallback(hGrabber, pData, frameNumber);
	}
}

int ISwrapper::getWidth()
{
	return width;
}

int ISwrapper::getHeight()
{
	return height;
}

bool ISwrapper::init(char *deviceName, char *videoFormat)
{
	if (initialized)
		return true;

	char *szLicenseKey = NULL;
	library_initialized = IC_InitLibrary (szLicenseKey) == IC_SUCCESS;
	if (!library_initialized)
		return false;
	
	hGrabber = IC_CreateGrabber();
	if (hGrabber == NULL)
	{
		release();
		return false;
	}

	if (deviceName == NULL)
	{
		// Defualt device
		deviceOpened = IC_OpenVideoCaptureDevice(hGrabber, "DMK 23U618") == IC_SUCCESS;
    } else
	{
		deviceOpened = IC_OpenVideoCaptureDevice(hGrabber,deviceName) == IC_SUCCESS;
	}

	if (!deviceOpened) 
	{
		release();
		return false;
	}

	/*
	 char szFormatList[80][40];
    int iFormatCount = IC_ListVideoFormats(hGrabber, (char*)szFormatList,40 );
    for( int i = 0; i < iFormatCount; i++ )
    {
        printf("%2d. %s\n",i+1,szFormatList[i]);
    }
 */
	bool use12Bits = true;

	if (use12Bits)
	{
		IC_RemoveOverlay(hGrabber,0);	// Remove the Graphic Overlay
		lastResult = IC_SetFormat(hGrabber,Y16);		// Set memoryformat in the sink to 16 bit.
	} else
	{
		lastResult = IC_SetFormat  (hGrabber,  Y800 );
	}

	if (lastResult != IC_SUCCESS) {
		release();
		return false;
	}
  
	if (videoFormat == NULL)
	{	
		
		if (use12Bits)
		{
			bytesPerPixel = 2;		 
			lastResult = IC_SetVideoFormat  (hGrabber, "Y16 (640x480)" );
		} else
		{
			bytesPerPixel = 1;
			lastResult = IC_SetVideoFormat  (hGrabber, "Y800 (640x480)" );
		}
		 width = 640;
		 height = 480;
		 
		 
	} else
	{
		lastResult = IC_SetVideoFormat  (hGrabber, videoFormat );
	}

	if (lastResult != IC_SUCCESS ) {
		release();
		return false;	
	}


	int Res = IC_SetFrameRate(hGrabber, 120.0);
	float rate = IC_GetFrameRate(hGrabber);

	if( IC_IsTriggerAvailable(hGrabber ) )
	{

		lastResult=IC_EnableTrigger(hGrabber,1);
		if (lastResult != IC_SUCCESS) {
			release();
		return false;	
		}

		lastResult=IC_SetFrameReadyCallback (hGrabber,   *TriggerCallback,  (void*)this);
		if (lastResult != IC_SUCCESS) {
			release();
		return false;	
		}

		lastResult=IC_SetContinuousMode(hGrabber,0);
		if (lastResult != IC_SUCCESS) {
			release();
		return false;	
		}
		lastResult=IC_StartLive(hGrabber, 0 );
		if (lastResult != IC_SUCCESS )
		{
			release();
		return false;	
		}

		streaming = true;
	}

	initialized = true;


	CheckVideoProperty(hGrabber, "Brightness   ", PROP_VID_BRIGHTNESS);
	CheckVideoProperty(hGrabber, "Contrast/Gain", PROP_VID_CONTRAST);
	CheckVideoProperty(hGrabber, "Hue          ", PROP_VID_HUE);
	CheckVideoProperty(hGrabber, "Saturation   ", PROP_VID_SATURATION);
	CheckVideoProperty(hGrabber, "Sharpness    ", PROP_VID_SHARPNESS);
	CheckVideoProperty(hGrabber, "Gamma        ", PROP_VID_GAMMA);
	CheckVideoProperty(hGrabber, "Color enable ", PROP_VID_COLORENABLE);
	CheckVideoProperty(hGrabber, "White balance", PROP_VID_WHITEBALANCE);
	CheckVideoProperty(hGrabber, "Backlight    ", PROP_VID_BLACKLIGHTCOMPENSATION);
	CheckVideoProperty(hGrabber, "Gain         ", PROP_VID_GAIN);



   return true;
}

ISwrapper::ISwrapper() : initialized(false), library_initialized(false),hGrabber(NULL),deviceOpened(false), streaming(false),triggered(false),numTrig(0)
{
	
    ghMutex = CreateMutex( 
        NULL,              // default security attributes
        FALSE,             // initially not owned
        NULL);             // unnamed mutex
	maxImagesInBuffer = 25000; // 15GB (!)
	triggerEnabled = true;
	trigsSinceBufferRead = 0;
	mutexCount = 0;

}

ISwrapper::~ISwrapper()
{
	release();
}


void ISwrapper::release()
{
	lockMutex();
	if (streaming)
	{
		IC_StopLive (hGrabber);
		streaming = false;
	}
	if (hGrabber != NULL)
	{
		if (deviceOpened) {
			IC_CloseVideoCaptureDevice( hGrabber );
			deviceOpened = false;
		}
		 IC_ReleaseGrabber(&hGrabber);   
		 hGrabber = NULL;
	}
	if (library_initialized )
	{
		IC_CloseLibrary();
	//	calledOnce = true;
		library_initialized = false;

	}
	CloseHandle(ghMutex);
	initialized = false;
}

 
void test()
{
char *szLicenseKey = NULL;
 IC_InitLibrary(szLicenseKey);
IC_CloseLibrary();
IC_InitLibrary(szLicenseKey);
IC_CloseLibrary();
}

ISwrapper *camera=nullptr;


void exitFunction()
{
	if (camera != nullptr)
		delete camera;
}

void mexFunction( int nlhs, mxArray *plhs[], 
				 int nrhs, const mxArray *prhs[] ) {


 int StringLength = int(mxGetNumberOfElements(prhs[0])) + 1;
 char* Command = new char[StringLength];
 if (mxGetString(prhs[0], Command, StringLength) != 0){
		mexErrMsgTxt("\nError extracting the command.\n");
		return;
} else if (strcmp(Command, "Init") == 0) {
	 mexAtExit(exitFunction);
	 if (camera != nullptr)
		 delete camera;

	camera = new ISwrapper();
	bool Success = camera->init(NULL,NULL);
	 plhs[0] = mxCreateDoubleScalar(Success);
	 delete Command;

	 return;
 } 

 if (strcmp(Command, "IsInitialized") == 0) {
	 if (camera==nullptr)
		plhs[0] = mxCreateDoubleScalar(false);
	 else
		 plhs[0] = mxCreateDoubleScalar(camera->isInitialized());
	 return;
 }

 if (camera == nullptr)
 {
	 mexErrMsgTxt("You need to call Initialize first!.\n");
	 delete Command;
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
 } else if (strcmp(Command,"GetImageBuffer") == 0) {
	 int N = camera->getNumImagesInBuffer();

	 if (nrhs > 1)
	 {
		 // grab a subset of images
		int requestedNumberOfImages = (int)*(double*)mxGetPr(prhs[1]);
		N = MIN(N, requestedNumberOfImages);
	 }

	 int w = camera->getWidth();
	 int h = camera->getHeight();
	 mwSize dim[3] = {h,w,N};
	 mxArray* imageBuffer;

	 if (camera->getBytesPerPixel() == 1)
		imageBuffer =  mxCreateNumericArray(3, dim, mxUINT8_CLASS, mxREAL);
	 else if (camera->getBytesPerPixel() == 2)
		 imageBuffer =  mxCreateNumericArray(3, dim, mxUINT16_CLASS, mxREAL);
	
	 if (imageBuffer == nullptr)
	 {
		 mexPrintf("Error allocating memory for buffer.\n");
	 }

	 unsigned char*imageBufferPtr = (unsigned char*)mxGetData(imageBuffer);
	 
	 camera->copyAndClearBuffer(imageBufferPtr, N);
	 plhs[0] = imageBuffer;
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

	 int startFrame = camera->pokeLastFrames(imageBufferPtr,requestedNumberOfImages );
	 plhs[0] = imageBuffer;
	 plhs[1] = mxCreateDoubleScalar(startFrame);
 }
 
 
 else if (strcmp(Command, "SetExposure") == 0)
 {

	 float exposure = *(double*)mxGetPr(prhs[1]);
	 camera->setExposure(exposure);
	 plhs[0] = mxCreateDoubleScalar(1);
 } else if (strcmp(Command,"GetExposure") == 0)
 {

	 plhs[0] = mxCreateDoubleScalar(camera->getExposure());
 } else if (strcmp(Command,"SetGain") == 0)
 {
	 float gain = *(double*)mxGetPr(prhs[1]);
	 camera->setGain(gain);	
	 plhs[0] = mxCreateDoubleScalar(1);
 } else if (strcmp(Command,"GetGain") == 0)
 {
	 plhs[0] = mxCreateDoubleScalar(camera->getGain());
 } else if (strcmp(Command,"GetBufferSize") == 0)
 {
	 plhs[0] = mxCreateDoubleScalar(camera->getNumImagesInBuffer());
 } else if  (strcmp(Command,"SoftwareTrigger") == 0)
 {
	camera->softwareTrigger();
	plhs[0] = mxCreateDoubleScalar(1);
 } else  if (strcmp(Command, "ClearBuffer") == 0)
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

