#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "..\tisgrabber.h"
#include "windows.h"



//////////////////////////////////////////////////////////////////////////
/*!
*/
void OpenDeviceAndShowLiveVideo()
{
	HGRABBER hGrabber; // The handle of the grabber object.

	printf("ANSI C Grabber Sample: Devices and Serial Numbers\n");

	hGrabber = IC_ShowDeviceSelectionDialog(NULL);
	if( hGrabber )
	{
		IC_StartLive(hGrabber,1);
		printf("Press any key to stop the live video\n" );
		_getch();
		IC_StopLive(hGrabber);

		IC_ReleaseGrabber(&hGrabber);
	}
}


//////////////////////////////////////////////////////////////////////////
/*!
*/
void DevicesAndSerialNumbers()
{
	int i;
	int iDeviceCount;
	char szSerialNumber[20];
	int TempSerial;

	HGRABBER hGrabber; // The handle of the grabber object.

	printf("ANSI C Grabber Sample: Devices and Serial Numbers\n");

	// Count the connected devices and
	iDeviceCount = IC_GetDeviceCount();
	printf("Devices connected: %2d \n",iDeviceCount);

	for( i = 0; i < iDeviceCount; i++ )
	{
		hGrabber = IC_CreateGrabber();
		IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(i) );
		IC_GetSerialNumber(hGrabber, szSerialNumber);
		TempSerial = atoi( szSerialNumber);
		sprintf(szSerialNumber,"%08X",TempSerial);
		IC_ReleaseGrabber(&hGrabber);
		printf("%2d. %s  Serial %s\n",i+1,IC_GetDevice(i),szSerialNumber );
	}
}



//////////////////////////////////////////////////////////////////////////
/*! This functions opens a video capture devices, shows its properties.
	
*/
void ShowProperties()
{
	HGRABBER hGrabber; // The handle of the grabber object.
	int iInputChannels;
	int iVideoFormats;
	int i;

	printf("ANSI C Grabber Sample\n");

	hGrabber = IC_ShowDeviceSelectionDialog(NULL); // Show the built in device select dialog
	if( hGrabber )            
	{

		iVideoFormats = IC_GetVideoFormatCount(hGrabber);
		for( i = 0; i < iVideoFormats; i++ )
		{
			printf("%2d. %s\n",i+1,IC_GetVideoFormat(hGrabber,i));
		}

		iInputChannels = IC_GetInputChannelCount(hGrabber);

		printf("%d Input channels\n",iInputChannels);

		for( i = 0; i < iInputChannels; i++ )
		{
			printf("%2d. %s\n",i, IC_GetInputChannel(hGrabber, i));
		}

		for( i = 0; i < IC_GetVideoNormCount(hGrabber); i++ )
		{
			printf("%2d. %s\n",i, IC_GetVideoNorm(hGrabber,i));
		}

		IC_ReleaseGrabber( &hGrabber );
	}
}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void ShowandSaveProperties()
{
	HGRABBER hGrabber; // The handle of the grabber object.

	printf("ANSI C Grabber Sample\n");

	hGrabber = IC_ShowDeviceSelectionDialog(NULL); // Show the built in device select dialog
	if( hGrabber )            
	{
		// Show the built in property dialog.
		IC_ShowPropertyDialog(hGrabber);
		// Save the current properties intn an XML file.
		IC_SaveDeviceStateToFile(hGrabber, "device.xml");
		
		IC_ReleaseGrabber( &hGrabber );
	}
}

//////////////////////////////////////////////////////////////////////////
/*! This function opens a video capture device, snaps an images and saves it
	as jpeg.
	Then 10 images are snapped and the first 15 bytes of each image are displayed.
*/
void ImageProcessing()
{
	int i,p;
	HGRABBER hGrabber; // The handle of the grabber object.
	unsigned char *pImageData = NULL;

	printf("ANSI C Grabber Sample\n");

	hGrabber = IC_ShowDeviceSelectionDialog(NULL); // Show the built in device select dialog
	if( hGrabber )            
	{
		IC_StartLive(hGrabber, 1);
		IC_SnapImage(hGrabber, 2000);                           // Snap a frame into memory
		IC_SaveImage(hGrabber, "Test.jpg",FILETYPE_JPEG,90);    // Save the snapped frame to harddisk

		// Snap 10 images and display the contents of the first 15 bytes of
		// each image.
		for( i = 0; i < 10; i++ )
		{
			if( IC_SnapImage(hGrabber, 200) == IC_SUCCESS )
			{
				pImageData = IC_GetImagePtr(hGrabber );
				if( pImageData != NULL )
				{
					for( p = 0; p < 15; p++)
					{
						printf("%2X ",pImageData[p]);
					}
					printf("\n");
				}
			}
		}

		IC_StopLive( hGrabber );

		IC_ReleaseGrabber( &hGrabber ); 
	}
}


//////////////////////////////////////////////////////////////////////////
/*! This functions shows, how to check, whether a video capture device is already
	in use.
*/
void CheckDevice()
{
	int i,o;
	int iDeviceCount;
	char szUniqueName[121];
	HGRABBER Grabbers[10];
	int iFound = 0;

	for( i = 0; i < 10; i++ )				// Create some grabber objects for testing this function
	{
		Grabbers[i] = IC_CreateGrabber();
	}
	IC_OpenVideoCaptureDevice(  Grabbers[5], "DFK 21F04" );
	if( !IC_IsDevValid(Grabbers[5]))  printf("Failed to open test device.\n");

	iDeviceCount = IC_GetDeviceCount();			// Count the connected video capture devices
	for( i = 0; i < iDeviceCount; i++ )
	{
		printf("Device %s\nUnique Name : %s\n\n",IC_GetDevice(i),IC_GetUniqueNamefromList(i));

		for( o = 0; o < 10 && iFound == 0; o++)
		{
			if( IC_IsDevValid(Grabbers[o]))
			{
				if( IC_GetUniqueName(Grabbers[o], szUniqueName,120) == IC_SUCCESS)
				{
					if( strcmp( IC_GetUniqueNamefromList(i) , szUniqueName) == 0 )
					{
						printf("Device already in use. (Grabber %d)\n",o);
						iFound = 1;
					}
				}
			}
		}
	}

	for( i = 0; i < 10; i++ )				// Create some grabber objects for testing this function
	{
		 IC_ReleaseGrabber(&Grabbers[i]);
	}
}



