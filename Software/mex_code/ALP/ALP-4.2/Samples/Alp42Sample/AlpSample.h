// AlpSample.h : main header file for the ALPSAMPLE application
//
// This is a part of the ALP application programming interface.
// Copyright (C) 2004 ViALUX GmbH
// All rights reserved.
//

#if !defined(AFX_ALPSAMPLE_H__AA820937_C345_408A_90D2_8025C7E13002__INCLUDED_)
#define AFX_ALPSAMPLE_H__AA820937_C345_408A_90D2_8025C7E13002__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleApp:
// See AlpSample.cpp for the implementation of this class
//

class CAlpSampleApp : public CWinApp
{
public:
	CAlpSampleApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CAlpSampleApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation
	//{{AFX_MSG(CAlpSampleApp)
	afx_msg void OnAppAbout();
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_ALPSAMPLE_H__AA820937_C345_408A_90D2_8025C7E13002__INCLUDED_)
