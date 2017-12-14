//
// EasyProjDlg.cpp : implementation file
//

#include "stdafx.h"
#include "EasyProj.h"
#include "EasyProjDlg.h"
#include "afxdialogex.h"

#include <memory>

//#ifdef _DEBUG
//#define new DEBUG_NEW
//#endif

GDIPLUS_APP;									// start GDI+

// CEasyProjDlg dialog

CEasyProjDlg::CEasyProjDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(CEasyProjDlg::IDD, pParent)
	, m_ProjectorErrorCode(_T(""))
	, m_ProjectorMessages(_T(""))
	, m_ProjectorSerial(_T(""))
	, m_SequenceLoadedImages(_T(""))
	, m_SequenceIlluminateTime(_T(""))
	, m_SequencePictureTime(_T(""))
	, m_iSyncPolarity(0)
	, m_SequenceSynchDelay(_T(""))
	, m_SequenceSynchPulseWidth(_T(""))
	, m_iLedBrightness(0)
	, m_iLEDType(0)
	, m_SequenceBitnum(_T(""))
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CEasyProjDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_PROJ_ALLOC, m_BtnProjectorAlloc);
	DDX_Control(pDX, IDC_PROJ_FREE, m_BtnProjectorFree);
	DDX_Text(pDX, IDC_ERROR_CODE, m_ProjectorErrorCode);
	DDX_Text(pDX, IDC_ERROR_MESSAGE, m_ProjectorMessages);
	DDX_Text(pDX, IDC_SERIAL, m_ProjectorSerial);
	DDX_Control(pDX, IDC_SEQ_LOAD, m_BtnSequenceLoad);
	DDX_Control(pDX, IDC_SEQ_FREE, m_BtnSeqFree);
	DDX_Control(pDX, IDC_PREVIEW, m_Preview);
	DDX_Text(pDX, IDC_SEQ_IMAGES, m_SequenceLoadedImages);
	DDX_Text(pDX, IDC_ILLU_TIME, m_SequenceIlluminateTime);
	DDX_Text(pDX, IDC_PIC_TIME, m_SequencePictureTime);
	DDX_Control(pDX, IDC_RADIO_TR_POLARITY_HIGH, m_RadioBtnSyncPolarityHigh);
	DDX_Control(pDX, IDC_RADIO_TR_POLARITY_LOW, m_RadioBtnSyncPolarityLow);
	DDX_Radio(pDX, IDC_RADIO_TR_POLARITY_HIGH, m_iSyncPolarity);
	DDX_Control(pDX, IDC_ILLU_TIME, m_EditIlluminateTime);
	DDX_Control(pDX, IDC_PIC_TIME, m_EditPictureTime);
	DDX_Control(pDX, IDC_SYNCH_DELAY, m_EditSynchDelay);
	DDX_Text(pDX, IDC_SYNCH_DELAY, m_SequenceSynchDelay);
	DDX_Control(pDX, IDC_TRIGGER_PULSE_WIDTH, m_EditSynchPulseWidth);
	DDX_Text(pDX, IDC_TRIGGER_PULSE_WIDTH, m_SequenceSynchPulseWidth);
	DDX_Control(pDX, IDC_PROJ_START, m_BtnProjection);
	DDX_Control(pDX, IDC_PROJ_STOP, m_BtnProjStop);
	DDX_Control(pDX, IDC_SET_SEQ_PARAM, m_BtnSet);
	DDX_Control(pDX, IDC_SLIDER_LED_BRIGHTNESS, m_sldLedBrightness);
	DDX_Slider(pDX, IDC_SLIDER_LED_BRIGHTNESS, m_iLedBrightness);
	DDX_Control(pDX, IDC_RADIO_LED_NONE, m_RadioBtnLEDTypeNone);
	DDX_Control(pDX, IDC_RADIO_LED_RED, m_RadioBtnLEDTypeRed);
	DDX_Control(pDX, IDC_RADIO_LED_GREEN, m_RadioBtnLEDTypeGreen);
	DDX_Control(pDX, IDC_RADIO_LED_BLUE_TE, m_RadioBtnLEDTypeBlueTE);
	DDX_Control(pDX, IDC_RADIO_LED_UV, m_RadioBtnLEDTypeUV);
	DDX_Control(pDX, IDC_RADIO_LED_CBT_140_WHITE, m_RadioBtnLEDTypeCBT140White);

	DDX_Radio(pDX, IDC_RADIO_LED_NONE, m_iLEDType);
	DDX_Text(pDX, IDC_EDIT_REPORT_BITNUM, m_SequenceBitnum);
}

