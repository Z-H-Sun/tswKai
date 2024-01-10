#include "tswLauncher.h"
#include <stdarg.h>
#define SegoeUIFontName "Segoe UI"

HWND hWnd = NULL;
HINSTANCE hIns = NULL;
HANDLE hMapFile = NULL;
LPVOID p_mutex = NULL;
RECT rcDlg = {0};

char app_title[MAX_PATH] = {0};
int font_size = 0;
BOOL have_font_segoe_ui = FALSE, is_chinese = FALSE;
HFONT font_dlg = NULL;
HICON icon = NULL;

typedef struct {
   DWORD pid;
   uintptr_t hwnd;
} MUTEXINFO;

int msgbox(unsigned int uType, unsigned int uID, ...)
{
  char fmt[256];
  char buffer[512];
  if (!LoadString(hIns, uID, fmt, sizeof(fmt))) // failed (unlikely)
    return 0;
  va_list args;
  va_start(args, uID);
  vsnprintf(buffer, sizeof(buffer), fmt, args);
  va_end(args);

  uType |= MB_SETFOREGROUND; // always set as foreground
  if (!hWnd || !IsWindowVisible(hWnd)) // if no main window, set msgbox window as top most
    uType |= MB_TOPMOST;
  return MessageBox(hWnd, buffer, app_title, uType);
}

void createMutex(HWND cur_hwnd) {
  if (! (hMapFile = CreateFileMapping(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, APP_MUTEX_BUFSIZE, APP_MUTEX)) ) {
    msgbox(MB_ICONEXCLAMATION, IDS_ERRA, GetLastError(), "CreateFileMapping");
    return; // could not create file mapping object
  }
  if (! (p_mutex = MapViewOfFile(hMapFile, FILE_MAP_WRITE, 0, 0, APP_MUTEX_BUFSIZE)) ) {
    CloseHandle(hMapFile);
    msgbox(MB_ICONEXCLAMATION, IDS_ERRA, GetLastError(), "MapViewOfFile");
    return; // could not map view of file
  }
  MUTEXINFO *minfo = p_mutex;
  minfo->pid = GetCurrentProcessId();
  minfo->hwnd = (uintptr_t)cur_hwnd;
}

void checkMutex(HWND cur_hwnd) {
  if (! (hMapFile = OpenFileMapping(FILE_MAP_READ, FALSE, APP_MUTEX)) ) {
    createMutex(cur_hwnd); // no other tswLauncher instance running
    return;
  }
  if (! (p_mutex = MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, APP_MUTEX_BUFSIZE)) ) {
    CloseHandle(hMapFile);
    msgbox(MB_ICONEXCLAMATION, IDS_ERRA, GetLastError(), "MapViewOfFile");
    return; // could not map view of file
  }
  MUTEXINFO *minfo = p_mutex;
  hWnd = (HWND)minfo->hwnd;
  if (!IsWindow(hWnd)) {
    msgbox(MB_ICONEXCLAMATION, IDS_ERRA, GetLastError(), "IsWindow");
    return; // somehow the window is invalid
  }
  SetWindowPos(hWnd, 0, rcDlg.left, rcDlg.top, 0, 0, SWP_NOZORDER | SWP_NOSIZE | SWP_NOACTIVATE);
  hWnd = GetLastActivePopup(hWnd); // the real active child window
  app_title[strlen(app_title)-3] = '\0'; // do not show " - "
  msgbox(MB_ICONINFORMATION, IDS_ERRD, is_chinese ? APP_TITLE_CN : APP_TITLE, minfo->pid);
  safe_exit(1);
}

void centerTSW(HWND hwndTSW) {
  RECT rcTSW;
  GetWindowRect(hwndTSW, &rcTSW);
  SetWindowPos(hwndTSW, 0, (rcDlg.left+rcDlg.right+rcTSW.left-rcTSW.right)/2, (rcDlg.top+rcDlg.bottom+rcTSW.top-rcTSW.bottom)/2, 0, 0, SWP_NOZORDER | SWP_NOSIZE | SWP_NOACTIVATE);
}

