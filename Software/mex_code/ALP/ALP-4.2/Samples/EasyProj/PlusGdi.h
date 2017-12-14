// PlusGdi.h
//
#ifndef	_PLUS_GDI_H_
#define	_PLUS_GDI_H_

#include <gdiplus.h>					// Gdiplus...
#pragma	comment(lib, "gdiplus.lib")		// interface for 'gdiplus.dll'

#define	GDIPLUS_APP	MyGdiplus::CGdiplusApp theGdiplusApp

namespace MyGdiplus
{	// BEGIN namespace MyGdiplus
/////////////////////////////////////////////////////////////////////////////

class CGdiplusApp
{
public:
	CGdiplusApp()
	{	// Initialize GDI+.
		Gdiplus::GdiplusStartup(&m_GdiplusToken, &m_GdiplusStartupInput, NULL);
	}
	~CGdiplusApp()
	{	// End GDI+
		Gdiplus::GdiplusShutdown(m_GdiplusToken);
	}

private:
	Gdiplus::GdiplusStartupInput	m_GdiplusStartupInput;
	ULONG_PTR						m_GdiplusToken;
};

/////////////////////////////////////////////////////////////////////////////
}	// END namespace MyGdiplus

#endif	// _PLUS_GDI_H_