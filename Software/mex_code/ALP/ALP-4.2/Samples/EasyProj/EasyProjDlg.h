//
// EasyProjDlg.h : header file
//

#pragma once

#include "Projector.h"	// include the projector class
#include "afxwin.h"

#include "PlusGdi.h"	// GDI+
#include "afxcmn.h"

// CEasyProjDlg dialog
class CEasyProjDlg : public CDialogEx
{
private:
	CProjector	m_Projector;	// instance of the projector

// Construction
public:
	CEasyProjDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	enum { IDD = IDD_EASYPROJ_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
	// Control: Button "Alloc projector"
	CButton m_BtnProjectorAlloc;
	// CString member of the dialog element which shows the projector serial number
	CString m_ProjectorSerial;
	// Control: Button "Free projector"
	CButton m_BtnProjectorFree;
	// -----
	// Control: Radio button for synch polarity HIGH
	CButton m_RadioBtnSyncPolarityHigh;
	// Control: Radio button for synch polarity HIGH
	CButton m_RadioBtnSyncPolarityLow;
	// int member (Radio button) for synch polarity
	int m_iSyncPolarity;
	// -----
	// Control: Radio button for the LED type NONE
	CButton m_RadioBtnLEDTypeNone;
	// Control: Radio button for the LED type RED
	CButton m_RadioBtnLEDTypeRed;
	// Control: Radio button for the LED type GREEN
	CButton m_RadioBtnLEDTypeGreen;
	// Control: Radio button for the LED type BLUE
	CButton m_RadioBtnLEDTypeBlueTE;
	// Control: Radio button for the LED type UV
	CButton m_RadioBtnLEDTypeUV;
	// Control: Radio button for the LED type WHITE
	CButton m_RadioBtnLEDTypeCBT140White;
	// -----
	// int member (Radio button) for the LED type
	int m_iLEDType;
	// Control: Slider for the LED brightness
	CSliderCtrl m_sldLedBrightness;
	// int member (Slider) for the LED brightness
	int m_iLedBrightness;
	// -----
	// CString member of the dialog element which shows the projector return codes
	CString m_ProjectorErrorCode;
	// CString member of the dialog element which shows the projector error message
	CString m_ProjectorMessages;
	// -----
	// Control: Button "Load images"
	CButton m_BtnSequenceLoad;
	// CString member of the dialog element which shows the number of loaded images
	CString m_SequenceLoadedImages;
	// Control: Button "Free sequence"
	CButton m_BtnSeqFree;
	// Preview of the loaded images
	CStatic m_Preview;
	// Control: dialog element for the illumination time of the sequence
	CEdit m_EditIlluminateTime;
	// CString member of the dialog element for the illumination time of the sequence
	CString m_SequenceIlluminateTime;
	// Control: dialog element for the picture time of the sequence
	CEdit m_EditPictureTime;
	// CString member of the dialog element for the picture time of the sequence
	CString m_SequencePictureTime;
	// Control: dialog element for the synch delay
	CEdit m_EditSynchDelay;
	// CString member of the dialog element for the synch delay
	CString m_SequenceSynchDelay;
	// Control: dialog element for the synch pulse width
	CEdit m_EditSynchPulseWidth;
	// CString member of the dialog element for the synch pulse width
	CString m_SequenceSynchPulseWidth;
	// Control: Button "Start projection
	CButton m_BtnProjection;
	// Control: Button "Stop projection"
	CButton m_BtnProjStop;
	// Control: Button "Set sequence parameter"
	CButton m_BtnSet;

public:
	// fill dialog elements with return code and error message
	void SetProjectorReturnCodeMsg( const int retCode);
	// update all dialog elements from data
	void UpdateElements(void);
	// -----
	// free projector and reset dialog elements
	const int FreeProjector(void);
	// get projector properties and update dialog elements
	const int GetProjectorProperties(void);
	// change synch polarity
	const int SetSyncPolarity();
	// set gates for LED control
	const int SetGates( const int iGateIndex);
	// Sub-function
	void BnClickedRadioLEDType();
	// select the LED type
	const int SelectLEDType( const int iLedTypeIndex);
	// change the LED brightness
	const int SetLEDBrightness( const int iBrightness);
	// -----
	// free sequence and reset dialog elements
	const int FreeSequence(void);
	// get sequence properties
	const int GetSequenceProperties(void);
	// change sequence properties
	const int SetSequenceProperties(void);
	// load images and add it to a sequence
	const int LoadSequence(void);
	//
	afx_msg void OnBnClickedProjAlloc();
	afx_msg void OnBnClickedProjFree();
	afx_msg void OnBnClickedSeqLoad();
	afx_msg void OnBnClickedSeqFree();
	afx_msg void OnDestroy();
	afx_msg void OnBnClickedSynchPolarityHigh();
	afx_msg void OnBnClickedSynchPolarityLow();
	afx_msg void OnBnClickedSetSeqParam();
	afx_msg void OnBnClickedProjStart();
	afx_msg void OnBnClickedProjStop();
	virtual void OnOK();
	afx_msg void OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar);
	afx_msg void OnBnClickedRadioLedNone();
	afx_msg void OnBnClickedRadioLedRed();
	afx_msg void OnBnClickedRadioLedGreen();
	afx_msg void OnBnClickedRadioLedBlueTe();
	afx_msg void OnBnClickedRadioLedUv();
	afx_msg void OnBnClickedRadioLedCbt140White();
	// report ALP_BITNUM and ALP_BIN_MODE
	CString m_SequenceBitnum;
	virtual void WinHelp(DWORD dwData, UINT nCmd = HELP_CONTEXT);
};