BOOL checkTSWrunning() {
  HWND hwndTSW = FindWindow(TSW_CLS, NULL);
  HWND hwndDlg = hWnd; // if NULL: this check is done during startup of this app; otherwise, when the Launch button is clicked
  DWORD pidTSW = 0;
  if (!hwndTSW)
    return FALSE;
  centerTSW(hwndTSW);
  GetWindowThreadProcessId(hwndTSW, &pidTSW);
  hwndTSW = GetWindow(hwndTSW, GW_OWNER); // TApplication (owner window)
  ShowWindow(hwndTSW, SW_SHOWNOACTIVATE); // this will restore the TSW window if it is minimized
  hWnd = GetLastActivePopup(hwndTSW); // the real active child window
  if (!hwndDlg)
    app_title[strlen(app_title)-3] = '\0'; // do not show " - "
  msgbox(MB_ICONINFORMATION, IDS_ERRD, is_chinese ? TARGET_TITLE_CN : TARGET_TITLE, pidTSW);
  if (hwndDlg)
    hWnd = hwndDlg; // restore
  else
    safe_exit(1);
  return TRUE;
}

void pre_exit() {
  if (icon)
    DeleteObject(icon);
  if (font_dlg)
    DeleteObject(font_dlg);
  if (p_mutex) {
    UnmapViewOfFile(p_mutex);
    CloseHandle(hMapFile);
  }
}

void safe_exit(int status) {
  pre_exit();
  exit(status);
}

int CALLBACK EnumFontFamExProc(ENUMLOGFONTEXA *lpelfe, NEWTEXTMETRICEXA *lpntme, DWORD FontType, LPARAM lParam) {
  if (strnicmp((char *) lpelfe->elfFullName, SegoeUIFontName, strlen(SegoeUIFontName)+1) == 0) {
    have_font_segoe_ui=TRUE;
    return 0;
  }

  return 1;
}

static void checkFonts()
{
  LOGFONTA lf = {0};
  HDC hDC = GetDC(NULL);
  EnumFontFamiliesExA(hDC, &lf, (FONTENUMPROCA)EnumFontFamExProc, 0, 0);
  font_size = -MulDiv(DLG_FONT_SIZE, GetDeviceCaps(hDC, LOGPIXELSY), 72); // need to accurately calculate font size according to screen DPI; see the comments for the `lfHeight` param on MSDN: https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-logfonta#members
  ReleaseDC(NULL, hDC);
}