//////////////////////////////////////////////////////////////////////////
/*!
*/
void CheckVideoProperty(HGRABBER hGrabber, char* szName, int iProperty )
{
	printf("%s: ", szName);
	if( IC_IsVideoPropertyAvailable(hGrabber, iProperty))
	{
		long lMin, lMax, lValue;
		IC_VideoPropertyGetRange(hGrabber, iProperty, &lMin, &lMax);
		IC_GetVideoProperty(hGrabber, iProperty, &lValue);
		printf("(%d - %d) %d", lMin, lMax, lValue );

		if( IC_IsVideoPropertyAutoAvailable(hGrabber, iProperty ) )
		{
			int iOnOff;
			IC_GetAutoVideoProperty(hGrabber, iProperty, &iOnOff);
			if( iOnOff)
				printf(" Auto On");
			else
				printf(" Auto Off");
		}
	}
	else
	{
		printf("n/a");
	}
	printf("\n");

}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void CheckCameraProperty(HGRABBER hGrabber, char* szName, int iProperty )
{
	printf("%s: ", szName);
	if( IC_IsCameraPropertyAvailable(hGrabber, iProperty))
	{
		long lMin, lMax, lValue;
		IC_CameraPropertyGetRange(hGrabber, iProperty, &lMin, &lMax);
		IC_GetCameraProperty(hGrabber, iProperty, &lValue);
		printf("(%d - %d) %d", lMin, lMax, lValue );

		if( IC_IsCameraPropertyAutoAvailable(hGrabber, iProperty ) )
		{
			int iOnOff;
			IC_GetAutoCameraProperty( hGrabber, iProperty, &iOnOff);
			if( iOnOff)
				printf(" Auto On");
			else
				printf(" Auto Off");
		}
	}
	else
	{
		printf("n/a");
	}
	printf("\n");

}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void PropertyCheck2()
{
	long lMin, lMax, lValue, i;
	int On;
	COLORFORMAT cf;
	HGRABBER hGrabber = IC_CreateGrabber();
	hGrabber = IC_ShowDeviceSelectionDialog(NULL);    

	//IC_GetDeviceCount();
	//IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));
	IC_PrepareLive(hGrabber, 1);
	IC_GetImageDescription(hGrabber, &lMin, &lMax, &lValue, &cf);
	printf("Image Width %d, Height %d, Bits per pixel %d, Colorformat %d\n",lMin, lMax, lValue, cf);

	CheckVideoProperty(hGrabber, "Brightness   ",PROP_VID_BRIGHTNESS );
	CheckVideoProperty(hGrabber, "Contrast/Gain",PROP_VID_CONTRAST );
	CheckVideoProperty(hGrabber, "Hue          ",PROP_VID_HUE );
	CheckVideoProperty(hGrabber, "Saturation   ",PROP_VID_SATURATION );
	CheckVideoProperty(hGrabber, "Sharpness    ",PROP_VID_SHARPNESS );
	CheckVideoProperty(hGrabber, "Gamma        ",PROP_VID_GAMMA );
	CheckVideoProperty(hGrabber, "Color enable ",PROP_VID_COLORENABLE );
	CheckVideoProperty(hGrabber, "White balance",PROP_VID_WHITEBALANCE );
	CheckVideoProperty(hGrabber, "Backlight    ",PROP_VID_BLACKLIGHTCOMPENSATION );
	CheckVideoProperty(hGrabber, "Gain         ",PROP_VID_GAIN );

	CheckCameraProperty(hGrabber, "Pan         ",PROP_CAM_PAN );
	CheckCameraProperty(hGrabber, "Tilt        ",PROP_CAM_TILT);
	CheckCameraProperty(hGrabber, "Roll        ",PROP_CAM_ROLL);
	CheckCameraProperty(hGrabber, "Zoom        ",PROP_CAM_ZOOM);
	CheckCameraProperty(hGrabber, "Exposure    ",PROP_CAM_EXPOSURE);
	CheckCameraProperty(hGrabber, "Iris        ",PROP_CAM_IRIS);
	CheckCameraProperty(hGrabber, "Focus       ",PROP_CAM_FOCUS);    

	IC_EnableAutoCameraProperty(hGrabber, PROP_CAM_EXPOSURE, 1); // Enable autoexposure


/*
	IC_GetExpRegValRange(hGrabber, &lMin, &lMax);
	IC_GetExpRegVal(hGrabber, &lValue);

	printf("Register Values : (%d - %d) %d\n", lMin, lMax, lValue);

	IC_EnableExpRegValAuto(hGrabber,  0 ); // Enable autoexposure
	IC_StartLive(hGrabber, 1);
	for( i = lMin; i < lMax; i+=10 )
	{
		IC_SetExpRegVal(hGrabber, i);
		Sleep( 10 );
	}






	printf("Press any key to continue\n");
	_getch();

	IC_SetExpRegVal(hGrabber, lMin );
	printf("Press any key to continue\n");
	_getch();
	IC_EnableExpRegValAuto(hGrabber,  1 ); // Enable autoexposure

	IC_GetExpRegValAuto(hGrabber,  &On );
	printf("Auto : %d\n", On);
	printf("Press any key to continue\n");
	_getch();
	*/


	IC_StopLive(hGrabber );

	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}



