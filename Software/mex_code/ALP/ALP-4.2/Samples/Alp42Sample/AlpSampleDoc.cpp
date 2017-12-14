// AlpSampleDoc.cpp : implementation of the CAlpSampleDoc class
//
// This is a part of the ALP application programming interface.
// Copyright (C) 2004 ViALUX GmbH
// All rights reserved.
//

#include "stdafx.h"
#include "AlpSample.h"

#include "AlpSampleDoc.h"

#include "math.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleDoc

IMPLEMENT_DYNCREATE(CAlpSampleDoc, CDocument)

BEGIN_MESSAGE_MAP(CAlpSampleDoc, CDocument)
	//{{AFX_MSG_MAP(CAlpSampleDoc)
	ON_COMMAND(ID_ALP_INIT, OnAlpInit)
	ON_COMMAND(ID_ALP_CLEARUP, OnAlpClearup)
	ON_COMMAND(ID_ALP_LOAD, OnAlpLoad)
	ON_COMMAND(ID_ALP_START, OnAlpStart)
	ON_COMMAND(ID_ALP_STOP, OnAlpStop)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleDoc construction/destruction

CAlpSampleDoc::CAlpSampleDoc()
:
m_bAlpInit(FALSE),
m_AlpSeq(0),
m_AlpSeqDisp(-1),
m_pData(NULL),
m_bDisp(FALSE)
{
	m_BitNum = 1;
	m_PicNum = 16;
}

CAlpSampleDoc::~CAlpSampleDoc()
{
	if (m_bAlpInit)
		AlpDevFree(m_AlpId);

	if (m_pData)
		delete m_pData;
}

BOOL CAlpSampleDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)

	// change title of document to company name (no file commands)
	CString strTitle;
	if (strTitle.LoadString(IDS_COMPANY_NAME))
		SetTitle(strTitle);		

	return TRUE;
}


/////////////////////////////////////////////////////////////////////////////
// CAlpSampleDoc serialization

void CAlpSampleDoc::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
		// TODO: add storing code here
	}
	else
	{
		// TODO: add loading code here
	}
}

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleDoc diagnostics

#ifdef _DEBUG
void CAlpSampleDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CAlpSampleDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleDoc sequence data generation

void CAlpSampleDoc::InitWheel(unsigned char *buf, int num)
{
	long const n = 3;						// half number of spokes >= 2 !
	long const d = min(m_nSizeY, m_nSizeX);	// wheel diameter
	double const pi = 3.14159;

	double	a	=	10.;		// half width of the spokes
	double	b	=	5.;			// tyre width
	double	c	=	.5;			// hub radius (hub ratio)

	double alpha	=	pi/n;				// spoke angle
	double delta	=	alpha/num;			// frame angle
	double ra		=	a/asin(alpha/2);	// hub outer radius
	double ri		=	ra*c;				// hub inner radius
	double ru		=	d/2-b;				// rim radius
	double z		=	pi*ru/(2*n*num);

	if (a > z) z = a;

	int i, j, k, x, y;
	double r;
	double gamma_s[n];
	double gamma_c[n];

	// check buffer pointer
	ASSERT(!IsBadWritePtr(buf,m_nSizeX*m_nSizeY*num));
		
	memset(buf, 0, m_nSizeX*m_nSizeY*num);
	for (i=0; i<num; i++)
	{
	  for (k=0; k<n; k++)
	  {
		gamma_s[k] = sin(pi/2 - k*alpha + i*delta);
		gamma_c[k] = cos(pi/2 - k*alpha + i*delta);
	  }

	  for (j=0; j<m_nSizeY; j++)
	  {
		if (j < m_nSizeY/2)
			y = m_nSizeY/2 - j;
		else
			y = m_nSizeY/2 - 1 - j;

		int i1 = m_nSizeX*m_nSizeY*i + m_nSizeX*j + m_nSizeX/2;
		int i2 = m_nSizeX*m_nSizeY*(i+1) - m_nSizeX*j - m_nSizeX/2 - 1;

		for (x=0; x<m_nSizeX/2; x++)
		{
			// radius test
			r = sqrt((double)(x*x + y*y));
			if (r > ri && r < d/2) 
			{
			  // hub or tyre
			  if (r < ra || r > ru)
			  {
				buf[i1 + x] = 255;		// 1. & 4. quadrant
				buf[i2 - x] = 255;		// 3. & 2. quadrant
			  }
			  else
				// spoke test
				for (k=0; k<n; k++)
				{
					double t = x*gamma_s[k] - y*gamma_c[k];
					if (t >= 0)
					{
						if (t <= z)
						{
							buf[i1 + x] = 255;		// 1. & 4. quadrant
							buf[i2 - x] = 255;		// 3. & 2. quadrant
							break;					// no further tests
						}
					}
					else if (t > -z)
					{
							buf[i1 + x] = 255;		// 1. & 4. quadrant
							buf[i2 - x] = 255;		// 3. & 2. quadrant
							break;					// no further tests
					}
				}
			}
		}
	  }
	}
#undef n
#undef d
#undef pi
}

/////////////////////////////////////////////////////////////////////////////
// CAlpSampleDoc commands