BEGIN_MESSAGE_MAP(CEasyProjDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDC_PROJ_ALLOC, &CEasyProjDlg::OnBnClickedProjAlloc)
	ON_BN_CLICKED(IDC_PROJ_FREE, &CEasyProjDlg::OnBnClickedProjFree)
	ON_BN_CLICKED(IDC_SEQ_LOAD, &CEasyProjDlg::OnBnClickedSeqLoad)
	ON_BN_CLICKED(IDC_SEQ_FREE, &CEasyProjDlg::OnBnClickedSeqFree)
	ON_WM_DESTROY()
	ON_BN_CLICKED(IDC_RADIO_TR_POLARITY_HIGH, &CEasyProjDlg::OnBnClickedSynchPolarityHigh)
	ON_BN_CLICKED(IDC_RADIO_TR_POLARITY_LOW, &CEasyProjDlg::OnBnClickedSynchPolarityLow)
	ON_BN_CLICKED(IDC_SET_SEQ_PARAM, &CEasyProjDlg::OnBnClickedSetSeqParam)
	ON_BN_CLICKED(IDC_PROJ_START, &CEasyProjDlg::OnBnClickedProjStart)
	ON_BN_CLICKED(IDC_PROJ_STOP, &CEasyProjDlg::OnBnClickedProjStop)
	ON_WM_HSCROLL()
	ON_BN_CLICKED(IDC_RADIO_LED_NONE, &CEasyProjDlg::OnBnClickedRadioLedNone)
	ON_BN_CLICKED(IDC_RADIO_LED_RED, &CEasyProjDlg::OnBnClickedRadioLedRed)
	ON_BN_CLICKED(IDC_RADIO_LED_GREEN, &CEasyProjDlg::OnBnClickedRadioLedGreen)
	ON_BN_CLICKED(IDC_RADIO_LED_BLUE_TE, &CEasyProjDlg::OnBnClickedRadioLedBlueTe)
	ON_BN_CLICKED(IDC_RADIO_LED_UV, &CEasyProjDlg::OnBnClickedRadioLedUv)
	ON_BN_CLICKED(IDC_RADIO_LED_CBT_140_WHITE, &CEasyProjDlg::OnBnClickedRadioLedCbt140White)
END_MESSAGE_MAP()


// CEasyProjDlg message handlers

BOOL CEasyProjDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// Set the icon for this dialog. The framework does this automatically
	// when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon

	// -----
	UpdateElements();													// update all dialog elements from data
	// -----

	return TRUE;  // return TRUE  unless you set the focus to a control
}


void CEasyProjDlg::OnDestroy()
{
	// free sequence and projector before the application is finished
	m_Projector.SequenceFree();
	m_Projector.Free();

	CDialogEx::OnDestroy();
}


void CEasyProjDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	CDialogEx::OnSysCommand(nID, lParam);
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CEasyProjDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialogEx::OnPaint();
	}
}

// The system calls this function to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CEasyProjDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}


////////////////////////////////////////////////////////////////////////////////


// fill dialog elements with return code and error message
void CEasyProjDlg::SetProjectorReturnCodeMsg( const int retCode)
{
	m_ProjectorErrorCode.Format( _T("%d"), retCode);
	m_Projector.GetErrorMessage( retCode, m_ProjectorMessages.GetBuffer( 512), 512);
	m_ProjectorMessages.ReleaseBuffer();

	if( ALP_OK != retCode) MessageBeep( MB_ICONERROR );
}


