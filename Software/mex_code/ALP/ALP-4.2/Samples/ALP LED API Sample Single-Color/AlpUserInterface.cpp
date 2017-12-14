
#include "AlpUserInterface.h"
#include "alp.h"
#include <conio.h>

void Pause() {
	_tprintf( _T("Press any key") );
	while (_kbhit()) _gettch();	// clear keyboard buffer
	_gettch();
}

LPCTSTR AlpErrorString( LPTSTR buffer, size_t const SizeOfBufferInTchar, long const nAlpResult )
{
	// use a pre-processor macro and Stringizing Operator (#)
	// to consistently convert named numerical values to strings
	#define ALP_ERROR_STRING( constant ) case constant: _sntprintf_s( buffer, SizeOfBufferInTchar, _TRUNCATE, _T("%s"), _T(#constant) ); break
	switch (nAlpResult) {
	ALP_ERROR_STRING(ALP_OK);
	ALP_ERROR_STRING(ALP_NOT_ONLINE);
	ALP_ERROR_STRING(ALP_NOT_IDLE);
	ALP_ERROR_STRING(ALP_NOT_AVAILABLE);
	ALP_ERROR_STRING(ALP_NOT_READY);
	ALP_ERROR_STRING(ALP_PARM_INVALID);
	ALP_ERROR_STRING(ALP_ADDR_INVALID);
	ALP_ERROR_STRING(ALP_MEMORY_FULL);
	ALP_ERROR_STRING(ALP_SEQ_IN_USE);
	ALP_ERROR_STRING(ALP_HALTED);
	ALP_ERROR_STRING(ALP_ERROR_INIT);
	ALP_ERROR_STRING(ALP_ERROR_COMM);
	ALP_ERROR_STRING(ALP_DEVICE_REMOVED);
	ALP_ERROR_STRING(ALP_NOT_CONFIGURED);
	ALP_ERROR_STRING(ALP_LOADER_VERSION);
	ALP_ERROR_STRING(ALP_ERROR_POWER_DOWN);
	default: _sntprintf_s( buffer, SizeOfBufferInTchar, _TRUNCATE, _T("ALP Error %i"), nAlpResult );
	}
	#undef ALP_ERROR_STRING

	return buffer;
}

bool AlpError(long const nAlpResult, LPCTSTR sAlpCommand, bool bEchoSuccess )
{
	TCHAR strMessageBuf[30] = {0};

	if (ALP_OK==nAlpResult) {
		if (bEchoSuccess)
			_tprintf( _T("Ok: %s\r\n"), sAlpCommand );
		return false;	// No error.
	} else {
		_tprintf( _T("ERROR: %s returns %s\r\n"), sAlpCommand, AlpErrorString(strMessageBuf, nAlpResult) );
		return true;	// Error
	}
}

long const gAlpLedTypes[] = {
	ALP_HLD_PT120_RED, ALP_HLD_PT120_GREEN, ALP_HLD_PT120TE_BLUE, ALP_HLD_PT120_BLUE,
	ALP_HLD_CBT90_UV, ALP_HLD_CBT120_UV,
	ALP_HLD_CBT90_WHITE, ALP_HLD_CBT140_WHITE,
};
// Returns NULL, if the LED type is unknown
LPCTSTR AlpLedTypeName(long const nApiValue)
{
	switch (nApiValue) {
	default: return NULL;
	case ALP_HLD_PT120_RED: return _T("PT120_RED");
	case ALP_HLD_PT120_GREEN: return _T("PT120_GREEN");
	case ALP_HLD_PT120_BLUE: return _T("PT120_BLUE");
	case ALP_HLD_CBT90_UV: return _T("CBT90_UV");
	case ALP_HLD_CBT120_UV: return _T("CBT120_UV");
	case ALP_HLD_CBT90_WHITE: return _T("CBT90_WHITE");
	case ALP_HLD_PT120TE_BLUE: return _T("PT120TE_BLUE");
	case ALP_HLD_CBT140_WHITE: return _T("CBT140_WHITE");
	};
}

long AlpLedTypePrompt() {
	// First output a list of all known LED types
	size_t Index;
	for (Index=0; Index<_countof(gAlpLedTypes); Index++)
		_tprintf( _T("%c: %s\r\n"), _T('a')+Index, AlpLedTypeName(gAlpLedTypes[Index]) );
	_tprintf( _T("Press a key to select one...") );
	// then let the user select one
	for (;;) {
		TCHAR cKey = _totlower(_gettch());
		if (cKey==VK_ESCAPE) {
			_tprintf( _T("ESC\r\n") );
			return 0;	// ESC
		}

		Index = cKey-_T('a');
		// ... but only return valid indexes
		if (Index>=0 && Index<_countof(gAlpLedTypes)) {
			_tprintf( _T("%s\r\n"), AlpLedTypeName(gAlpLedTypes[Index]) );
			return gAlpLedTypes[Index];
		} else
			_tprintf( _T("%c\b\a"), cKey );
	}
}

long AlpPercentPrompt(LPCTSTR sPrompt) {
	long nPercent(10);
	do {
		_tprintf( _T("%s"), sPrompt );
		_tscanf_s( _T("%i"), &nPercent );
	} while (nPercent<0 || nPercent>100);
	return nPercent;
}