void CAlpSampleDoc::OnAlpInit() 
{
	if (m_bAlpInit)	// avoid re-initialization
	{
		AfxMessageBox(IDS_ERROR_ALP_REINIT, MB_OK);
		return;
	}

	// show status text and wait cursor
	static CFrameWnd* pFrame = (CFrameWnd*) AfxGetMainWnd();
	pFrame->SetMessageText(IDS_ALP_INIT);
	BeginWaitCursor();

	// allocate device
	if (AlpDevAlloc(ALP_DEFAULT, ALP_DEFAULT, &m_AlpId) == ALP_OK &&
		AlpDevInquire(m_AlpId, ALP_DEV_DMDTYPE, &m_nDmdType) == ALP_OK)
	{
		switch (m_nDmdType) {
		case ALP_DMDTYPE_XGA_055A :
		case ALP_DMDTYPE_XGA_055X :
		case ALP_DMDTYPE_XGA_07A :
			m_nSizeX = 1024;
			m_nSizeY = 768;
			m_bAlpInit = TRUE;
			break;
		case ALP_DMDTYPE_DISCONNECT :	// API emulates 1080p
		case ALP_DMDTYPE_1080P_095A :
			m_nSizeX = 1920;
			m_nSizeY = 1080;
			m_bAlpInit = TRUE;
			break;
		case ALP_DMDTYPE_WUXGA_096A :
			m_nSizeX = 1920;
			m_nSizeY = 1200;
			m_bAlpInit = TRUE;
			break;
		default :
			AfxMessageBox(IDS_ERROR_DMD_TYPE, MB_OK);
		}

		// inquire device memory
		if (m_bAlpInit) AlpDevInquire(m_AlpId, ALP_AVAIL_MEMORY, &m_FrameMemory);
	}
	else
		AfxMessageBox(IDS_ERROR_ALP_INIT, MB_OK);

	// restore status text and wait cursor
	pFrame->SetMessageText(AFX_IDS_IDLEMESSAGE);
	EndWaitCursor();
}

void CAlpSampleDoc::OnAlpClearup() 
{
	if (!m_bAlpInit)	// check for initialization
	{
		AfxMessageBox(IDS_ERROR_ALP_NOT_INIT, MB_OK);
		return;
	}

	if (AlpDevFree(m_AlpId) == ALP_OK)
	{
		m_bAlpInit = FALSE;
		m_AlpSeq = 0;
		m_AlpSeqDisp = -1;
	}
	else
		AfxMessageBox(IDS_ERROR_ALP_FREE, MB_OK);
}

void CAlpSampleDoc::OnAlpLoad() 
{
	if (!m_bAlpInit)	// check for initialization
	{
		AfxMessageBox(IDS_ERROR_ALP_NOT_INIT, MB_OK);
		return;
	}

	// allocate ALP sequence memory
	if ( (m_AlpSeq == SEQU_MAX) ||
	     (AlpSeqAlloc(m_AlpId, m_BitNum, m_PicNum, &m_AlpSeqId[m_AlpSeq]) != ALP_OK) )
	{
		AfxMessageBox(IDS_ERROR_SEQ_ALLOC, MB_OK);
		return;
	}

	// set sequence timing
	long Time = 10000 * (m_AlpSeq + 1);
	AlpSeqTiming(m_AlpId, m_AlpSeqId[m_AlpSeq], ALP_DEFAULT, Time, ALP_DEFAULT, ALP_DEFAULT, ALP_DEFAULT);

	// show status text and wait cursor
	static CFrameWnd* pFrame = (CFrameWnd*) AfxGetMainWnd();
	pFrame->SetMessageText(IDS_ALP_LOAD);
	BeginWaitCursor();

	// init sequence data - only once
	if (!m_pData)
	{
		m_pData = new char unsigned [m_nSizeX*m_nSizeY*m_PicNum];
		InitWheel(m_pData, m_PicNum);
	}

	// load sequence data into ALP memory
	if (AlpSeqPut(m_AlpId, m_AlpSeqId[m_AlpSeq], 0, m_PicNum, m_pData) != ALP_OK)
	{
		CString str;
		str.Format(IDS_ERROR_SEQ_PUT, m_AlpSeq + 1);
		AfxMessageBox(str, MB_OK);
	}

	// increment sequence index
	m_AlpSeq++;

	// restore status text and wait cursor
	pFrame->SetMessageText(AFX_IDS_IDLEMESSAGE);
	EndWaitCursor();
}


void CAlpSampleDoc::OnAlpStart() 
{
	if (!m_bAlpInit)	// check for initialization
	{
		AfxMessageBox(IDS_ERROR_ALP_NOT_INIT, MB_OK);
		return;
	}

	if (!m_AlpSeq)		// check for sequence allocation
	{
		AfxMessageBox(IDS_ERROR_SEQ_NOT_INIT, MB_OK);
		return;
	}

	m_AlpSeqDisp += 1;
	if (m_AlpSeqDisp == m_AlpSeq)
		m_AlpSeqDisp = 0;

	AlpProjStartCont(m_AlpId, m_AlpSeqId[m_AlpSeqDisp]);
	m_bDisp = TRUE;
}

void CAlpSampleDoc::OnAlpStop() 
{
	if (!m_bAlpInit)	// check for initialization
	{
		AfxMessageBox(IDS_ERROR_ALP_NOT_INIT, MB_OK);
		return;
	}

	AlpProjHalt(m_AlpId);
	m_bDisp = FALSE;
}