//////////////////////////////////////////////////////////////////////////
/*!
*/
void TestAbsoluteValues()
{
	float fMin, fMax, fValue;
	HGRABBER hGrabber = IC_CreateGrabber();
	IC_GetDeviceCount();
	IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));
	printf("Video format width %d, height %d\n",IC_GetVideoFormatWidth(hGrabber), IC_GetVideoFormatHeight(hGrabber));
	IC_SetFormat(hGrabber, RGB24);

	IC_StartLive(hGrabber,1);

	printf("Testing Absolute Values interface\n");
	if( IC_IsExpAbsValAvailable(hGrabber) )
	{
		IC_GetExpAbsValRange(hGrabber,&fMin,&fMax);
		printf("Absolute Values are available!%f - %f\n",fMin,fMax);

		printf("Sec:");
		scanf("%f", &fValue);
		IC_SetExpAbsVal(hGrabber, fValue );

		printf("Sec:");
		scanf("%f", &fValue);
		IC_SetExpAbsVal(hGrabber, fValue );

		printf("Sec:");
		scanf("%f", &fValue);
		IC_SetExpAbsVal(hGrabber, fValue );
	}
	else
	{
		printf("not available.\n");
	}


	IC_StopLive(hGrabber );

	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}
void Test3()
{
	HGRABBER hGrabber = IC_CreateGrabber();
	/*
	IC_GetDeviceCount();
	IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));
	printf("Video format width %d, height %d\n",IC_GetVideoFormatWidth(hGrabber), IC_GetVideoFormatHeight(hGrabber));
	IC_SetFormat(hGrabber, RGB24);

	IC_StartLive(hGrabber,1);
	IC_StopLive(hGrabber);
	IC_CloseVideoCaptureDevice(hGrabber);*/
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}


typedef struct SSICGrab SICGrab;
struct SSICGrab{

	HGRABBER hGrabber;
	int iDeviceCount;
	int iHeight;
	int iWidth;
	int iBitsPerPixel;  
	unsigned char *pucImageData;
	COLORFORMAT     ColorFormat;
	int iProcessing;
};

// Testfuction
void CallbackTest(); 
// the Callbackfunction
void _cdecl  callback(HGRABBER hGrabber, unsigned char* pData, unsigned long frameNumber, void*);

void  _cdecl callback(HGRABBER hGrabber, unsigned char* pData, unsigned long frameNumber, void* Data)
{
	SICGrab *psICGrabCB;
	psICGrabCB = (SICGrab *)Data;
	printf("callback called \n");
	if(!psICGrabCB->iProcessing)
	{
		psICGrabCB->iProcessing = 1;
		printf("callback processing \n");
		Sleep(1000);
		psICGrabCB->iProcessing = 0;
	}    
}


//////////////////////////////////////////////////////////////////////////
/*!
*/
void CallbackTest()
{
	int error = 0;
	int iResult  = 0;

	SICGrab *psICGrab;

	psICGrab = (SICGrab*)calloc(1,sizeof(SICGrab));
	psICGrab->hGrabber = IC_ShowDeviceSelectionDialog(NULL);    
	if(psICGrab->hGrabber)
	{
		iResult =   IC_SetFrameReadyCallback (psICGrab->hGrabber,   *callback,  psICGrab);
		IC_SetFormat(psICGrab->hGrabber, Y800);
		IC_SetContinuousMode(psICGrab->hGrabber,0);
		IC_StartLive(psICGrab->hGrabber,0);
	}    

	while (!kbhit()) 
	{
	}


	//if still open -> sto and release grabber
	if(psICGrab->hGrabber)
	{
		IC_StopLive(psICGrab->hGrabber);
		IC_CloseVideoCaptureDevice(psICGrab->hGrabber);
		IC_ReleaseGrabber(&psICGrab->hGrabber);
	}
}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void GetImageDescriptionSample()
{
	HGRABBER hGrabber = IC_CreateGrabber();
	//long lMin, lMax, lValue;
	//COLORFORMAT cf;
	unsigned char* ImagePointer;
	int p;

	IC_GetDeviceCount();
	IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));

//	printf("Video format width %d, height %d\n",IC_GetVideoFormatWidth(hGrabber), IC_GetVideoFormatHeight(hGrabber));
//	IC_SetFormat(hGrabber, RGB24);


	IC_PrepareLive(hGrabber, 1);
//	IC_GetImageDescription(hGrabber, &lMin, &lMax, &lValue, &cf);
//	printf("Image Width %d, Height %d, Bitsperpixel %d, Colorformat %d\n",lMin, lMax, lValue, cf);

	IC_StartLive( hGrabber, 0 );
	IC_SnapImage(hGrabber, -1);  // timeout in ms; -1 = ohne timeout
	ImagePointer = IC_GetImagePtr(hGrabber); //IC_GetImagePtr 

	if( ImagePointer != NULL )
	{
		for( p = 0; p < 15; p++)
		{
			printf("%2X ",ImagePointer[p]);
		}
		printf("\n");
	}
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}



