This is a part of the ALP application programming interface.
Copyright (C) 2011 ViALUX GmbH
All rights reserved.

This sample application shows how to call the ALP high-speed API functions
from managed .NET code.

This sample is provided as-is, without any warranty.

Please always consult the ALP-4 high-speed API description when customizing
this program. It contains a detailled specification of all Alp... functions.

Source code contents:
---------------------
AlpImport.cs
	The class AlpImport is the equivalent C#
	representation of the C++ header file alp.h. It contains API function
	declarations, data types, and values of the ALP high-speed API.
	It is recommended to copy this file to a Visual Basic .NET project in
	order to use the ALP-4 high-speed API.

AlpSampleProgram.cs and AlpSampleForm.cs
	This application code handles user interface events, for example button
	clicks). It performs the necessary steps to show two different patterns on
	an ALP-4.

Build settings etc.:
--------------------
Settings are supplied by means of project files for different versions of the
Microsoft Visual Studio software.

ALP_CSharp8_DotNet.sln and ALP_CSharp8_DotNet.csproj
	These files are the solution and project files of
	Microsoft Visual Studio 2005 (8.0).

ALP_CSharp_DotNet.sln and ALP_CSharp_DotNet.csproj
	Project settings are upgraded to Microsoft Visual Studio 2010 (10.0).
	These are the according solution and project files.


Debug / Run:
------------
The DLL file alpV42.dll must be accessible to the application. Please copy
it to the sub-directory bin\Debug before starting the debug session.

Known Exceptions:
-----------------
System.DllNotFoundException: As the name suggests, the file alpV42.dll must be
	copied to the debug directory.

System.BadImageFormatException: Ensure that you have the correct version of
	alpD41.dll installed. It must match the build platform:
	- x86 uses the 32-bit version
	- x64 uses the 64-bit version
	- "Any CPU" needs the alpV42.dll version according to the operating system

In case of these errors stop debugging, copy the correct files to the debug
directory, and restart the application.

