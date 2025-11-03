// LE = Locale Emulator
// Since LE uses LGPLv3 license while tswKai3 uses MIT license, no source code from LE is integrated into this project;
// Rather, compiled locale emulator core DLLs (located in the "LE" subfolder) are directly used and loaded.
// https://github.com/xupefei/Locale-Emulator-Core
#include "tswLauncher.h"
extern DWORD winVer; extern HWND hWndMain; // from gui.c
extern char cur_path[], tsw_exe_path[]; // from tswLauncher.c

typedef char __Undefined;

typedef struct {
  ULONG AnsiCodePage;
  ULONG OemCodePage;
  ULONG LocaleID;
  ULONG DefaultCharset;
  ULONG HookUILanguageApi;
  WCHAR dummy[LF_FACESIZE]; // DefaultFaceName (not used)
  __Undefined Timezone[172]; // RTL_TIME_ZONE_INFORMATION (but we don't care)
  ULONG64 NumberOfRegistryRedirectionEntries;
  // REGISTRY_REDIRECTION_ENTRY64 RegistryReplacement[NumberOfRegistryRedirectionEntries] ... (but we don't care)
} LOCALE_ENUMLATOR_ENVIRONMENT_BLOCK;

typedef DWORD WINAPI _LeCreateProcess(LOCALE_ENUMLATOR_ENVIRONMENT_BLOCK* Leb, WCHAR* ApplicationName, WCHAR* CommandLine, const WCHAR* CurrentDirectory, ULONG CreationFlags, STARTUPINFOW* StartupInfo, PROCESS_INFORMATION* ProcessInformation, SECURITY_ATTRIBUTES* ProcessAttributes, SECURITY_ATTRIBUTES* ThreadAttributes, void* Environment, HANDLE Token); // prototype of CreateProcess with Locale Emulator

#define CP_SHIFTJIS 932
#define CP_GB2312 936
#ifndef _WIN32_WINNT_WIN7 // in case the macro is not defined in <Windows.h>...
#define _WIN32_WINNT_WIN7 0x0601
#endif

/**
 * Based on the specified type and other information, determines whether to initialize the LeCreateProcess call pointer:
 * Not initialized if the system does not meet the lowest requirement or is already using the correct locale.
 *
 * @param type An integer representing the type of TSW to launch (0-based index of the selected item in the main dialog combobox).
 * @return Pointer to the LeCreateProcess API call, or NULL if not needed.
 */
static _LeCreateProcess* initLE(int type) {
  if (winVer < MAKELONG(1, _WIN32_WINNT_WIN7)) // must be Windows 7, Service pack 1, or later
    return NULL;

  UINT cp = GetACP();
  switch (type) {
  case 0: // English (Original Ver)
    if (cp == CP_SHIFTJIS)
      return NULL; // no need to emulate locale for Japanese system
    break;
  case 1: // English (Retranslated Ver)
    return NULL; // no need to emulate locale
  case 2: // Chinese Ver
  case 3: // Chinese (Retranslated Ver)
    if (cp == CP_GB2312)
      return NULL; // no need to emulate locale for Chinese system
  }

  HMODULE hDll = LoadLibrary("LE\\Loader.dll");
  if (!hDll)
    return NULL;
  return (_LeCreateProcess*)GetProcAddress(hDll, "LeCreateProcess");
}

/**
 * Creates a process with or without Locale Emulator (i.e., using LeCreateProcess or CreateProcess) based on the selected TSW type
 * and if successful, fills the PROCESS_INFORMATION structure with details about the newly created process.
 *
 * @param type An integer representing the type of TSW to launch (0-based index of the selected item in the main dialog combobox).
 * @param p_pi Pointer to a PROCESS_INFORMATION structure that will receive information about the created process.
 * @return Non-zero if the process was created successfully, or FALSE otherwise.
 */
BOOL CreateProcessLE(int type, PROCESS_INFORMATION* p_pi) {
  STARTUPINFO si = {sizeof(si)};
  si.dwFlags = STARTF_FORCEONFEEDBACK;

  _LeCreateProcess* LeCreateProcess = initLE(type);
  if (LeCreateProcess) {
    // LeCreateProcess requires wide char input
    WCHAR tsw_exe_path_w[MAX_PATH], cur_path_w[MAX_PATH];
    if (!MultiByteToWideChar(CP_ACP, MB_ERR_INVALID_CHARS, tsw_exe_path, -1, tsw_exe_path_w, MAX_PATH))
      goto plain_create_process;
    if (!MultiByteToWideChar(CP_ACP, MB_ERR_INVALID_CHARS, cur_path, -1, cur_path_w, MAX_PATH))
      goto plain_create_process;

    LOCALE_ENUMLATOR_ENVIRONMENT_BLOCK leb = {0};
    if (type == 0) {
      if (msgbox(hWndMain, MB_ICONINFORMATION | MB_YESNO | MB_DEFBUTTON2, IDS_INFO_EMULATE_LOCALE) == IDNO)
        goto plain_create_process;
      leb.AnsiCodePage = CP_SHIFTJIS;
      leb.OemCodePage = CP_SHIFTJIS;
      leb.LocaleID = ID_ja_JP;
      leb.DefaultCharset = SHIFTJIS_CHARSET;
    } else {
      if (msgbox(hWndMain, MB_ICONINFORMATION | MB_YESNO, IDS_INFO_EMULATE_LOCALE) == IDNO)
        goto plain_create_process;
      leb.AnsiCodePage = CP_GB2312;
      leb.OemCodePage = CP_GB2312;
      leb.LocaleID = ID_zh_CN;
      leb.DefaultCharset = GB2312_CHARSET;
    }
    return !LeCreateProcess(&leb, tsw_exe_path_w, NULL, cur_path_w, 0, (STARTUPINFOW*)&si, p_pi, NULL, NULL, NULL, NULL); // unlike CreateProcess, LeCreateProcess returns 0 on success
  } else
plain_create_process:
  return CreateProcess(tsw_exe_path, NULL, NULL, NULL, FALSE, 0, NULL, cur_path, &si, p_pi);
}