//////////////////////////////////////////////////////////////////////////
/*!
*/
void DrawOverlay()
{
	HDC hPaintDC;
	HGRABBER hGrabber = IC_CreateGrabber();
	IC_GetDeviceCount();
	IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));
	IC_SetFormat(hGrabber, RGB24);

	IC_StartLive(hGrabber,1);


	IC_EnableOverlay( hGrabber,1 );

	hPaintDC = (HDC)IC_BeginPaint(hGrabber); 

	if(hPaintDC != NULL)
	{
		HPEN PenHandle = CreatePen(PS_SOLID, 1, RGB(0, 0, 255));// nur Blau
		PenHandle = SelectObject(hPaintDC, PenHandle);

		MoveToEx(hPaintDC, 100,150,NULL);
		LineTo(hPaintDC, 200,300);

		DeleteObject( hPaintDC );
	}
	IC_EndPaint(hGrabber);





	_getch();
	IC_StopLive(hGrabber );

	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void ChangeInputChannels()
{
	HGRABBER hGrabber = IC_CreateGrabber();
	int iInputChannels;
	int i;
	IC_GetDeviceCount();
	IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));
	IC_SetVideoNorm(hGrabber,"PAL-B");
	IC_SetVideoFormat(hGrabber,"UYVY (640x480)");
	IC_SetFormat(hGrabber, RGB24);

	IC_StartLive(hGrabber,1);

	iInputChannels = IC_GetInputChannelCount(hGrabber);

	for( i = 0; i < iInputChannels; i++)
	{
		IC_SetInputChannel(hGrabber, IC_GetInputChannel(hGrabber, i));
		printf("Channel : %s\nPess any key for next channel.\n",IC_GetInputChannel(hGrabber, i));
		_getch();
	}

	IC_StopLive(hGrabber );

	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void SetTrigger()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);    
	//int iInputChannels;
	//int i;
	//IC_GetDeviceCount();
	//IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));

	if( IC_IsTriggerAvailable(hGrabber) == IC_SUCCESS )
	{
		IC_EnableTrigger(hGrabber,0);
		IC_StartLive(hGrabber,1);

		printf("Untriggered, there should be new images\n");

		printf("Press any key to continue!\n");
		_getch();

		IC_StopLive(hGrabber );


		IC_EnableTrigger(hGrabber,1);
		IC_StartLive(hGrabber,1);

		printf("Triggered, there should be new images only if a trigger pulse occurred\n");

		printf("Press any key to continue!\n");
		_getch();

		IC_StopLive(hGrabber );

		IC_EnableTrigger(hGrabber,0);
	}
	else
	{
		printf("The device does not support triggering!\n");
	}

	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}

/////////////////////////////////////////////////////////////////////////////////
//
void ColorEnhancementSample()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	int OnOff;
	int Error;
	int i;

	printf("Colorenhancement Property Sample\n");
	IC_StartLive(hGrabber,1);

	Error = IC_GetColorEnhancement(hGrabber, &OnOff);
	if(Error == IC_SUCCESS)
	{
		printf("Property is available, value is %d\n", OnOff );
		for(  i = 0; i < 5; i++ )
		{
			printf("Press any key to toggle color enhancement\n");
			_getch();
			if( OnOff == 1 )
			{
				IC_SetColorEnhancement(hGrabber,0 );
			}
			else
			{
				IC_SetColorEnhancement(hGrabber,1 );
			}
			IC_GetColorEnhancement(hGrabber, &OnOff);
			printf("Value is now %d\n", OnOff );
		}
	}
	else
	{
		printf("Erro %d occurred\n");
	}


	IC_StopLive(hGrabber);
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void SetColorEnhancementDFx51()
{
	HGRABBER hGrabber;
	if( IC_InitLibrary(0) )
	{
		hGrabber = IC_CreateGrabber();
		IC_OpenVideoCaptureDevice( hGrabber,"DFx 51AUC03");
		IC_SetColorEnhancement(hGrabber,1 );
		IC_ReleaseGrabber(&hGrabber);
		IC_CloseLibrary();
	}
}


//////////////////////////////////////////////////////////////////////////
/*!
*/
void  _cdecl TriggerCallback(HGRABBER hGrabber, unsigned char* pData, unsigned long frameNumber, void* Data)
{
	int *pImageReceived;
	pImageReceived = (int*) Data;
	*pImageReceived = 1;
	printf("Callback called.\n");
}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void SoftwareTrigger()
{
	int ImageReceived; // Flag that is set in the callback to 1 if an image is received.
	int Tries;

	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   

	if( IC_IsTriggerAvailable(hGrabber ) )
	{
		IC_EnableTrigger(hGrabber,1);

		IC_SetFrameReadyCallback (hGrabber,   *TriggerCallback,  (void*)&ImageReceived);
		IC_SetContinuousMode(hGrabber,0);

		IC_StartLive(hGrabber, 1 );
		
		ImageReceived = 0; // Set the flag for image received to 0;
		Tries = 20;			// Tries for time out. Depends on the Sleep time and the frame rate.

		printf("Press a key to push software trigger.\n");
		_getch();

		printf("Software trigger triggered.\n");
		if( IC_SoftwareTrigger(hGrabber) == IC_SUCCESS )
		{
			// Check, whether we got an image
			while(Tries > 0 && ImageReceived == 0)
			{
				Sleep( 10 );
				Tries--;
			}

			if( ImageReceived == 1 )
			{
				printf("Got an image.\n");
			}
			else
			{
				printf("Sorry, we got no image. Try again later.\n");
			}
		}
		else
		{
			printf("Error at software trigger\n");
		}


		IC_StopLive(hGrabber);
	}
	
	IC_CloseLibrary();
}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void FrameRate()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   

	printf("%f\n",IC_GetFrameRate(hGrabber));
	IC_SetFrameRate(hGrabber,10.0f);

	printf("%f\n",IC_GetFrameRate(hGrabber));
	IC_SetFrameRate(hGrabber,60.0f);

	printf("%f\n",IC_GetFrameRate(hGrabber));
	IC_CloseLibrary();
}

void ShowInternalPropertyDialog()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	IC_ShowInternalPropertyPage(hGrabber);
}


void ResetProperties()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	if( IC_IsDevValid(hGrabber) )
	{
		IC_ResetProperties(hGrabber);
	}
}



//////////////////////////////////////////////////////////////
//
void  _cdecl DeviceLost(HGRABBER hGrabber, void* Param)
{
	int* pDeviceLost;
	pDeviceLost = (int*) Param;
	*pDeviceLost = 0;
}

