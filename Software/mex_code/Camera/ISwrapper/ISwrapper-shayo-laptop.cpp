/*
The Image Source Matlab Wrapper
Programmed by Shay Ohayon
DiCarlo Lab @ MIT

Revision History
Version 0.1 7/11/2014  

*/
#include <stdio.h>
#include "mex.h"
#include "C:\Users\Shay\Documents\The Imaging Source Europe GmbH\TIS Grabber DLL\include\tisgrabber.h"
#include <Windows.h>
#include <queue>

#define MIN(a,b) (a)<(b)?(a):(b)

class Image {
public:
	Image();
	Image(const Image &I);
	Image(int _width, int _height, unsigned char *pRaw, unsigned long _frameNumber, int _bytesPerPixel);

	~Image();
	int width, height;
	unsigned long frameNumber;
	unsigned char *pData;
	int bytesPerPixel;
};

Image::Image(const Image &I)
{
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


Image::Image(int _width, int _height, unsigned char *pRaw, unsigned long _frameNumber, int _bytesPerPixel) : frameNumber(_frameNumber),width(_width),height(_height), bytesPerPixel(_bytesPerPixel)
{
	pData = new unsigned char[width*height*bytesPerPixel];
	if (pRaw == NULL)
	{
		for (int k=0;k<width*height*bytesPerPixel;k++)
			pData[k] = 0;
	} else
	{
		memcpy(pData,pRaw,width*height*bytesPerPixel);
		//for (int k=0;k<width*height*bytesPerPixel;k++)
		//	pData[k] = pRaw[k];
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
		bool init(char *deviceName, char *videoFormat);
		int getWidth();
		int getHeight();
		bool softwareTrigger();
		void frameCallback(HGRABBER hGrabber,unsigned char *pData,unsigned long frameNumber);
		void setGain(int value);
		long getGain();
		void setAutoExposure(bool value);
		bool getAutoExposure();
		int getNumImagesInBuffer();
		void setExposure(int value);
		long getExposure();
		int copyAndClearBuffer(unsigned char *imageBufferPtr, int N);
		int getBytesPerPixel();
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
	unsigned long numTrig;
	HANDLE ghMutex; 
	int width, height;
	int maxImagesInBuffer;
	std::queue<Image*> imageQueue;
};

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

void ISwrapper::setExposure(int value)
{
	//	long lMin, lMax, lValue;
	//IC_CameraPropertyGetRange(hGrabber, PROP_CAM_EXPOSURE, &lMin, &lMax);
	IC_SetCameraProperty(hGrabber, PROP_CAM_EXPOSURE, value);
	//printf("(%d - %d) %d", lMin, lMax, lValue );
}

long ISwrapper::getExposure()
{
	//	long lMin, lMax, lValue;
	//IC_CameraPropertyGetRange(hGrabber, PROP_CAM_EXPOSURE, &lMin, &lMax);
	long value;
	lastResult = IC_GetCameraProperty(hGrabber, PROP_CAM_EXPOSURE, &value);
	return value;
	//printf("(%d - %d) %d", lMin, lMax, lValue );
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


void ISwrapper::setGain(int value)
{
		//long lMin, lMax, lValue;
		//IC_VideoPropertyGetRange(hGrabber, PROP_VID_GAIN, &lMin, &lMax);
		//IC_GetVideoProperty(hGrabber, PROP_VID_GAIN, &lValue);
		IC_SetVideoProperty(hGrabber, PROP_VID_GAIN, value);
		//printf("(%d - %d) %d", lMin, lMax, lValue );
		//CheckCameraProperty(hGrabber, "Exposure    ",PROP_CAM_EXPOSURE);
}

long ISwrapper::getGain()
{
	long lValue;
	lastResult = IC_GetVideoProperty(hGrabber, PROP_VID_GAIN, &lValue);
	return lValue;
}

void ISwrapper::lockMutex()
{
       int dwWaitResult = WaitForSingleObject( 
            ghMutex,    // handle to mutex
            INFINITE);  // no time-out interval
}

void ISwrapper::unlockMutex()
{
	ReleaseMutex(ghMutex);
}

bool ISwrapper::softwareTrigger()
{
	return IC_SoftwareTrigger(hGrabber ) == IC_SUCCESS;
}


void ISwrapper::frameCallback(HGRABBER hGrabber,unsigned char *pData,unsigned long frameNumber)
{
	triggered = true;
	numTrig++;
    lockMutex();
	Image *pImage = new Image(640,480,pData, frameNumber,bytesPerPixel);
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
	int numToCopy = MIN(imageQueue.size(),N);
	for (int k=0;k<numToCopy;k++)
	{
		Image *I = imageQueue.front();
		int offset = (width*height*bytesPerPixel)*k;

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


int ISwrapper::copyAndClearBuffer16Bit(unsigned char *imageBufferPtr, int N)
{
	unsigned short *imageBufferIntPtr = (unsigned short *)imageBufferPtr;
	int tmp = sizeof(unsigned short);
	tmp=tmp;
	lockMutex();
	int numCopied = 0;
	int numToCopy = MIN(imageQueue.size(),N);
	unsigned short Pixel;
	for (int k=0;k<numToCopy;k++)
	{
		Image *I = imageQueue.front();
		int offset = (width*height*k);
		int counter = 0;
		for (int y=0;y<height;y++)
		{
			for (int x=0;x<width;x++)
			{
					memcpy( &Pixel, I->pData + counter,2);
					Pixel = Pixel >>4;	// move the upper 12 bit to the right, so we have 0..4095 gray scales.
	  			    imageBufferIntPtr[offset + (y)+x*height]=Pixel;
					counter+=2;
			}
		}
		imageQueue.pop();
		delete I;
	}
	unlockMutex();
	return numToCopy;
}

int ISwrapper::copyAndClearBuffer(unsigned char *imageBufferPtr, int N)
{
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
	cls->frameCallback(hGrabber, pData,frameNumber);
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

	if( IC_IsTriggerAvailable(hGrabber ) )
	{

		lastResult=IC_EnableTrigger(hGrabber,1);
		if (lastResult != 0 ) {
			release();
		return false;	
		}

		lastResult=IC_SetFrameReadyCallback (hGrabber,   *TriggerCallback,  (void*)this);
		if (lastResult != 0 ) {
			release();
		return false;	
		}

		lastResult=IC_SetContinuousMode(hGrabber,0);
		if (lastResult != 0 ) {
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
   return true;
}

ISwrapper::ISwrapper() : initialized(false), library_initialized(false),hGrabber(NULL),deviceOpened(false), streaming(false),triggered(false),numTrig(0)
{
	
    ghMutex = CreateMutex( 
        NULL,              // default security attributes
        FALSE,             // initially not owned
        NULL);             // unnamed mutex
	maxImagesInBuffer = 4096;

}

ISwrapper::~ISwrapper()
{
	release();
}


void ISwrapper::release()
{
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
	if (library_initialized)
	{
		IC_CloseLibrary();
		library_initialized = false;
	}
	CloseHandle(ghMutex);
	initialized = false;
}

 

ISwrapper *camera;

void mexFunction( int nlhs, mxArray *plhs[], 
				 int nrhs, const mxArray *prhs[] ) {

 int StringLength = int(mxGetNumberOfElements(prhs[0])) + 1;
 char* Command = new char[StringLength];
 if (mxGetString(prhs[0], Command, StringLength) != 0){
		mexErrMsgTxt("\nError extracting the command.\n");
		return;
} else if (strcmp(Command, "Init") == 0) {
	camera = new ISwrapper();
	bool Success = camera->init(NULL,NULL);
	 plhs[0] = mxCreateDoubleScalar(Success);
 } else if (strcmp(Command, "Release") == 0) {
	 delete camera;
	 camera = NULL;
	  mexPrintf("Camera handles released.\n");
 } else if (strcmp(Command,"GetImageBuffer") == 0) {
	 int N = camera->getNumImagesInBuffer();
	 int w = camera->getWidth();
	 int h = camera->getHeight();
	 mwSize dim[3] = {h,w,N};
	 mxArray* imageBuffer;

	 if (camera->getBytesPerPixel() == 1)
		imageBuffer =  mxCreateNumericArray(3, dim, mxUINT8_CLASS, mxREAL);
	 else if (camera->getBytesPerPixel() == 2)
		 imageBuffer =  mxCreateNumericArray(3, dim, mxUINT16_CLASS, mxREAL);
	
	 unsigned char*imageBufferPtr = (unsigned char*)mxGetData(imageBuffer);

	 camera->copyAndClearBuffer(imageBufferPtr, N);
	 plhs[0] = imageBuffer;
 } else if (strcmp(Command,"SetExposure") == 0)
 {
	 int exposure = (int) *(double*)mxGetPr(prhs[1]);
	 camera->setExposure(exposure);
 } else if (strcmp(Command,"GetExposure") == 0)
 {
	 plhs[0] = mxCreateDoubleScalar(camera->getExposure());
 } else if (strcmp(Command,"SetGain") == 0)
 {
	 int gain = (int) *(double*)mxGetPr(prhs[1]);
	 camera->setGain(gain);	
 } else if (strcmp(Command,"GetGain") == 0)
 {
	 plhs[0] = mxCreateDoubleScalar(camera->getGain());
 } else if (strcmp(Command,"GetBufferSize") == 0)
 {
	 plhs[0] = mxCreateDoubleScalar(camera->getNumImagesInBuffer());
 } else if  (strcmp(Command,"SoftwareTrigger") == 0)
 {
	camera->softwareTrigger();
 } else {
	 mexPrintf("Error. Unknown command\n");
 }

 delete Command;
 


}

