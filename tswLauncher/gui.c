#include "gui.h"

HWND hWndMain = NULL, hWndConf = NULL;
HINSTANCE hIns = NULL;
HANDLE hMapFile = NULL;
LPVOID p_mutex = NULL;
RECT rcDlg = {0};
WCHAR tooltip_descr[256]; // this has to be a static pointer because it will be assigned to NMTTDISPINFOW.lpszText and thus shouldn't be a local variable
WCHAR app_title[MAX_PATH+1] = WT(APP_TITLE); // note: app_title[0] is (WORD)length; the actual unicode string starts from app_title+1
BOOL is_chinese;
DLGTEMPLATE *pDlg_old[3] = {NULL}, *pDlg_new[3] = {NULL};
DWORD szDlg[3], dimDlgWin[3];
DWORD winVer;

int msgbox(HWND hwnd, unsigned int uType, unsigned int uID, ...) {
  WCHAR buffer[512];
  DWORD lang = APP_LANGUAGE;
  va_list args;
  va_start(args, uID);
  if (!FormatMessageW(FORMAT_MESSAGE_FROM_HMODULE, NULL, uID, lang, buffer, sizeof(buffer), &args)) { // failed (unlikely)
    // fallback on generic treatment of simple error message
    size_t len = (is_chinese ? sizeof(FAIL_FORMAT_MSG_CN) : sizeof(FAIL_FORMAT_MSG_EN))-sizeof(WCHAR); // in bytes, not including the trailing \0\0
    memcpy(buffer, is_chinese ? FAIL_FORMAT_MSG_CN : FAIL_FORMAT_MSG_EN, len); // fallback error message
    _itow(uID, (WCHAR*)((char*)buffer+len), 10); // error message number
  }
  va_end(args);

  uType |= MB_SETFOREGROUND; // always set as foreground
  if (!hwnd) { // if NULL: default value
    hwnd = hWndMain;
  }
  if (!hwnd || hwnd == HWND_TOPMOST || !IsWindowVisible(hwnd)) { // if no main window, set msgbox window as top most
    hwnd = NULL;
    uType |= MB_TOPMOST;
  }
  int ret = MessageBoxExW(hwnd, buffer, app_title+1, uType, lang); // first try the app-defined language
  if (!ret) ret = MessageBoxW(hwnd, buffer, app_title+1, uType); // if failed, then use the system language
  return ret;
}

static WCHAR* _LoadStringLang(DWORD id, WORD lang) {
  HRSRC hrsrc = FindResourceEx(hIns, RT_STRING, MAKEINTRESOURCE(id / 16 + 1), lang); // String tables are broken up into "bundles" of 16 strings each
  if (!hrsrc) return NULL;
  WCHAR* pWch = LoadResource(hIns, hrsrc);
  if (!pWch) return NULL;
  for (id &= 0xF; id; id--) // Now skip over the strings in the resource until we hit the one we want. Each entry is a counted string, just like Pascal
    pWch += *pWch + 1;
  return pWch;
}

static size_t LoadStringLangW(DWORD id, WORD lang, WCHAR* buf) { // be careful: make sure `buf` is large enough; will not check length to copy to it
  WCHAR* pWch = _LoadStringLang(id, lang);
  if (!pWch) { msgbox(NULL, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"FindResourceEx"); buf[0] = L'\0'; return 0; } // fail
  size_t len = *pWch;
  buf[len] = L'\0'; // the original string in the resource table is not terminated with \0\0; must copy out to `buf` and manually terminate it
  memcpy(buf, pWch+1, len*sizeof(WCHAR));
  return len;
}

/*
static size_t LoadStringLangA(DWORD id, WORD lang, char buf[MAX_PATH]) { // be careful: the source string should be shorter than 260 bytes, and `buf` should be large enough; will not run checks
  WCHAR* pWch = _LoadStringLang(id, lang);
  if (!pWch) { msgbox(NULL, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"FindResourceEx"); buf[0] = '\0'; return 0; } // fail
  size_t len = *pWch;
  len = WideCharToMultiByte(CP_ACP, 0, pWch+1, len, buf, MAX_PATH-1, NULL, NULL);
  buf[len] = '\0'; // terminate string; note: MSDN: `WideCharToMultiByte` won't automatically terminate the string if `cchWideChar` is not -1
  if (!len)
    msgbox(NULL, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"WideCharToMultiByte");
  return len;
}
*/