void DeviceLostSample()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	int DeviceConnected = 0;
	char DeviceName[255];

	if( IC_IsDevValid(hGrabber) )
	{
		strcpy(DeviceName, IC_GetDeviceName(hGrabber)); // Save the name of the device, we use.
		DeviceConnected = 1;
		// The following call sets a device lost callbac only, declared above.
		// the parameter "DeviceConnected" will be set to 0 in the callback function.
		// In case, frameReady callbacks are to be handled too, please pass the
		// callback function address to the first "NULL" and the user parameters
		// to the second "NULL"
		IC_SetCallbacks( hGrabber, NULL, NULL, *DeviceLost ,&DeviceConnected);
		IC_StartLive(hGrabber,1);

		while (!kbhit() ) 
		{
			if( DeviceConnected == 0 )
			{
				IC_CloseVideoCaptureDevice(hGrabber); 
				
				
				IC_OpenVideoCaptureDevice(hGrabber, DeviceName );

				if( IC_IsDevValid(hGrabber) )
				{
					IC_StartLive(hGrabber,1);
					DeviceConnected = 1;
				}
				else
				{
					printf("No Device\n");
					Sleep(1000);
				}
			}
		}

		if(hGrabber)
		{
			IC_StopLive(hGrabber);
			IC_CloseVideoCaptureDevice(hGrabber);
			IC_ReleaseGrabber(&hGrabber);
		}
	}
}


//////////////////////////////////////////////////////////////////
// Test function for one push focus.

void FocusOnePush()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	printf("Colorenhancement Property Sample\n");
	IC_StartLive(hGrabber,1);

	printf("Press a key to run the one push auto focus\n");
	_getch();
	IC_FocusOnePush( hGrabber );	// No error handling here.

	printf("Press a key to stop live video\n");
	_getch();

	IC_StopLive(hGrabber);
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}

//////////////////////////////////////////////////////////////////
// Test function for one strobe with generic interface
// Use VCD Propery Inspector for querrying the names of the properties.

void GenericStrobe()
{
	int Min = 0;
	int Max = 0;
	int Value = 0;
	int result;
	float fMin = 0.0f; 
	float fMax = 0.0f;
	float fValue = 1111.0;
	
	int ModeCount;
	char **StrobeModes;
	char StrobeMode[50];
	int i;

	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	printf("Strobe Property Sample\n");
	

	if( IC_IsPropertyAvailable( hGrabber, "Strobe",NULL) == IC_SUCCESS )
	{
		// Play with the strobe enable switch. Get the current value, set a new value.
		printf("Strobe is supported\n");

		IC_GetPropertySwitch(hGrabber,"Strobe","Enable",&Value);
		if(  Value == 1 )
		{
			printf("Strobe is currently enabled\n");
			IC_SetPropertySwitch(hGrabber,"Strobe","Enable", 0 );
		}
		else
		{
			printf("Strobe is currently disabled\n");
			IC_SetPropertySwitch(hGrabber,"Strobe","Enable", 1 );
		}

		IC_GetPropertySwitch(hGrabber,"Strobe","Enable",&Value);
		if( Value == 1 )
		{
			printf("Strobe is now enabled\n");
		}
		else
		{
			printf("Strobe is now disabled\n");
		}

		// Check the strobe delay
		if( IC_GetPropertyValueRange(hGrabber,"Strobe","Delay",&Min, &Max ) == IC_SUCCESS)
		{
			printf("Strobe Delay range is %d  -  %d\n",Min,Max);
			IC_GetPropertyValue(hGrabber,"Strobe","Delay",&Value);
			printf("Strobe Delay current value is  %d\n",Value);

			// Set a new value
			IC_SetPropertyValue(hGrabber,"Strobe","Delay",Max);

			// Check the result
			IC_GetPropertyValue(hGrabber,"Strobe","Delay",&Value);
			printf("Strobe Delay current value is now Max: %d\n",Value);

			// Query the count of strobe modes
			IC_GetPropertyMapStrings(hGrabber,"Strobe","Mode",&ModeCount,NULL);
			printf("Count of strobe modes is: %d\n",ModeCount);

			// Allocate memory for the strobemodes
			if( ModeCount > 0 )
			{
				StrobeModes = (char**)malloc(ModeCount);
				for( i = 0; i < ModeCount; i++ )
				{
					StrobeModes[i] = (char*)malloc(50);
					StrobeModes[i][0] = '\0';
				}
			}

			// Query the strobe modes
			IC_GetPropertyMapStrings(hGrabber,"Strobe","Mode",&ModeCount,StrobeModes);
			printf("Available modes are:\n");
			for( i = 0; i < ModeCount; i++ )
			{
				printf(" - %s\n", StrobeModes[i]);
			}


			// Now query the current setting.
			IC_GetPropertyMapString(hGrabber,"Strobe","Mode",StrobeMode);
			printf("Current strobe mode is : %s\n", StrobeMode);

			// At least, set a strobe mode
			IC_SetPropertyMapString(hGrabber,"Strobe","Mode",StrobeModes[0]);

			// Now query the current setting.
			IC_GetPropertyMapString(hGrabber,"Strobe","Mode",StrobeMode);
			printf("New strobe mode is : %s\n", StrobeMode);

			IC_SetPropertyMapString(hGrabber,"Strobe","Mode",StrobeModes[1]);

			IC_GetPropertyMapString(hGrabber,"Strobe","Mode",StrobeMode);
			printf("Newer strobe mode is : %s\n", StrobeMode);


			// Free memory
			for( i = 0; i < ModeCount; i++ )
			{
				free( StrobeModes[i]); 
			}
		}
		else
		{
			printf("Strobe Delay not supported\n");
		}


		 	
		result = IC_SetPropertySwitch(hGrabber,"Trigger","Enable", 1);
		// Ergebnis: return 1

		result = IC_GetPropertyAbsoluteValueRange(hGrabber,"Trigger","Delay",&fMin, &fMax);
		// Ergebnis: return -6, Min 0, Max 0

		result = IC_SetPropertyAbsoluteValue(hGrabber,"Trigger","Delay",7777.0);
		// Ergebnis: return -6

		result = IC_GetPropertyAbsoluteValue(hGrabber,"Trigger","Delay",&fValue);
		// Ergebnis return -6, Value = 1111



	}
	else
	{
		printf("Strobe is not supported\n");
	}



	IC_StopLive(hGrabber);
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}


