========================================================================
ScrollingSample - Microsoft Win32 Console Application
========================================================================

This is a part of the ALP application programming interface.

© 2008-2009 ViALUX GmbH. All rights reserved.

Please always consult the ALP-4 high-speed API description when customizing
this program. It contains a detailled specification of all Alp... functions.

The ScrollingSample application primarily serves to illustrate the
image scrolling on ALP devices. It also serves as a simple template
suitable for adjusting in order to evaluate the different parameter sets
of the extension feature.

The application uses image data of two alternating frames:
- 1st, 3rd, 5th... frame: shaded arrow
- 2nd, 4th, 6th... frame: shaded circle
Parameters like total frame count, timing, and scrolling range are given
in the source code at the beginning of the main() function.


Build the sample application:
	1. Supported Integrated Development Environments
	Microsoft Visual C++ 6.0: Open ScrollingSample.dsw
	Microsoft Visual Studio 8.0 (2005): Open ScrollingSample8.sln
	Microsoft Visual Studio 10.0 (2010): Open ScrollingSample.sln
	Use the build command.

	2. Other Compile Software
	Use a C++ compiler to compile ScrollingSample.cpp. Make sure to have
	alp.h in your include path.
	(e.g. using the command line switch "/I:..\inc")
	Link the resulting object file to alpV42.lib.

Run the sample application:
	The ScrollingSample.exe depends upon alpV42.dll. So make sure to
	run it from a working directory that contains alpV42.dll.
	This DLL file must match the built EXE (32 or 64 bit). Else it 
	will not start, and instead shows error 0xc000007b.


This file contains a summary of what you will find in each of the files that
make up your ScrollingSample application.

ScrollingSample.cpp
	C++ source code of the sample application.

ReadMe.txt
	This text file.

ScrollingSample.dsw
	Microsoft Visual C++ 6.0 work space
ScrollingSample8.sln
	Microsoft Visual Studio 2005 (8.0) solution
ScrollingSample.sln
	Microsoft Visual Studio 2010 (10.0) solution

ScrollingSample.dsp
	Microsoft Visual C++ 6.0 project
ScrollingSample8.vcproj
	Microsoft Visual Studio 2005 (8.0) project
ScrollingSample.vcproj
	Microsoft Visual Studio 2010 (10.0) project