static void setDlgFont(int i, WCHAR* fontName, size_t fontNameLen, WORD fontSize) { // inspired by CDialogTemplate::SetFont: https://github.com/mirror/winscp/blob/22fdfe5692ce9cf209807026d63a9d2be2279a72/libs/mfc/source/dlgtempl.cpp#L284
// fontNameLen: in bytes, including the trailing \0\0
  WORD* pFont = (WORD*)(pDlg_old[i] + 1);
  if (*pFont == (WORD)-1) // Skip menu name string or ordinal
    pFont += 2; // WORDs
  else
    while (*pFont++);
  if (*pFont == (WORD)-1) // Skip class name string or ordinal
    pFont += 2; // WORDs
  else
    while(*pFont++);
  while (*pFont++); // Skip caption string

  size_t cbHeader = (char*)pFont - (char*)(pDlg_old[i]);
  size_t cbOldFont = wcslen((WCHAR*)(pFont+1))+1; // length of old font name (in WCHARs)
  size_t cbNewFont = sizeof(WORD) + fontNameLen; // first WORD: fontSize; next WCHARs: unicode string of fontName
  cbOldFont = (1 + cbOldFont) * sizeof(WCHAR); // actual font structure length (fontSize and fontName, in bytes)
  char* pOldControls = (char*)(((uintptr_t)pFont + cbOldFont + 3) & ~3);
  char* pNewControls = (char*)(((uintptr_t)pFont + cbNewFont + 3) & ~3); // alignment

  char* pbDlg_new = malloc(pNewControls - pOldControls + szDlg[i]);
  memcpy(pbDlg_new, pDlg_old[i], cbHeader);
  pDlg_new[i] = (DLGTEMPLATE*)pbDlg_new;
  pbDlg_new += cbHeader;
  *(WORD*)pbDlg_new = fontSize;
  pbDlg_new += 2;
  memcpy(pbDlg_new, fontName, fontNameLen);
  memcpy(pNewControls - (char*)(pDlg_old[i]) + (char*)(pDlg_new[i]), pOldControls, szDlg[i] - (pOldControls - (char*)(pDlg_old[i])));
}

static void createMutex() {
  if (! (hMapFile = CreateFileMapping(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, APP_MUTEX_BUFSIZE, APP_MUTEX)) ) {
    msgbox(HWND_TOPMOST, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"CreateFileMapping");
    return; // could not create file mapping object
  }
  if (! (p_mutex = MapViewOfFile(hMapFile, FILE_MAP_WRITE, 0, 0, APP_MUTEX_BUFSIZE)) ) {
    CloseHandle(hMapFile);
    msgbox(HWND_TOPMOST, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"MapViewOfFile");
    return; // could not map view of file
  }
  MUTEXINFO *minfo = p_mutex;
  minfo->pid = GetCurrentProcessId();
  minfo->hwnd = hWndMain;
}

static void checkMutex() {
  if (! (hMapFile = OpenFileMapping(FILE_MAP_READ, FALSE, APP_MUTEX)) ) {
    createMutex(); // no other tswLauncher instance running
    return;
  }
  if (! (p_mutex = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, APP_MUTEX_BUFSIZE)) ) {
    CloseHandle(hMapFile);
    msgbox(HWND_TOPMOST, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"MapViewOfFile");
    return; // could not map view of file
  }
  MUTEXINFO *minfo = p_mutex;
  hWndMain = minfo->hwnd;
  if (!IsWindowVisible(hWndMain)) {
    msgbox(HWND_TOPMOST, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"IsWindowVisible");
    return; // somehow the window is invalid or invisible
  }
  SetWindowPos(hWndMain, 0, rcDlg.left, rcDlg.top, 0, 0, SWP_NOZORDER | SWP_NOSIZE | SWP_NOACTIVATE);
  HWND hwnd = GetLastActivePopup(hWndMain); // the real active child window
  msgbox(hwnd, MB_ICONINFORMATION, IDS_ERR_APP_RUNNING, is_chinese ? WT(APP_TITLE_CN) : WT(APP_TITLE), minfo->pid);
  safe_exit(1);
}

void centerTSW(HWND hwndTSW) {
  RECT rcTSW;
  GetWindowRect(hwndTSW, &rcTSW);
  SetWindowPos(hwndTSW, 0, (rcDlg.left+rcDlg.right+rcTSW.left-rcTSW.right)/2, (rcDlg.top+rcDlg.bottom+rcTSW.top-rcTSW.bottom)/2, 0, 0, SWP_NOZORDER | SWP_NOSIZE | SWP_NOACTIVATE);
}

