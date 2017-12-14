// AlpSampleView.cpp : implementation of the CAlpSampleView class
//
// This is a part of the ALP application programming interface.
// Copyright (C) 2004 ViALUX GmbH
// All rights reserved.
//

#include "stdafx.h"
#include "AlpSample.h"

#include "AlpSampleDoc.h"
#include "AlpSampleView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleView

IMPLEMENT_DYNCREATE(CAlpSampleView, CView)

BEGIN_MESSAGE_MAP(CAlpSampleView, CView)
	//{{AFX_MSG_MAP(CAlpSampleView)
	ON_UPDATE_COMMAND_UI(ID_ALP_INIT, OnUpdateAlpInit)
	ON_COMMAND(ID_ALP_INQUIRE, OnAlpInquire)
	ON_UPDATE_COMMAND_UI(ID_ALP_START, OnUpdateAlpStart)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleView construction/destruction

CAlpSampleView::CAlpSampleView()
{
	// TODO: add construction code here,

}

CAlpSampleView::~CAlpSampleView()
{
}

BOOL CAlpSampleView::PreCreateWindow(CREATESTRUCT& cs)
{
	// TODO: Modify the Window class or styles here by modifying
	//  the CREATESTRUCT cs

	return CView::PreCreateWindow(cs);
}

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleView drawing

void CAlpSampleView::OnDraw(CDC* /*pDC*/)
{
	CAlpSampleDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);
	// TODO: add draw code for native data here
}

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleView diagnostics

#ifdef _DEBUG
void CAlpSampleView::AssertValid() const
{
	CView::AssertValid();
}

void CAlpSampleView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CAlpSampleDoc* CAlpSampleView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CAlpSampleDoc)));
	return (CAlpSampleDoc*)m_pDocument;
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// update of Menu and Toolbar: ON_UPDATE_COMMAND_UI

void CAlpSampleView::OnUpdateAlpInit(CCmdUI* pCmdUI) 
{
	CAlpSampleDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);
	pCmdUI->SetCheck(pDoc->m_bAlpInit? 1:0);
}

void CAlpSampleView::OnUpdateAlpStart(CCmdUI* pCmdUI) 
{
	CAlpSampleDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);
	pCmdUI->SetCheck(pDoc->m_bDisp? 1:0);
}

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleView message handlers

void CAlpSampleView::OnAlpInquire() 
{
	CAlpSampleDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);

	if (!pDoc->m_bAlpInit)	// check for initialization
	{
		AfxMessageBox(IDS_ERROR_ALP_NOT_INIT, MB_OK);
		return;
	}

	CClientDC NewDC(this);

	TEXTMETRIC Metrics;
	NewDC.GetTextMetrics(&Metrics);
	int offset = Metrics.tmHeight*3/2;

	// clear client area
	RECT Rect;
	GetClientRect(&Rect);
	NewDC.FillSolidRect(&Rect, NewDC.GetBkColor());

	// get device information and simply show it
	long	Info;
	CString	Text;
	int		x = offset;
	int		y = offset;

	AlpDevInquire( pDoc->m_AlpId, ALP_VERSION, &Info);
	Text.Format(IDS_DEVICE_VERSION, HIBYTE(Info), LOBYTE(Info));
	NewDC.TextOut( x, y, Text); y += offset;

	AlpDevInquire( pDoc->m_AlpId, ALP_DEVICE_NUMBER, &Info);
	Text.Format(IDS_DEVICE_NUMBER, Info, pDoc->m_FrameMemory);
	NewDC.TextOut( x, y, Text); y += offset;

	AlpDevInquire( pDoc->m_AlpId, ALP_AVAIL_MEMORY, &Info);
	Text.Format(IDS_DEVICE_MEMORY, Info, pDoc->m_FrameMemory);
	NewDC.TextOut( x, y, Text); y += offset;

	Text.Format(IDS_SEQ_NUMBER, pDoc->m_AlpSeq);
	NewDC.TextOut( x, y, Text); y += offset;

	if (pDoc->m_bDisp)
	{
		Text.Format(IDS_SEQ_ACTIVE, pDoc->m_AlpSeqDisp + 1);
		NewDC.TextOut( x, y, Text); y += offset;

		AlpSeqInquire( pDoc->m_AlpId, pDoc->m_AlpSeqId[pDoc->m_AlpSeqDisp], ALP_PICTURE_TIME, &Info);
		Text.Format(IDS_SEQ_PICTIME, Info);
		NewDC.TextOut( x, y, Text); y += offset;

		AlpSeqInquire( pDoc->m_AlpId, pDoc->m_AlpSeqId[pDoc->m_AlpSeqDisp], ALP_MIN_PICTURE_TIME, &Info);
		Text.Format(IDS_SEQ_MINPICTIME, Info);
		NewDC.TextOut( x, y, Text); y += offset;
	}
}