void GPOut()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	printf("Strobe Property Sample\n");

	printf("0\n");
	IC_SetPropertyValue(hGrabber,"GPIO","GP Out", (int) 0);
    IC_PropertyOnePush(hGrabber,"GPIO","Write");

	printf("Press a key to continue\n");
	_getch();

	printf("1\n");
	IC_SetPropertyValue(hGrabber,"GPIO","GP Out", (int) 1 );
    IC_PropertyOnePush(hGrabber,"GPIO","Write");

	printf("Press a key to continue\n");
	_getch();

	printf("0\n");
	IC_SetPropertyValue(hGrabber,"GPIO","GP Out", (int) 0 );
    IC_PropertyOnePush(hGrabber,"GPIO","Write");

	printf("Press a key to continue\n");
	_getch();

	printf("1\n");
	IC_SetPropertyValue(hGrabber,"GPIO","GP Out", (int) 1 );
    IC_PropertyOnePush(hGrabber,"GPIO","Write");

	printf("Press a key to end\n");
	_getch();

	IC_StopLive(hGrabber);
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}



void GPIn()
{
	int In = 0;
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	printf("GPIn Property Sample\n");

	while( 1 )
	{
		IC_PropertyOnePush(hGrabber,"GPIO","Read");
		IC_GetPropertyValue(hGrabber,"GPIO","GP IN",&In);
		printf("%d",In);
	}

	IC_StopLive(hGrabber);
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}



/////////////////////////////////////////////////////////////////////////
//
void photo(char *nomcam,char *format,char *type,char *trigger)
{
	int trig;
	FILE *prephoto;
	HGRABBER hGrabber;
	char image[200];
	int ImageReceived;
	int Tries;
	ImageReceived = 0;
	trig = atoi(trigger);
	strcpy( image,"b:\\bla.bmp");

	if( IC_InitLibrary(0) == IC_SUCCESS )
	{
		hGrabber = IC_CreateGrabber();
		if( hGrabber )
		{
			if( IC_OpenVideoCaptureDevice(hGrabber,nomcam) == IC_SUCCESS )
			{
				if(!(strcmp(format,"Y800")))
					IC_SetFormat (hGrabber, Y800); //initialise le format de la camera
				else if(!(strcmp(format,"RGB24")))
					IC_SetFormat (hGrabber, RGB24); //initialise le format de la camera
				else
					IC_SetFormat (hGrabber, RGB32); //initialise le format de la camera
				if( IC_IsTriggerAvailable(hGrabber) == IC_SUCCESS )
				{
					if(trig==0)
					{
						if(IC_StartLive (hGrabber, 0)==IC_SUCCESS)
						{
							if(!(strcmp(type,"BMP")))
								IC_SaveImage ( hGrabber, image, FILETYPE_BMP,50);
							else
								IC_SaveImage ( hGrabber, image, FILETYPE_JPEG,50);
						}
					}
					else if(trig==1)
					{
						IC_EnableTrigger(hGrabber,1);
						IC_SetFrameReadyCallback (hGrabber, *TriggerCallback, (void*)&ImageReceived);
						IC_SetContinuousMode(hGrabber,0);

						if(IC_StartLive (hGrabber, 0)==IC_SUCCESS)
						{
							Tries = 60; // Tries for time out. Depends on the Sleep time and the frame rate.
							while(Tries > 0 && ImageReceived == 0)
							{
								Sleep( 1000 );
								Tries--;
							}	

							printf("Loop ended\n");
						}
					}
					IC_StopLive (hGrabber); //stop la camera
					IC_EnableTrigger(hGrabber,0);
				}
			}
			// suprime les choses créé pour eviter les fuite de memoire
			IC_CloseVideoCaptureDevice( hGrabber );
			IC_ReleaseGrabber( &hGrabber );
		}
		//IC_CloseLibrary();
	}
} 


//////////////////////////////////////////////////////////////////////////
/*! Frame filters
*/
void FrameFilters()
{
	HGRABBER hGrabber;
	int iFilterCount;
	int i;
	char **FilterList;
	HFRAMEFILTER FilterHandle;
	int FlipHValue = 0;
	int FlipVValue = 0;
	int RotationAngle = 0;

	FilterHandle.pFilter = NULL;
	FilterHandle.bHasDialog = 0;

	iFilterCount = IC_GetAvailableFrameFilterCount();

	// Create the memory for the filter list
	FilterList = (char**)malloc(iFilterCount);
	for( i = 0; i < iFilterCount; i++ )
	{
		FilterList[i] = (char*)malloc(50);
		FilterList[i][0] = '\0';
	}

	printf("%d Frame filters are available.\n",iFilterCount);

	// Query the filters and list them.
	IC_GetAvailableFrameFilters(FilterList,iFilterCount );
	for( i = 0; i < iFilterCount; i++ )
	{
		printf("%s\n", FilterList[i]); 
	}

	if( IC_CreateFrameFilter("Rotate Flip", &FilterHandle) == IC_SUCCESS)
	{

		// List availalbe Parameters of the filter

		for( i = 0; i < FilterHandle.ParameterCount; i++ )
		{
			printf("Parameter \"%s\", Type : \"%d\"\n", FilterHandle.Parameters[i].Name,  FilterHandle.Parameters[i].Type);
		}

		printf("Filter successfully created\n");
		hGrabber = IC_CreateGrabber();
		IC_AddFrameFilterToDevice(hGrabber, FilterHandle);


		// Show the built in filter dialog
		if( FilterHandle.bHasDialog )
		{
			IC_FrameFilterShowDialog( FilterHandle);
		}

		// Query values from a filter (Rotate Flip)
		IC_FrameFilterGetParameter(FilterHandle,"Flip H", &FlipHValue);
		printf("Flip H : %d\n",FlipHValue);

		IC_FrameFilterGetParameter(FilterHandle,"Flip V", &FlipVValue);
		printf("Flip V : %d\n",FlipVValue);

		IC_FrameFilterGetParameter(FilterHandle,"Rotation Angle", &RotationAngle);
		printf("Rotation Angle : %d\n",RotationAngle);
		
		

		IC_ShowDeviceSelectionDialog(hGrabber);
		// rotate the image 90° (can not be set, while the live video runs).
		IC_FrameFilterSetParameterInt(FilterHandle,"Rotation Angle", 90);
		IC_StartLive(hGrabber,1);

		printf("Press a key to end\n");
		_getch();

		IC_StopLive(hGrabber);
		IC_FrameFilterDeviceClear(hGrabber);
		IC_DeleteFrameFilter( FilterHandle );
		FilterHandle.pFilter = NULL;
		IC_ReleaseGrabber( &hGrabber);
	}
	else
	{
		printf("Failed to create the filter.\n");
	}

	// Free memory
	for( i = 0; i < iFilterCount; i++ )
	{
		free( FilterList[i]); 
	}
	IC_CloseLibrary();
}
////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////
/*
		Property functions

*/

