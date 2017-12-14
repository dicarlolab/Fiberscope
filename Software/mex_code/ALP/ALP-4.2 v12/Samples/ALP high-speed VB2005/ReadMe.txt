This is a part of the ALP application programming interface.
Copyright (C) 2008-2009 ViALUX GmbH
All rights reserved.

This sample application shows how to call the ALP high-speed API functions
from managed .NET code.

This sample is provided as-is, without any warranty.

Please always consult the ALP-4 high-speed API description when customizing
this program. It contains a detailled specification of all Alp... functions.

Source code contents:
---------------------
AlpImport.vb
	The class AlpImport is the equivalent Visual Basic .NET
	representation of the C++ header file alp.h. It contains API function
	declarations, data types, and values of the ALP high-speed API.
	It is recommended to copy this file to a Visual Basic .NET project in
	order to use the ALP-4 high-speed API.

AlpTest.vb
	This application code handles user interface events, for example button
	clicks). It performs the necessary steps to show two different patterns on
	an ALP-4.


Debug / Run:
------------
The DLL file alpV42.dll must be accessible to the application. Please copy
it to the sub-directory bin\Debug before starting the debug session.

Known Exceptions:
-----------------
System.DllNotFoundException: As the name suggests, the file alpV42.dll must be
	copied to the debug directory.

System.BadImageFormatException: Ensure that you have the correct version of
	alpV42.dll installed. It must match the build platform:
	- x86 uses the 32-bit version
	- x64 uses the 64-bit version
	- "Any CPU" needs the alpD41.dll version according to the operating system

In case of these errors stop debugging, copy the correct files to the debug
directory, and restart the application.

