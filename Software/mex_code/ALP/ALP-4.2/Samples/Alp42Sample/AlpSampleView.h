// AlpSampleView.h : interface of the CAlpSampleView class
//
// This is a part of the ALP application programming interface.
// Copyright (C) 2004 ViALUX GmbH
// All rights reserved.
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_ALPSAMPLEVIEW_H__EC0637C4_BAEB_4ABB_B9D5_701979F24580__INCLUDED_)
#define AFX_ALPSAMPLEVIEW_H__EC0637C4_BAEB_4ABB_B9D5_701979F24580__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


class CAlpSampleView : public CView
{
protected: // create from serialization only
	CAlpSampleView();
	DECLARE_DYNCREATE(CAlpSampleView)

// Attributes
public:
	CAlpSampleDoc* GetDocument();

// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CAlpSampleView)
	public:
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
	protected:
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~CAlpSampleView();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	//{{AFX_MSG(CAlpSampleView)
	afx_msg void OnUpdateAlpInit(CCmdUI* pCmdUI);
	afx_msg void OnAlpInquire();
	afx_msg void OnUpdateAlpStart(CCmdUI* pCmdUI);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG  // debug version in AlpSampleView.cpp
inline CAlpSampleDoc* CAlpSampleView::GetDocument()
   { return (CAlpSampleDoc*)m_pDocument; }
#endif

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_ALPSAMPLEVIEW_H__EC0637C4_BAEB_4ABB_B9D5_701979F24580__INCLUDED_)
