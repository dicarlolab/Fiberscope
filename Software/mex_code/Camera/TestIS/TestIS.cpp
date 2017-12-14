#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "C:\Users\Shay\SkyDrive\Waveform Reshaping code\Camera\The Imaging Source\C Code\include\tisgrabber.h"
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

		// Snap 10 images and display the contents of the first 15 bytes ot
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
void CheckVideoProperty(HGRABBER hGrabber, char* szName, VIDEO_PROPERTY iProperty )
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
void CheckCameraProperty(HGRABBER hGrabber, char* szName, CAMERA_PROPERTY iProperty )
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
	long lMin, lMax, i;
	int lValue;
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
//		PenHandle = SelectObject(hPaintDC, PenHandle);

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
	IC_GetDeviceCount();
	IC_OpenVideoCaptureDevice(hGrabber, IC_GetDevice(0));

	int err = IC_EnableTrigger(hGrabber,0);
	printf("Enable Trigger returned %d\n",err);
	IC_StartLive(hGrabber,1);

	printf("Untriggered, there should be new images\n");

	printf("Press any key to continue!\n");
	_getch();

	IC_StopLive(hGrabber );


	err = IC_EnableTrigger(hGrabber,1);
	printf("Enable Trigger returned %d\n",err);
	IC_StartLive(hGrabber,1);

	printf("Triggered, there should be new images only if a trigger pulse occurred\n");

	printf("Press any key to continue!\n");
	_getch();

	IC_StopLive(hGrabber );

	IC_EnableTrigger(hGrabber,0);


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
		int err;
		err = IC_EnableTrigger(hGrabber,1);
		printf("Enable Trigger Error is : %d\n",err);

		err = IC_SetFrameReadyCallback (hGrabber,   *TriggerCallback,  (void*)&ImageReceived);
		printf("IC_SetFrameReadyCallback Error is : %d\n",err);


		err = IC_SetContinuousMode(hGrabber,0);

		printf("IC_SetContinuousMode Error is : %d\n",err);

		IC_StartLive(hGrabber, 0 );
		
		ImageReceived = 0; // Set the flag for image received to 0;
		Tries = 10;			// Tries for time out. Depends on the Sleep time and the frame rate.

		printf("Waiting for trigger .\n");
		bool lop = true;
		while (lop)
		//{
		//if( IC_SoftwareTrigger(hGrabber) == IC_SUCCESS )
		{
			// Check, whether we got an image
			if (ImageReceived == 0)
			{
				Sleep( 1000 );
			}

			if( ImageReceived == 1 )
			{
				printf("Got an image.\n");
				break;
			} else
			{
				printf("Attempt %d\n",Tries--);
				if (Tries == 0)
				{
					printf("Software triggerring\n");
					int res = IC_SoftwareTrigger(hGrabber);
					printf("Software triggerring result : %d\n",res);
				}
				if (Tries == -10)
				{
					printf("Failed!\n");
					lop = false;
				}
			}
			
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



//////////////////////////////////////////////////////////////////////////
/*!
*/
void main()
{
	if( IC_InitLibrary(0) )
	{
		//OpenDeviceAndShowLiveVideo();
		//ShowProperties();
		//ShowandSaveProperties();
		//ImageProcessing();
		//CheckDevice();
		//DevicesAndSerialNumbers();
		PropertyCheck2();
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
		printf("Press any key to continue!\n");
		_getch();
		
	}
	else
	{
		IC_MsgBox("InitLibrary failed.","Initialize");
	}

}