// update all dialog elements from data
void CEasyProjDlg::UpdateElements(void)
{
	BOOL const bValidProjector = m_Projector.IsConnected(),
		bValidSeqence = bValidProjector && m_Projector.IsValidSequence();

	m_BtnProjectorAlloc.EnableWindow( !bValidProjector);
	m_BtnProjectorFree.EnableWindow( bValidProjector);
	
	m_RadioBtnSyncPolarityHigh.EnableWindow( bValidProjector);
	m_RadioBtnSyncPolarityLow.EnableWindow( bValidProjector);

	m_RadioBtnLEDTypeNone.EnableWindow( bValidProjector);
	m_RadioBtnLEDTypeRed.EnableWindow( bValidProjector);
	m_RadioBtnLEDTypeGreen.EnableWindow( bValidProjector);
	m_RadioBtnLEDTypeBlueTE.EnableWindow( bValidProjector);
	m_RadioBtnLEDTypeUV.EnableWindow( bValidProjector);
	m_RadioBtnLEDTypeCBT140White.EnableWindow( bValidProjector);

	m_sldLedBrightness.EnableWindow( m_Projector.Led(1).IsValid());

	m_BtnSequenceLoad.EnableWindow( bValidProjector && !bValidSeqence);
	m_BtnSeqFree.EnableWindow( bValidSeqence);
	m_EditIlluminateTime.EnableWindow( bValidSeqence);
	m_EditPictureTime.EnableWindow( bValidSeqence);
	m_EditSynchDelay.EnableWindow( bValidSeqence);
	m_EditSynchPulseWidth.EnableWindow( bValidSeqence);
	m_BtnProjection.EnableWindow( bValidSeqence);
	m_BtnProjStop.EnableWindow( bValidSeqence);
	m_BtnSet.EnableWindow( bValidSeqence);

	UpdateData( FALSE);													// update direction: data -> dialog elements
}


// free projector and reset dialog elements
const int CEasyProjDlg::FreeProjector(void)
{
	int ret = m_Projector.Free();
	m_ProjectorSerial = CString( L" ");									// delete the serial number
	m_iSyncPolarity = 0;
	m_iLEDType = 0;
	m_iLedBrightness = 0;

	return ret;
}


// get projector properties and update dialog elements
const int CEasyProjDlg::GetProjectorProperties(void)
{
	CProjector::CDevProperties prop;
	int ret = m_Projector.GetDevProperties( prop);
	if( ALP_OK == ret)
	{
		m_ProjectorSerial.Format( _T("%d"), prop.SerialNumber);
		switch( prop.Polarity)
		{
			case ALP_LEVEL_HIGH:	m_iSyncPolarity = 0; break;
			case ALP_LEVEL_LOW:		m_iSyncPolarity = 1; break;
			default: m_iSyncPolarity = 0; break;
		}
	}

	return ret;
}


// change synch polarity
const int CEasyProjDlg::SetSyncPolarity()
{
	long synchMode;
	UpdateData( TRUE);													// update direction: dialog elements -> data
	switch( m_iSyncPolarity)
	{
		case 0: synchMode = ALP_LEVEL_HIGH; break;
		case 1: synchMode = ALP_LEVEL_LOW; break;
		default: synchMode = ALP_LEVEL_HIGH; break; 
	}
	return m_Projector.SetSyncOutputMode( synchMode);
}


// set gates for LED control
const int CEasyProjDlg::SetGates( const int iGateIndex)
{
	tAlpDynSynchOutGate GateConfig;
	ZeroMemory( GateConfig.Gate, sizeof GateConfig.Gate );

	/* Disable 3 Gated Synch Outputs */
	GateConfig.Period = 0;
	GateConfig.Polarity = 1;
	m_Projector.SetSynchGate( 1, GateConfig );
	m_Projector.SetSynchGate( 2, GateConfig );
	m_Projector.SetSynchGate( 3, GateConfig );

	/* Re-Enable only the selected one */
	GateConfig.Period = 1;
	GateConfig.Polarity = 0;
	GateConfig.Gate[0] = 0;
	GateConfig.Gate[1] = 0;
	GateConfig.Gate[2] = 0;
	GateConfig.Gate[3] = 0;
	// ALP currently supports up to 16 Gate-Values

	int ret = m_Projector.SetSynchGate( iGateIndex, GateConfig);

	// In case of a running projection the changes gets effective even after Stop/Start of the projection.
	if( ALP_OK == ret
	&&	m_Projector.IsProjection())
	{
		m_Projector.ProjStop();
		m_Projector.ProjStartContinuous();
	}

	return ret;
}


// Sub-function
void CEasyProjDlg::BnClickedRadioLEDType()
{
	UpdateData( TRUE);													// update direction: dialog elements -> data
	int ret = SelectLEDType( m_iLEDType);
	if( ALP_OK != ret)
		m_iLEDType = 0;

	m_iLedBrightness = 0;
	SetLEDBrightness( m_iLedBrightness);
	UpdateElements();													// update all dialog elements from data
}


