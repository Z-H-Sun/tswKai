#include "tswLauncher.h"
#include <gdiplus.h>

ULONG_PTR gpToken;
GpFontCollection* gpfc = NULL;

// Initializes the GDI+ library and retrieves the installed font collection.
// This function sets global variables `gpToken` and `gpfc` for later use (NULL if failed).
void initGdip() {
  GdiplusStartupInput gdiplusStartupInput = {1, NULL, FALSE, FALSE};
  if (GdiplusStartup(&gpToken, &gdiplusStartupInput, NULL) == Ok) {
    if (GdipNewInstalledFontCollection(&gpfc) == Ok)
      return;
  // failed cases
    GdiplusShutdown(gpToken);
  }
  gpToken = 0;
  gpfc = NULL;
}

/**
 * Retrieves the font name for a specified language.
 *
 * @param fontName      Pointer to the input font name (wide string).
 * @param lang          Language identifier (WORD).
 * @param outFontName   Pointer to the buffer where the output font name will be stored (wide string).
 * @return              TRUE if the font name for the specified language was successfully retrieved;
 *                      otherwise, -1 if no such font was found, or FALSE if GDI+ encounters an error.
 */
BOOL getFontNameLang(WCHAR* fontName, WORD lang, WCHAR* outFontName) {
  if (!gpfc) return FALSE;
  GpFontFamily* gpff;
  GpStatus ret = GdipCreateFontFamilyFromName(fontName, gpfc, &gpff);
  if (ret != Ok) {
    if (ret == FontFamilyNotFound) return CB_ERR;
    return FALSE;
  }
  ret = GdipGetFamilyName(gpff, outFontName, lang);
  GdipDeleteFontFamily(gpff);
  return (ret == Ok);
}
