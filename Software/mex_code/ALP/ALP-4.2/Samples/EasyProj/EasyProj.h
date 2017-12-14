// EasyProj.h : main header file for the PROJECT_NAME application
//

#pragma once

#ifndef __AFXWIN_H__
	#error "include 'stdafx.h' before including this file for PCH"
#endif

#include "resource.h"		// main symbols


// CEasyProjApp:
// See EasyProj.cpp for the implementation of this class
//

class CEasyProjApp : public CWinApp
{
public:
	CEasyProjApp();

// Overrides
public:
	virtual BOOL InitInstance();
	virtual BOOL SupportsRestartManager() const { return FALSE; }

// Implementation

	DECLARE_MESSAGE_MAP()
};

extern CEasyProjApp theApp;