// select the LED type
const int CEasyProjDlg::SelectLEDType( const int iLedTypeIndex)
{
	m_Projector.Led(1).Free();

	if( iLedTypeIndex == CProjector::LEDTYPE_0_NONE) return ALP_OK;

	int ret = m_Projector.Led(1).Alloc( m_Projector.GetLedTypeByIndex( iLedTypeIndex), 0);

	return ret;
}


// change the LED brightness
const int CEasyProjDlg::SetLEDBrightness( const int iBrightness)
{
	int ret = m_Projector.Led(1).SetBrightness( iBrightness);

	return ret;
}


// free sequence and reset dialog elements
const int CEasyProjDlg::FreeSequence(void)
{
	int ret = ALP_OK;
	if( m_Projector.IsValidSequence())
	{
		ret = m_Projector.SequenceFree();
	}
	m_SequenceLoadedImages = CString( L" ");
	m_SequenceIlluminateTime = CString( L" ");
	m_SequencePictureTime = CString( L" ");
	m_SequenceSynchDelay = CString( L" ");
	m_SequenceSynchPulseWidth = CString( L" ");
	m_SequenceBitnum.Empty();

	return ret;
}


// get sequence properties
const int CEasyProjDlg::GetSequenceProperties(void)
{
	CProjector::CTimingEx timing;
	int ret = m_Projector.GetSeqProperties( timing);
	if( ALP_OK == ret)
	{
		m_SequenceIlluminateTime.Format( _T("%d"), timing.IlluminateTime);
		m_SequencePictureTime.Format( _T("%d"), timing.PictureTime);
		m_SequenceSynchDelay.Format( _T("%d"), timing.SynchDelay);
		m_SequenceSynchPulseWidth.Format( _T("%d"), timing.SynchPulseWidth);

		m_SequenceBitnum.Format( _T("%d"), timing.BitNum );
		if (timing.Uninterrupted) m_SequenceBitnum += _T(" uninterrupted");
	}
	return ret;
}


// change sequence properties
const int CEasyProjDlg::SetSequenceProperties(void)
{
	UpdateData( TRUE);													// update direction: dialog elements -> data

	CProjector::CTimingEx timing;
	timing.IlluminateTime = _wtol( m_SequenceIlluminateTime.GetBuffer( 16));
	m_SequenceIlluminateTime.ReleaseBuffer();

	timing.PictureTime = _wtol( m_SequencePictureTime.GetBuffer( 16));
	m_SequencePictureTime.ReleaseBuffer();

	timing.SynchDelay = _wtol( m_SequenceSynchDelay.GetBuffer( 16));
	m_SequenceSynchDelay.ReleaseBuffer();

	timing.SynchPulseWidth = _wtol( m_SequenceSynchPulseWidth.GetBuffer( 16));
	m_SequenceSynchPulseWidth.ReleaseBuffer();

	// m_SequenceBitnum is read-only

	return m_Projector.SelectMaxBitnum( timing );
}


