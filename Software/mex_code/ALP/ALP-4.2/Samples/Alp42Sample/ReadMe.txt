========================================================================
AlpSample - Microsoft Foundation Classes Application
========================================================================

This is a part of the ALP application programming interface.
Copyright (C) 2004 ViALUX GmbH
All rights reserved.

This sample is provided as-is, without any warranty.

Please always consult the ALP-4 high-speed API description when
customizing this program. It contains a detailled specification
of all Alp... functions.

The AlpSample application primarily serves to illustrate the ALP application 
programming interface features and programming techniques:

  1. Initialization and clear-up of one ALP device.

  2. Inquiry of ALP device information.

  3. Allocation of ALP sequence memory and transfer of image data into device
	memory.

  4. Adjustment of timing properties for the sequence display.

  5. Start and stop of sequence display.

This file contains a summary of what you will find in each of the files that
make up your AlpSample application.

ViALUX has supplied build settings by means of project files for different
versions of the Microsoft Visual Studio Software. However do not mix them.
Always clean the directory in the case of switching to another version, for
example use complete rebuild instead of incremental build.

AlpSample.dsw and AlpSample.dsp
	These files are the workspace and the project file of
	Microsoft Visual C++ 6.0.
AlpSample8.sln and AlpSample8.vcproj
	Project settings are upgraded to Microsoft Visual Studio 2005 (8.0).
	These are the according solution and project files.
AlpSample.vcxproj, AlpSample.vcxproj.filters and AlpSample.sln
	These are the according project settings and solution files for
	Microsoft Visual Studio 2010 (10.0).

AlpSample.h
	This is the main header file for the application.  It includes other
	project specific headers (including Resource.h) and declares the
	CAlpSampleApp application class.

AlpSample.cpp
	This is the main application source file that contains the application
	class CAlpSampleApp.

AlpSample.rc
	This is a listing of all of the Microsoft Windows resources that the
	program uses.  It includes the icons, bitmaps, and cursors that are stored
	in the RES subdirectory.  This file can be directly edited in Microsoft
	Developer Studio.

res\AlpSample.ico
	This is an icon file, which is used as the application's icon.  This
	icon is included by the main resource file AlpSample.rc.

res\AlpSample.rc2
	This file contains resources that are not edited by Microsoft
	Developer Studio.  You should place all resources not
	editable by the resource editor in this file.



/////////////////////////////////////////////////////////////////////////////

For the main frame window:


MainFrm.h, MainFrm.cpp
	These files contain the frame class CMainFrame, which is derived from
	CFrameWnd and controls all SDI frame features. 

/////////////////////////////////////////////////////////////////////////////

AppWizard creates one document type and one view.  These files are changed to 
support the functionality of the sample application.

AlpSampleDoc.h, AlpSampleDoc.cpp - the document
	These files contain your CAlpSampleDoc class.  It handles most of the 
	ALP menu commands. File saving and loading is not implemented.

AlpSampleView.h, AlpSampleView.cpp - the view of the document
	These files contain your CAlpSampleView class.
	CAlpSampleView objects are used to view CAlpSampleDoc objects.
	The message handler CAlpSampleView::OnAlpInquire implements the inquiry 
	of ALP device information and simply shows it in the client area.



/////////////////////////////////////////////////////////////////////////////
Other standard files:

StdAfx.h, StdAfx.cpp
	These files are used to build a precompiled header (PCH) file
	named AlpSample.pch and a precompiled types file named StdAfx.obj.

Resource.h
	This is the standard header file, which defines new resource IDs.
	Microsoft Developer Studio reads and updates this file.

/////////////////////////////////////////////////////////////////////////////
Other notes:

AppWizard uses "TODO:" to indicate parts of the source code you
should add to or customize.

If your application uses MFC in a shared DLL, and your application is
in a language other than the operating system's current language, you
will need to copy the corresponding localized resources MFC40XXX.DLL
from the Microsoft Visual C++ CD-ROM onto the system or system32 directory,
and rename it to be MFCLOC.DLL.  ("XXX" stands for the language abbreviation.
For example, MFC40DEU.DLL contains resources translated to German.)  If you
don't do this, some of the UI elements of your application will remain in the
language of the operating system.

/////////////////////////////////////////////////////////////////////////////