BOOL checkTSWrunning() {
  HWND hwndTSW = FindWindow(TARGET_CLS_NAME, NULL);
  DWORD pidTSW = 0;
  if (!hwndTSW)
    return FALSE;
  centerTSW(hwndTSW);
  GetWindowThreadProcessId(hwndTSW, &pidTSW);
  hwndTSW = GetWindow(hwndTSW, GW_OWNER); // TApplication (owner window)
  ShowWindow(hwndTSW, SW_SHOWNOACTIVATE); // this will restore the TSW window if it is minimized
  hwndTSW = GetLastActivePopup(hwndTSW); // the real active child window
  msgbox(hwndTSW, MB_ICONINFORMATION, IDS_ERR_APP_RUNNING, is_chinese ? WT(TARGET_TITLE_CN) : WT(TARGET_TITLE), pidTSW);
  if (!hWndMain) // if NULL, this check is done during startup of this app; otherwise, when the Launch button is clicked
    safe_exit(1);
  return TRUE;
}

void pre_exit() {
  if (p_mutex) {
    UnmapViewOfFile(p_mutex);
    CloseHandle(hMapFile);
  }
  if (pDlg_new[0]) free(pDlg_new[0]);
  if (pDlg_new[1]) free(pDlg_new[1]);
  if (pDlg_new[2]) free(pDlg_new[2]);
}

void safe_exit(int status) {
  pre_exit();
  exit(status);
}

static int CALLBACK EnumFontFamProc(ENUMLOGFONTW *lpelfe, NEWTEXTMETRICW *lpntme, DWORD FontType, LPARAM lParam) {
    return 0;
}

static HWND createTooltipWnd(HWND hWndParent, TOOLINFOW* p_toolInfo) {
    HWND hWndTip = CreateWindowExW(0, WT(TOOLTIPS_CLASS), NULL, WS_POPUP | TTS_ALWAYSTIP, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, hWndParent, NULL, hIns, NULL);
    SendMessageW(hWndTip, TTM_SETMAXTIPWIDTH, 0, 320); // allow text wrap and multiline
    SendMessageW(hWndTip, TTM_SETDELAYTIME, TTDT_INITIAL, 0);
    SendMessageW(hWndTip, TTM_SETDELAYTIME, TTDT_RESHOW, 0);
    SendMessageW(hWndTip, TTM_SETDELAYTIME, TTDT_AUTOPOP, 0x7FFF); // largest possible delay because the HIWORD must be zero
    p_toolInfo->hwnd = hWndParent;
    p_toolInfo->uFlags = TTF_IDISHWND | TTF_SUBCLASS;
    p_toolInfo->lpszText = LPSTR_TEXTCALLBACKW; // instead of setting a fixed description text here, this will send TTN_NEEDTEXTW notification, allowing dynamically changing icon / title, which is otherwise impossible (since after such changes, the tooltip window size needs to be recalculated, so intercepting TTN_SHOW is not enough; have to do this in an earlier stage)
    // Ref: https://www.codeproject.com/Articles/12328/Displaying-a-Title-and-an-Icon-in-a-ToolTip-window
    return hWndTip;
}

static LRESULT CALLBACK dialog_conf_proc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  switch ( message ) {
  case WM_INITDIALOG:
    hWndConf = hwnd;
    return TRUE;
  case WM_COMMAND:
    // TODO
  case WM_CLOSE:
    EndDialog(hwnd, IDCANCEL);
    return TRUE;
  }
  return FALSE;
}