// load images and add it to a sequence
const int CEasyProjDlg::LoadSequence(void)
{
	const LPCTSTR filter =
		_T("All Image Files|*.tif;*.tiff;*.png;*.gif;*.bmp;*.jpg;*.jpeg|")
		_T("TIF Files for Sequence (*.tif)|*.tif|")
		_T("TIFF Files for Sequence (*.tiff)|*.tiff|");
	CFileDialog dlg( TRUE, NULL, 0, OFN_PATHMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_EXPLORER|OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ENABLESIZING, filter);

	wchar_t buffer[1<<16];
	*buffer = '\0';

	dlg.m_pOFN->lpstrFile	= buffer;
	dlg.m_pOFN->nMaxFile	= sizeof(buffer)/sizeof(*buffer);

	int ret = ALP_OK;
	int nImages = 0;

	if(IDOK == dlg.DoModal())											// show file open dialog
	{
		// determine the sequence length
		for(POSITION pos = dlg.GetStartPosition(); NULL!=pos; )
		{
			CString fileNameLOAD = dlg.GetNextPathName(pos);
			nImages ++;
		}


		const int BitPlanes = 8;									// use all bitplanes for projection
		ret = m_Projector.SequenceAlloc( BitPlanes, nImages);		// create a sequence
		if( ALP_OK != ret)
			return ret;

		// read images from file, convert it and put it to the projector
		Gdiplus::Status status;
		int k = 0;	
		for(POSITION pos = dlg.GetStartPosition(); NULL!=pos; )
		{
			CString fileNameLOAD = dlg.GetNextPathName(pos);

			Gdiplus::Bitmap BmpLoaded( fileNameLOAD);			// read the image from file

			// create a new bitmap with projector dimensions
			std::auto_ptr<Gdiplus::Bitmap> pProjBmp(new Gdiplus::Bitmap( m_Projector.GetWidth(), m_Projector.GetHeight(), PixelFormat24bppRGB));
			Gdiplus::Graphics projGraphics( pProjBmp.get() );

			// create a 8bpp-sequence-image as bitmap with projector dimensions
			std::auto_ptr<Gdiplus::Bitmap> pSeqImageBmp(new Gdiplus::Bitmap( m_Projector.GetWidth(), m_Projector.GetHeight(), PixelFormat8bppIndexed));
	
			// create a bitmap for the preview with preview dimensions
			const int thumbWidth = 176;
			const int thumbHeight = 132;
			std::auto_ptr<Gdiplus::Bitmap> pThumbBmp(new Gdiplus::Bitmap( thumbWidth, thumbHeight, PixelFormat24bppRGB));
			Gdiplus::Graphics thumbGraphics(pThumbBmp.get());	// connect the drawing area with preview


			if( BmpLoaded.GetWidth() == pProjBmp->GetWidth()
				&&	BmpLoaded.GetHeight() == pProjBmp->GetHeight())
			{
				// resize not necessary -> clone the bitmap
				pProjBmp.reset(BmpLoaded.Clone( 0, 0, m_Projector.GetWidth(), m_Projector.GetHeight(), PixelFormat24bppRGB));
			}
			else
			{
				// draw bitmap into the drawing area of the sequence image, resize
				status = projGraphics.DrawImage( &BmpLoaded, 0, 0, m_Projector.GetWidth(), m_Projector.GetHeight());
			}

			if( pProjBmp->GetWidth() != pSeqImageBmp->GetWidth()
			||	pProjBmp->GetHeight() != pSeqImageBmp->GetHeight())
				break;

			// lock RGB image for read access
			Gdiplus::Rect lockRect( 0, 0, pProjBmp->GetWidth(), pProjBmp->GetHeight());	
			Gdiplus::BitmapData bitmapDataProj;		// image data
			pProjBmp->LockBits( &lockRect, Gdiplus::ImageLockModeWrite, PixelFormat24bppRGB, &bitmapDataProj);

			// lock 8bpp sequence image for write access
			Gdiplus::BitmapData bitmapData8bpp;		// image data
			pSeqImageBmp->LockBits( &lockRect, Gdiplus::ImageLockModeWrite, PixelFormat8bppIndexed, &bitmapData8bpp);

			BYTE *pImageDataProj = static_cast<BYTE*>(bitmapDataProj.Scan0);	// pointer to the first pixel of the first line (RGB image: source)
			BYTE *pImageData8bpp = static_cast<BYTE*>(bitmapData8bpp.Scan0);	// pointer to the first pixel of the first line (8bpp image: target)

			// transform pixel wise: RGB -> 8bpp
			for( size_t y=0; y < pProjBmp->GetHeight(); y++)
			{
				for( size_t x=0; x < pProjBmp->GetWidth(); x++)
				{
					pImageData8bpp[x] =	( pImageDataProj[ x*3]		// B
										+ pImageDataProj[ x*3+1]	// G
										+ pImageDataProj[ x*3+2]	// R
										) / 3;
				}
				pImageDataProj += bitmapDataProj.Stride;				// set pointer to the first pixel of the next line
				pImageData8bpp += bitmapData8bpp.Stride;				// set pointer to the first pixel of the next line
			}

			pImageData8bpp = static_cast<BYTE*>(bitmapData8bpp.Scan0);	// set pointer back to the first pixel of the first line (RGB image: source)
			ret = m_Projector.AddImage( pImageData8bpp, pSeqImageBmp->GetWidth(), pSeqImageBmp->GetHeight());		// upload image to the projector an add to sequence

			status = pProjBmp->UnlockBits(&bitmapDataProj);	// lock end
			status = pSeqImageBmp->UnlockBits(&bitmapData8bpp);	// lock end

			if( ALP_OK != ret)
				break;

			m_SequenceLoadedImages.Format( _T("%d"), k+1);	// update dialog element with current image counter

			// draw BmpLoaded in the drawing area of the preview
			status = thumbGraphics.DrawImage( &BmpLoaded, 0, 0, thumbWidth, thumbHeight);	
			HBITMAP hBmp = 0;
			status = pThumbBmp->GetHBITMAP( Gdiplus::Color(0,0,0), &hBmp);	// get bitmap handle
			DeleteObject(m_Preview.SetBitmap( hBmp ));	// draw the preview, dereference previous bitmap
			DeleteObject(hBmp);

			k++;
		}
	}
	return ret;
}

