
#pragma once
#include "stdafx.h"

// Output a prompt: "Press any key", wait for a key.
void Pause();
// Output a sPrompt, wait for user to enter a key from sChoices,
// return the pressed character from sChoices or VK_ESCAPE on ESC
TCHAR Choice( LPCTSTR sPrompt, LPCTSTR sChoices, bool const bIgnoreCase );

// Convert nAlpResult to a string and write it to a user-supplied buffer.
// For convenience return the buffer pointer.
LPCTSTR AlpErrorString( LPTSTR buffer, size_t const SizeOfBufferInTchar, long const nAlpResult );
template <size_t size> LPCTSTR AlpErrorString( TCHAR (&buffer)[size], long const nAlpResult )
{ return AlpErrorString(buffer, size, nAlpResult); }

// If nAlpResult is ALP_OK, then simply return false (no error).
// Else, output an error message (including sAlpCommand and AlpErrorString(nAlpResult)
// and return true (error)
bool AlpError(long const nAlpResult,
	LPCTSTR sAlpCommand,
	bool bEchoSuccess /* also output a message in case of success? */  );

// Return a string describing the LED type (ALP_HLD_...).
// Return NULL, if the LED type is unknown.
LPCTSTR AlpLedTypeName(long const nApiValue);
// Ask the user to enter a LED type
long AlpLedTypePrompt();

// Ask the user to enter a percentage value (0..100)
long AlpPercentPrompt(LPCTSTR sPrompt);

// class CConsolePosition
class CConsolePosition {
public:
	CConsolePosition(void);
	void Restore() const;
private:
	COORD m_pos;
};