////////////////////////////////////////////////////////////////////
/*
	Enumerate available properties of a device. This function uses 
	a callbacl for enumeration.
*/

//////////////////////////////////////////////////////////////////
/* Simple callback function, that is used to list all available properties 
*/
int  _cdecl enumPropertiesSimple( char* PropertyName ,void* Data)
{
	printf("%s\n", PropertyName);

	return 0; // Do not terminate the enumeration
}

//////////////////////////////////////////////////////////////////
/* Simple function, that lists all properties. 
*/
void Enumerate_Available_Properties_Simple()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   

	IC_enumProperties( hGrabber,enumPropertiesSimple,NULL);

	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}

//////////////////////////////////////////////////////////////////
/* Callback functions, that are used to list all available properties
   and enumerates the available interfaces. 
   Therefore, the HGRABBER handle is passed in Data.

   enumProperties() will call enumElements
*/

typedef struct 
{
	HGRABBER hGrabber;
	char PropertyName[100];
	char ElementName[100];
} CAMERA_PROPERTY_t;

int  _cdecl enumInterfaces( char* InterfacetName ,void* Data)
{
	CAMERA_PROPERTY_t *CameraProperty = (CAMERA_PROPERTY_t*)Data;
	
	int iMin,iMax,iValue;
	float fMin,fMax,fValue;

	printf("\t\tInterface: %s\n", InterfacetName);
	
	// Query some property values
	if( strcmp(InterfacetName,"Range") == 0 )
	{
		IC_GetPropertyValueRange(CameraProperty->hGrabber, CameraProperty->PropertyName, CameraProperty->ElementName, &iMin, &iMax );
		printf("\t\tMin: %d, Max: %d, ", iMin, iMax);
		IC_GetPropertyValue(CameraProperty->hGrabber, CameraProperty->PropertyName, CameraProperty->ElementName,&iValue);
		printf("Current : %d\n", iValue);
	}

	if( strcmp(InterfacetName,"AbsoluteValues") == 0 )
	{
		IC_GetPropertyAbsoluteValueRange(CameraProperty->hGrabber, CameraProperty->PropertyName, CameraProperty->ElementName, &fMin, &fMax );
		printf("\t\tMin: %f, Max: %f, ", iMin, iMax);
		IC_GetPropertyAbsoluteValue(CameraProperty->hGrabber, CameraProperty->PropertyName, CameraProperty->ElementName,&fValue);
		printf("Current : %f\n", fValue);
	}



	return 0; // Do not terminate the enumeration
}


int  _cdecl enumElements( char* ElementName ,void* Data)
{
	CAMERA_PROPERTY_t *CameraProperty = (CAMERA_PROPERTY_t*)Data;
	strcpy(CameraProperty->ElementName, ElementName);

	printf("\t Element: %s\n", ElementName);
	// Lets get the available interfaces for this element
	IC_enumPropertyElementInterfaces(CameraProperty->hGrabber, CameraProperty->PropertyName, CameraProperty->ElementName,enumInterfaces,Data);
	
	
	return 0; // Do not terminate the enumeration
}


int  _cdecl enumProperties( char* PropertyName ,void* Data)
{
	CAMERA_PROPERTY_t CameraProperty;
	CameraProperty.hGrabber = (HGRABBER) Data;
	strcpy( CameraProperty.PropertyName, PropertyName);

	printf("Property: %s\n", PropertyName);
	// Lets get the elements of the found property:
	IC_enumPropertyElements((HGRABBER)Data, PropertyName,enumElements, (void*)&CameraProperty);

	return 0; // Do not terminate the enumeration
}

//////////////////////////////////////////////////////////////////
/* List all properties with their elements. It calls 
	enumProperties which calls
	enumElements
*/
void Enumerate_Available_Properties()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   

	IC_enumProperties( hGrabber,enumProperties,(void*)hGrabber);

	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}




////////////////////////////////////////////////////////////////////
// Set exposure absolut and gain.
void Exposure_Gain()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	printf("Exposure and Gain Sample\n");
	IC_StartLive(hGrabber,1 );
	// Disable gain automatic
	IC_SetPropertySwitch(hGrabber,"Gain","Auto",0);
	// Set a gain value
	IC_SetPropertyValue(hGrabber,"Gain","Value",16);

	// Disable Exposure automatic
	IC_SetPropertySwitch(hGrabber,"Exposure","Auto",0);
	// Set an abslute exposure value in seconds uning
	IC_SetPropertyAbsoluteValue(hGrabber,"Gain","Value",0.0303);

	// Disable Whitebalance automatic
	IC_SetPropertySwitch(hGrabber,"WhiteBalance","Auto",0);

	// Set a white balance values
	IC_SetPropertyValue(hGrabber,"WhiteBalance","White Balance Red",64);
	IC_SetPropertyValue(hGrabber,"WhiteBalance","White Balance Green",128);
	IC_SetPropertyValue(hGrabber,"WhiteBalance","White Balance Red",32);

	printf("Press a key to continue\n");
	_getch();
	IC_StopLive(hGrabber);
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void Using_12bits()
{
	int i,p;
	unsigned char *pImageData = NULL;
	unsigned short Pixel;
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	printf("Using 12bits Sample\nMake sure the video capture device supports Y16 video format\n");

	IC_RemoveOverlay(hGrabber,0);	// Remove the Graphic Overlay
	IC_SetFormat(hGrabber,Y16);		// Set memoryformat in the sink to 16 bit.

	IC_StartLive(hGrabber,1 );
	IC_SnapImage(hGrabber, 2000);	// Snap a frame into memory

	printf("Image data:\n");
	while(!kbhit())
	{
		if( IC_SnapImage(hGrabber, 200) == IC_SUCCESS )
		{

			pImageData = IC_GetImagePtr(hGrabber );
			if( pImageData != NULL )
			{
				for( p = 0; p < 15; p++)
				{
					memcpy( &Pixel,pImageData,2);
					Pixel = Pixel >>4;	// move the upper 12 bit to the left, so we have 0..4095 gray scales.
										// keep in mind, the lowst 4 bits usually keep noise only.
					printf("%04X ",Pixel);
					pImageData+=2;		// move data pointer to next pixel.
				}
				printf("\n");
			}
		}
	}
	printf("Press a key to continue\n");
	_getch();
	IC_StopLive(hGrabber);
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();
}