////////////////////////////////////////////////////////////////////////////////


void CEasyProjDlg::OnBnClickedProjAlloc()
{
	int ret = m_Projector.Alloc();

	if( ALP_OK == ret)
		ret = GetProjectorProperties();

	for( size_t i = 1; i <= 3; i++)
	{
		if( ALP_OK == ret)
			ret = SetGates( i);

		if( m_Projector.TestLedExistence())
			break;
	}

	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnBnClickedProjFree()
{
	m_iLedBrightness = 0;
	SetLEDBrightness( m_iLedBrightness);
	SelectLEDType( CProjector::LEDTYPE_0_NONE);
	m_Projector.ProjStop();
	FreeSequence();

	int ret = FreeProjector();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnBnClickedSynchPolarityHigh()
{
	int ret = SetSyncPolarity();
	GetProjectorProperties();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnBnClickedSynchPolarityLow()
{
	int ret = SetSyncPolarity();
	GetProjectorProperties();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}



void CEasyProjDlg::OnBnClickedRadioLedNone()
{
	BnClickedRadioLEDType();
}
void CEasyProjDlg::OnBnClickedRadioLedRed()
{
	BnClickedRadioLEDType();
}
void CEasyProjDlg::OnBnClickedRadioLedGreen()
{
	BnClickedRadioLEDType();
}
void CEasyProjDlg::OnBnClickedRadioLedBlueTe()
{
	BnClickedRadioLEDType();
}
void CEasyProjDlg::OnBnClickedRadioLedUv()
{
	BnClickedRadioLEDType();
}
void CEasyProjDlg::OnBnClickedRadioLedCbt140White()
{
	BnClickedRadioLEDType();
}


void CEasyProjDlg::OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{
	switch (nSBCode)
	{
		case SB_ENDSCROLL:   // End scroll.
			UpdateData( TRUE);											// update direction: dialog elements -> data
			SetLEDBrightness( m_iLedBrightness);
			break;
	}

	CDialogEx::OnHScroll(nSBCode, nPos, pScrollBar);
}


void CEasyProjDlg::OnBnClickedSeqLoad()
{
	int ret = LoadSequence();
	GetSequenceProperties();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnBnClickedSeqFree()
{
	int ret = FreeSequence();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnBnClickedSetSeqParam()
{
	int ret = SetSequenceProperties();

	// In case of a running projection the changes gets effective even after Stop/Start of the projection.
	if( ALP_OK == ret
	&&	m_Projector.IsProjection())
	{
		m_Projector.ProjStop();
		m_Projector.ProjStartContinuous();
	}

	// After successful timing setup, report effective settings. These values could
	// differ from input in case of inconsistent parameters or ALP_DEFAULT.
	// On failure the user interface parameters shall be adjustable individually, so they are not overwritten.
	if (ALP_OK==ret)
		GetSequenceProperties();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnBnClickedProjStart()
{
	int ret = m_Projector.ProjStartContinuous();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnBnClickedProjStop()
{
	int ret = m_Projector.ProjStop();
	SetProjectorReturnCodeMsg( ret);
	UpdateElements();													// update all dialog elements from data
}


void CEasyProjDlg::OnOK()
{
	OnBnClickedSetSeqParam();
}




void CEasyProjDlg::WinHelp(DWORD dwData, UINT nCmd)
{
	UNREFERENCED_PARAMETER( (dwData, nCmd) );

	MessageBox(
		_T("1. An introduction to EasyProj can be found in the ALP Quick Start Guide.\r\n")
		_T("2. Select the correct LED type in order to avoid overload and damage.\r\n")
		_T("3. Sequence Timing automatically corrects inconsistent parameters.\r\n")
		_T("4. Please read the source code and the ALP API description for details."),
		_T("ALP EasyProj - ViALUX GmbH")
		);
}