static LRESULT CALLBACK dialog_main_proc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  WCHAR buf[32]; // this buffer is used to load combobox items and button names, so 16 TCHARs is enough space
  switch ( message ) {
  case WM_INITDIALOG:
    GetWindowRect(hwnd, &rcDlg);

    checkTSWrunning();
    hWndMain = hwnd;
    checkMutex();
    init_path();

    SendMessageW(hwnd, WM_SETICON, (WPARAM)ICON_BIG, // according to MSDN, icons loaded with LR_SHARED need not to be disposed of
      (LPARAM)LoadImage(hIns, MAKEINTRESOURCE(IDI_APP), IMAGE_ICON, 0, 0, LR_DEFAULTCOLOR | LR_DEFAULTSIZE | LR_SHARED));
    SetWindowTextW(hwnd, app_title+1);

    // set button image (this will only work for Windows Vista+, i.e., XP won't work)
    // comctl32 v6 can't add monochrome images, so make them 16-color (ref: https://www.virtualdub.org/blog2/entry_331.html)
    if (LOWORD(winVer) >= _WIN32_WINNT_VISTA) {
      RECT btn_margin = {5, 1, 1, 1};
      for (int i = IDC_OPEN; i <= IDC_CONF; ++i) {
        SendDlgItemMessageW(hwnd, i, BM_SETIMAGE, (WPARAM)IMAGE_ICON,
          (LPARAM)LoadImage(hIns, MAKEINTRESOURCE(IDI_OPEN-IDC_OPEN + i), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR | LR_SHARED));
        SendDlgItemMessageW(hwnd, i, BCM_SETTEXTMARGIN, 0, (LPARAM)&btn_margin); // increase margin between image and text
      }
    }

    // add combobox entries
    DWORD lang = APP_LANGUAGE;
    for (int i = IDS_ENTRY_TYPE_EN; i <= IDS_ENTRY_TYPE_CN_REV; ++i) {
      LoadStringLangW(i, lang, buf);
      SendDlgItemMessageW(hwnd, IDC_TYPE, CB_ADDSTRING, (WPARAM)0, (LPARAM)buf);
    }

    // select default entry
    SetComboboxVal(IDC_TYPE, is_chinese ? 2 : 1);

    // create tooltips
    TOOLINFOW toolInfo = {sizeof(toolInfo)};
    HWND hwndTip = createTooltipWnd(hwnd, &toolInfo);
    for (int i = IDC_BEGIN; i <= IDC_END; ++i) {
      toolInfo.uId = (UINT_PTR)GetDlgItem(hwnd, i);
      SendMessageW(hwndTip, TTM_ADDTOOLW, 0, (LPARAM)&toolInfo);
    }

    return TRUE;
  case WM_MIGRATE: // delayed processing for startup migration
    ShowWindow(hwnd, SW_SHOWNOACTIVATE); // make sure dialog window is visible
    migrate_data();
    return TRUE;
  case WM_DESTROY:
    pre_exit();
    return TRUE;
  case WM_CLOSE:
    EndDialog(hwnd, IDCANCEL);
    return TRUE;
  case WM_NOTIFY: // tooltip pops up; provide tooltip title and text
    ; // low version GCC doesn't allow a declaration immediately after a label (error: a label can only be part of a statement and a declaration is not a statement). Fine, let's make it happy
    NMTTDISPINFOW* info = (NMTTDISPINFOW*)lparam;
    if (info->hdr.code != TTN_NEEDTEXTW)
      return TRUE;
    int id = GetDlgCtrlID((HWND)wparam);
    if (id == IDC_TYPE)
      SendMessageW(info->hdr.hwndFrom, TTM_SETTITLEW, TTI_INFO, (LPARAM)DROPDOWNLIST_NAME_APP);
    else {
      GetWindowTextW((HWND)wparam, buf, sizeof(buf)/sizeof(WCHAR));
      wcscat(buf, BUTTON_NAME_APP);
      SendMessageW(info->hdr.hwndFrom, TTM_SETTITLEW, TTI_INFO, (LPARAM)buf);
    }
    LoadStringLangW(IDS_TIP_BEGIN-IDC_BEGIN + id, APP_LANGUAGE, tooltip_descr);
    info->lpszText = tooltip_descr;
    return TRUE;
  case WM_COMMAND:
    switch (LOWORD(wparam)) {
    case IDCANCEL: // pressed ESC
      MessageBeep(MB_ICONINFORMATION);
      EndDialog(hwnd, IDCANCEL);
      return TRUE;
    case IDC_OPEN: // launch
      ; // low version GCC doesn't allow a declaration immediately after a label (error: a label can only be part of a statement and a declaration is not a statement). Fine, let's make it happy
      int type = GetComboboxVal(IDC_TYPE);
      if (type == CB_ERR) { // not selected
        msgbox(hwnd, MB_ICONINFORMATION, IDS_ERR_SELECTION, TARGET_RUN);
        SetFocusedItemAsync(IDC_TYPE);
        return TRUE;
      }
      if (checkTSWrunning())
        return TRUE;
      if (launch_tsw(type))
        EndDialog(hwnd, IDOK); // quit if successful
      return TRUE;
    case IDC_MGRT:
      if (msgbox(hwnd, MB_YESNO | MB_ICONINFORMATION, IDS_INFO_MIGRATION, data_path) == IDNO)
        return TRUE;
      if (migrate_data())
        SetFocusedItemAsync(IDC_TYPE);
      return TRUE;
    case IDC_INIT: // initialize
      if (msgbox(hwnd, MB_YESNO | MB_ICONINFORMATION, IDS_INFO_INITIALIZE) == IDNO)
        return TRUE;
      if (delete_ini()) {
        msgbox(hwnd, MB_ICONINFORMATION, IDS_INFO_INITIALIZE_OK);
        SetFocusedItemAsync(IDC_TYPE);
      }
      return TRUE;
    case IDC_CONF: // configure
      type = GetComboboxVal(IDC_TYPE);
      if (type == CB_ERR) { // not selected
        msgbox(hwnd, MB_ICONINFORMATION, IDS_ERR_SELECTION, TARGET_CONFIG);
        SetFocusedItemAsync(IDC_TYPE);
        return TRUE;
      }
      // TODO
      DialogBoxIndirectParamW(hIns, pDlg_new[is_chinese] ? pDlg_new[is_chinese] : pDlg_old[is_chinese], hwnd, (DLGPROC)dialog_conf_proc, 0);
      SetFocusedItemAsync(IDC_TYPE);
      return TRUE;
    }
  }
  return FALSE;
}