//////////////////////////////////////////////////////////////////////////
/* AVI Capture
*/

//////////////////////////////////////////////////////////////////
/* Simple callback function, that is used to list all available coceds 
*/
int  _cdecl enumCodecsCB( char* Codecname ,void* Data)
{
	printf("%s\n", Codecname);

	return 0; // Do not terminate the enumeration
}


//////////////////////////////////////////////////////////////////////////
/* Simply list all installed codecs.
*/
void ListInstalledCodecs()
{

	IC_enumCodecs(enumCodecsCB, NULL);

}


//////////////////////////////////////////////////////////////////
/*  This callback function is used to search for a special codec.
	The name of the codec, that is searched for and the found CODECHANDLE 
	will be saved in a structure passed by Data.
*/

typedef struct SEARCH_CODEC_t_
{
	char Name[255];
	HCODEC FoundCodec;
} SEARCH_CODEC;	


int  _cdecl SearchCodecCB( char* Codecname, void* Data)
{
	SEARCH_CODEC *pCodecData = (SEARCH_CODEC*) Data;

	if(strcmp( pCodecData->Name, Codecname) == 0)
	{
		pCodecData->FoundCodec = IC_Codec_Create(Codecname);
		return 1; // Terminate on success;
	}
	return 0; // Continue search.
}


//////////////////////////////////////////////////////////////////////////
/* This sample searches for a codec and shows the codec's property dialog
*/
void ShowPropertyDialogOfSpecialCodec()
{
	SEARCH_CODEC CodecToSearch;
	strcpy( CodecToSearch.Name, "MJPEG Compressor");
	CodecToSearch.FoundCodec = NULL;

	IC_enumCodecs(SearchCodecCB, (void*)&CodecToSearch);

	if( CodecToSearch.FoundCodec != NULL )
	{
		if( IC_Codec_hasDialog(  CodecToSearch.FoundCodec ) == IC_SUCCESS )
		{
			printf("Show property dialog of codec %s.\n",  CodecToSearch.Name);
			IC_Codec_showDialog( CodecToSearch.FoundCodec );
		}
		else
		{
			printf("Codec %s has no property dialog.\n",  CodecToSearch.Name);
		}
		IC_Codec_Release( CodecToSearch.FoundCodec );
	}
	else
	{
		printf("Codec %s not found\n.",  CodecToSearch.Name);
	}
}

////////////////////////////////////////////////////////////////////
// Capture an AVI file
// Select video capture device
// Create the codec
// 
void CaptureAVI()
{
	HGRABBER hGrabber = IC_ShowDeviceSelectionDialog(NULL);   
	HCODEC Codec = IC_Codec_Create("MJPEG Compressor"); // Make sure, the codec exists. However, thats one of the standard Windows codecs.

	if(Codec != NULL )
	{
		IC_SetCodec(hGrabber,Codec);
		IC_SetAVIFileName(hGrabber,"test.avi");
		IC_enableAVICapturePause(hGrabber,1); // Pause avi capture.

		IC_StartLive(hGrabber,1 ); // start the live stream

		printf("Press a key to start AVI Capture\n");
		_getch();
		IC_enableAVICapturePause(hGrabber,0); 

		printf("Press a key to end AVI Capture\n");
		_getch();
		IC_StopLive(hGrabber);

		IC_Codec_Release( Codec );

	}
	IC_ReleaseGrabber(&hGrabber);
	IC_CloseLibrary();

}

//////////////////////////////////////////////////////////////////////////
/*!
*/
void main()
{
	if( IC_InitLibrary(0) )
	{
		OpenDeviceAndShowLiveVideo();
		//ShowProperties();
		//ShowandSaveProperties();
		//ImageProcessing();
		//CheckDevice();
		//DevicesAndSerialNumbers();
		//PropertyCheck2();
		//Test3();
		//CallbackTest();
		//GetImageDescriptionSample();
		//TestAbsoluteValues();
		//DrawOverlay();
		//ChangeInputChannels();
		//SetTrigger();
		//ColorEnhancementSample();
		//SoftwareTrigger();
		//FrameRate();
		//ShowInternalPropertyDialog();
		//ResetProperties();
		//DeviceLostSample();
		//FocusOnePush();
		//GenericStrobe();
		//GPOut();
		//GPIn();
		//FrameFilters();
		
		
		///////////////////////////////////////////////////////////////////////
		// Property functions

		//Exposure_Gain();
		//Enumerate_Available_Properties();

		//////////////////////////////////////////////////////
		//Using_12bits();


		//////////////////////////////////////////////////////////////////////////
		// AVI Capture functions

		//ListInstalledCodecs();
		//ShowPropertyDialogOfSpecialCodec();
		//CaptureAVI();
		

		printf("Press any key to continue!\n");
		_getch();
		
	}
	else
	{
		IC_MsgBox("InitLibrary failed.","Initialize");
	}

}