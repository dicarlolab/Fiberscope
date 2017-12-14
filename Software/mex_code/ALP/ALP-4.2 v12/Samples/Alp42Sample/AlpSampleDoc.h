// AlpSampleDoc.h : interface of the CAlpSampleDoc class
//
// This is a part of the ALP application programming interface.
// Copyright (C) 2004 ViALUX GmbH
// All rights reserved.
//
/////////////////////////////////////////////////////////////////////////////

#if !defined(AFX_ALPSAMPLEDOC_H__1976FDB8_3666_4797_82BB_D90189932082__INCLUDED_)
#define AFX_ALPSAMPLEDOC_H__1976FDB8_3666_4797_82BB_D90189932082__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


#include "alp.h"					// ALP API symbols and functions

#define SEQU_MAX		32				// maximum number of sequences


class CAlpSampleDoc : public CDocument
{
protected: // create from serialization only
	CAlpSampleDoc();
	DECLARE_DYNCREATE(CAlpSampleDoc)

// Attributes
public:

	BOOL		m_bAlpInit;				// ALP initialization status
	long		m_nDmdType;				// DMD type (ALP_DMDTYPE_...)
	long		m_nSizeX, m_nSizeY;		// DMD size (pixels X*Y)
	ALP_ID		m_AlpId;				// ALP device ID
	ALP_ID		m_AlpSeqId[SEQU_MAX];	// ALP sequence IDs
	long		m_AlpSeq;				// ALP sequence index
	long		m_AlpSeqDisp;			// ALP sequence slected for display
	long		m_FrameMemory;			// number of binary frames
	long		m_BitNum;				// number of bits
	long		m_PicNum;				// number of pictures
	char unsigned*		m_pData;		// sequence data
	BOOL		m_bDisp;				// display active


// Operations
public:

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CAlpSampleDoc)
	public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);
	//}}AFX_VIRTUAL

// Implementation
public:
	virtual ~CAlpSampleDoc();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:
	void InitWheel(unsigned char *buf, int num);

// Generated message map functions
protected:
	//{{AFX_MSG(CAlpSampleDoc)
	afx_msg void OnAlpInit();
	afx_msg void OnAlpClearup();
	afx_msg void OnAlpLoad();
	afx_msg void OnAlpStart();
	afx_msg void OnAlpStop();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_ALPSAMPLEDOC_H__1976FDB8_3666_4797_82BB_D90189932082__INCLUDED_)