int main() {
  LoadLibrary("comctl32"); // for winXP compatibility: comctl32.dll must be imported; otherwise no control will be shown (see https://stackoverflow.com/questions/2938313/c-win32-xp-visual-styles-no-controls-are-showing-up); alternatively, call `InitCommonControls()` from <commctrl.h> and link comctl32.lib, which is technically a no-op (but loads comctl32.dll so as to solve the issue)
  OSVERSIONINFOEX v;
  v.dwOSVersionInfoSize = sizeof(v);
  GetVersionEx((OSVERSIONINFO*)&v); // note: MSDN: for this function to work on Win 8.1+, compatibility.application.supportedOS should not be included in the manifest file "2.manifest"
  // a better idea is to call ntdll.RtlGetVersion, but just don't bother to do that
  winVer = MAKELONG(MAKEWORD(v.dwMinorVersion, v.dwMajorVersion), v.wServicePackMajor);

  is_chinese = ((GetUserDefaultUILanguage() & 0x3FF) == LANG_CHINESE); // lang = LANG_ID | (SUBLANG_ID << 10)
  hIns = GetModuleHandle(NULL);
  app_title[0] = (WORD)LoadStringLangW(IDS_TITLE, APP_LANGUAGE, app_title+1); // set unicode stringlength at the same time

  HRSRC hrsrc_dlg[3] = {
    FindResourceEx(hIns, RT_DIALOG, MAKEINTRESOURCE(IDD_CONFIG), MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT)),
    FindResourceEx(hIns, RT_DIALOG, MAKEINTRESOURCE(IDD_CONFIG), MAKELANGID(LANG_CHINESE, SUBLANG_CHINESE_SIMPLIFIED)),
    FindResourceEx(hIns, RT_DIALOG, MAKEINTRESOURCE(IDD_APP), APP_LANGUAGE)
  };
  HGLOBAL hdlg;
  for (int i = 0; i < 3; ++i) {
    if (!(hrsrc_dlg[i] &&
        (szDlg[i] = SizeofResource(hIns, hrsrc_dlg[i])) &&
        (hdlg = LoadResource(hIns, hrsrc_dlg[i])) &&
        (pDlg_old[i] = LockResource(hdlg)))) {
      msgbox(HWND_TOPMOST, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"FindResourceEx");
      return 0;
    }
  }

  HDC hDC = GetDC(NULL);
  if (!EnumFontFamiliesW(hDC, WT(MODERN_FONT_NAME), (FONTENUMPROCW)EnumFontFamProc, 0)) { // have Segoe UI font
    for (int i = 0; i < 3; ++i)
      setDlgFont(i, WT(MODERN_FONT_NAME), sizeof(WT(MODERN_FONT_NAME)), DLG_FONT_SIZE);
  }
  ReleaseDC(NULL, hDC);

  if (!DialogBoxIndirectParamW(hIns, pDlg_new[2] ? pDlg_new[2] : pDlg_old[2], NULL, (DLGPROC)dialog_main_proc, 0)) // must create a Unicode dialog here; otherwise, even SetWindowTextW may not work properly (reference: https://stackoverflow.com/a/11515400/11979352)
    msgbox(HWND_TOPMOST, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"DialogBoxIndirectParam");
  return 0;
}