LRESULT CALLBACK dialog_proc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  switch ( message ) {
  case WM_INITDIALOG:
    GetWindowRect(hwnd, &rcDlg);

    checkTSWrunning();
    checkMutex(hwnd);
    init_path();

    hWnd = hwnd;
    icon = LoadImage(hIns, MAKEINTRESOURCE(IDI_APP), IMAGE_ICON, 0, 0, LR_DEFAULTCOLOR | LR_DEFAULTSIZE | LR_SHARED);
    SendMessage(hwnd, WM_SETICON, (WPARAM)ICON_BIG, (LPARAM)icon);
    SetWindowText(hwnd, app_title);

    // try using segoe ui; if not possible, fallback to MS Dlg Shell 2
    checkFonts();
    if (have_font_segoe_ui) {
      font_dlg = CreateFont(font_size, 0, 0, 0, FW_REGULAR, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, FF_DONTCARE, SegoeUIFontName);
      SendDlgItemMessage(hwnd, IDC_TYPE, WM_SETFONT, (WPARAM)font_dlg, (LPARAM)FALSE);
      SendDlgItemMessage(hwnd, IDC_OPEN, WM_SETFONT, (WPARAM)font_dlg, (LPARAM)FALSE);
      SendDlgItemMessage(hwnd, IDC_INIT, WM_SETFONT, (WPARAM)font_dlg, (LPARAM)FALSE);
    }

    // add combobox entries
    char entry[256];
    LoadString(hIns, IDS_ENTRY1, entry, sizeof(entry));
    SendDlgItemMessage(hwnd, IDC_TYPE, CB_ADDSTRING, (WPARAM)0, (LPARAM)entry);
    LoadString(hIns, IDS_ENTRY2, entry, sizeof(entry));
    SendDlgItemMessage(hwnd, IDC_TYPE, CB_ADDSTRING, (WPARAM)0, (LPARAM)entry);
    LoadString(hIns, IDS_ENTRY3, entry, sizeof(entry));
    SendDlgItemMessage(hwnd, IDC_TYPE, CB_ADDSTRING, (WPARAM)0, (LPARAM)entry);
    LoadString(hIns, IDS_ENTRY4, entry, sizeof(entry));
    SendDlgItemMessage(hwnd, IDC_TYPE, CB_ADDSTRING, (WPARAM)0, (LPARAM)entry);

    // select default entry
    SendDlgItemMessage(hwnd, IDC_TYPE, CB_SETCURSEL, (WPARAM)(is_chinese ? 2 : 1), (LPARAM)0);

    // create tooltips
    HWND hwndType = GetDlgItem(hwnd, IDC_TYPE);
    HWND hwndOpen = GetDlgItem(hwnd, IDC_OPEN);
    HWND hwndInit = GetDlgItem(hwnd, IDC_INIT);
    HWND hwndTip = CreateWindowEx(0, TOOLTIPS_CLASS, NULL, WS_POPUP | TTS_ALWAYSTIP, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, hwnd, NULL, hIns, NULL);
    SendMessage(hwndTip, TTM_SETMAXTIPWIDTH, 0, 300); // allow text wrap and multiline
    SendMessage(hwndTip, TTM_SETDELAYTIME, TTDT_INITIAL, 0);
    SendMessage(hwndTip, TTM_SETDELAYTIME, TTDT_RESHOW, 0);
    SendMessage(hwndTip, TTM_SETDELAYTIME, TTDT_AUTOPOP, 0x7FFF); // largest possible delay because the HIWORD must be zero
    TOOLINFO toolInfo = {0};
    toolInfo.cbSize = sizeof(toolInfo);
    toolInfo.hwnd = hwnd;
    toolInfo.uFlags = TTF_IDISHWND | TTF_SUBCLASS;

    toolInfo.uId = (UINT_PTR)hwndType;
    toolInfo.lpszText = (LPTSTR)IDS_TIP1;
    SendMessage(hwndTip, TTM_ADDTOOL, 0, (LPARAM)&toolInfo);

    toolInfo.uId = (UINT_PTR)hwndOpen;
    toolInfo.lpszText = (LPTSTR)IDS_TIP2;
    SendMessage(hwndTip, TTM_ADDTOOL, 0, (LPARAM)&toolInfo);

    LoadString(hIns, IDS_TIP3, entry, sizeof(entry)); // lpszText must be pointed to a buffer when the text used in the tooltip exceeds 80 TCHARs in length
    toolInfo.uId = (UINT_PTR)hwndInit;
    toolInfo.lpszText = entry;
    SendMessage(hwndTip, TTM_ADDTOOL, 0, (LPARAM)&toolInfo);

    return TRUE;
  case WM_DESTROY:
    pre_exit();
    return TRUE;
  case WM_CLOSE:
    EndDialog(hwnd, IDCANCEL);
    return TRUE;
  case WM_COMMAND:
    if (wparam == IDCANCEL) { // pressed ESC
      MessageBeep(MB_ICONINFORMATION);
      EndDialog(hwnd, IDCANCEL);
      return TRUE;
    } else if (LOWORD(wparam) == IDC_OPEN) { // launch
      int type = SendDlgItemMessage(hwnd, IDC_TYPE, CB_GETCURSEL, 0, 0);
      if (type == CB_ERR) { // not selected
        msgbox(MB_ICONINFORMATION, IDS_ERRB);
        return TRUE;
      }
      if (checkTSWrunning())
        return TRUE;
      if (launch_tsw(type))
        EndDialog(hwnd, IDOK); // quit if successful
      return TRUE;
    } else if (LOWORD(wparam) == IDC_INIT) { // initialize
      if (delete_ini()) {
        HWND hwndType = GetDlgItem(hwnd, IDC_TYPE);
        SendMessage(hwnd, WM_NEXTDLGCTL, (WPARAM)hwndType, TRUE); // set focus (see https://devblogs.microsoft.com/oldnewthing/20040802-00/?p=38283)
      }
      return TRUE;
    }
    break;
  }

  return FALSE;
}

int main() {
  LoadLibrary("comctl32"); // for winXP compatibility: comctl32.dll must be imported; otherwise no control will be shown (see https://stackoverflow.com/questions/2938313/c-win32-xp-visual-styles-no-controls-are-showing-up); alternatively, call `InitCommonControls()` from <commctrl.h> and link comctl32.lib, which is technically a no-op (but loads comctl32.dll so as to solve the issue)

  is_chinese = ((GetUserDefaultUILanguage() & 0x3FF) == LANG_CHINESE); // lang = LANG_ID | (SUBLANG_ID << 10)
  hIns = GetModuleHandle(NULL);
  LoadString(hIns, IDS_TITLE, app_title, sizeof(app_title));

  DialogBoxParam(hIns, MAKEINTRESOURCE(IDD_APP), NULL, (DLGPROC)dialog_proc, 0);
  return 0;
}
