#include "gui.h"

HWND hWndMain = NULL, hWndConf = NULL;
HINSTANCE hIns = NULL;
HANDLE hMapFile = NULL;
LPVOID p_mutex = NULL;
RECT rcDlg = {0};
char tsw_exe_conf_path[MAX_PATH] = {0};
OPENFILENAME ofn = {sizeof(ofn), NULL, NULL, "*.EXE\0*.exe\0", NULL, 0, 1, tsw_exe_conf_path, MAX_PATH, NULL, 0, NULL, NULL, OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_LONGNAMES, 0, 0, "exe"};
WCHAR tooltip_descr[512]; // this has to be a static pointer because it will be assigned to NMTTDISPINFOW.lpszText and thus shouldn't be a local variable
WCHAR app_title[MAX_PATH] = WT(APP_TITLE); // note: app_title[0] is (WORD)length; the actual unicode string starts from app_title+1
BOOL is_chinese;
DLGTEMPLATE *pDlg_old[3] = {NULL}, *pDlg_new[3] = {NULL};
DWORD szDlg[3], dimDlgWin[3];
DWORD winVer;

int msgbox(HWND hwnd, unsigned int uType, unsigned int uID, ...) {
  WCHAR buffer[512];
  DWORD lang = hWndConf ? APP_CONF_LANGUAGE : APP_LANGUAGE;
  va_list args;
  va_start(args, uID);
  if (!FormatMessageW(FORMAT_MESSAGE_FROM_HMODULE, NULL, uID, lang, buffer, sizeof(buffer), &args)) { // failed (unlikely)
    // fallback on generic treatment of simple error message
    size_t len = is_chinese ? sizeof(FAIL_FORMAT_MSG_CN)-sizeof(WCHAR) : sizeof(FAIL_FORMAT_MSG_EN)-sizeof(WCHAR); // in bytes, not including the trailing \0\0
    memcpy(buffer, is_chinese ? FAIL_FORMAT_MSG_CN : FAIL_FORMAT_MSG_EN, len); // fallback error message
    _itow(uID, (WCHAR*)((char*)buffer+len), 10); // error message number
  }
  va_end(args);

  uType |= MB_SETFOREGROUND; // always set as foreground
  if (!hwnd) { // if NULL: default value
    if (hWndConf && IsWindowVisible(hWndConf)) {
      hwnd = hWndConf;
      goto show_msgbox;
    }
    hwnd = hWndMain;
  }
  if (!hwnd || hwnd == HWND_TOPMOST || !IsWindowVisible(hwnd)) { // if no main window, set msgbox window as top most
    hwnd = NULL;
    uType |= MB_TOPMOST;
  }
show_msgbox:
  ; // low version GCC doesn't allow a declaration immediately after a label (error: a label can only be part of a statement and a declaration is not a statement). Fine, let's make it happy
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
  wmemcpy(buf, pWch+1, len);
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
  WCHAR buf[MAX_PATH];
  switch ( message ) {
  case WM_INITDIALOG:
    hWndConf = hwnd;
    TOOLINFOW toolInfo = {sizeof(toolInfo)};
    RECT *rct = &toolInfo.rect; // temporary RECT struct
    // get dialog window size; will be used when resizing the window during IDC_CONF_BUTTON_MORE clicks
    // also used to get the region for showing tooltip for IDC_CONF_STATIC_BUG
    GetWindowRect(hwnd, rct);
    dimDlgWin[2] = rct->right-rct->left; // width, in pixels
    dimDlgWin[0] = rct->bottom-rct->top; // original height, in pixels
    rct->top = 59; // height difference, in dialog box units
    rct->right = 6; rct->bottom = 8; // area width and height for IDC_CONF_STATIC_BUG to add tooltip to
    MapDialogRect(hwnd, rct);
    dimDlgWin[1] = rct->top+dimDlgWin[0]; // new height, in pixels
    GetClientRect(hwnd, (RECT*)(((POINT*)rct)-1)); // *HACK*: GetClientRect always returns 0 for the first two elements of RECT, but we are only interested in the latter two, so shift the pointer a bit... (and the benefit is that the next 2 integers won't be overwritten)
    rct->right = rct->left - rct->right;
    rct->left -= rct->right;
    rct->bottom += rct->top;

    // set title (specify type)
    UINT i;
    if ((i = GetWindowTextW(hwnd, buf, sizeof(buf)/sizeof(WCHAR)))) {
      if (LoadStringLangW(IDS_ENTRY_TYPE_BEGIN+(int)lparam+1, APP_CONF_LANGUAGE, buf+i+sizeof(TITLE_SEPARATOR)-1)) // lparam is `type`: 0-3: English, English(Retranslated), Chinese, and Chinese (Retranslated), respectively; -1: custom
        wmemcpy(buf+i, WT(TITLE_SEPARATOR), sizeof(TITLE_SEPARATOR)-1);
    }
    SetWindowTextW(hwnd, buf);

    SetDlgItemText(hwnd, IDC_CONF_EDIT_EXE_NAME, tsw_exe_conf_path);
    SendDlgItemMessageW(hwnd, IDC_CONF_COMBO_FONT, CB_LIMITTEXT, (WPARAM)LF_FACESIZE-1, (LPARAM)0); // maximum font name length
    for (i = IDC_CONF_EDIT_BEGIN_2; i <= IDC_CONF_EDIT_END; ++i)
      SendDlgItemMessageW(hwnd, i, EM_LIMITTEXT, (WPARAM)3, (LPARAM)0);
    for (i = IDC_CONF_SPIN_BEGIN; i <= IDC_CONF_SPIN_END; ++i)
      SendDlgItemMessageW(hwnd, i, UDM_SETRANGE32, (WPARAM)interval_min_vals[i-IDC_CONF_SPIN_BEGIN], (LPARAM)interval_max_vals[i-IDC_CONF_SPIN_BEGIN]);
    for (i = IDC_CONF_SLIDER_BEGIN; i <= IDC_CONF_SLIDER_END; ++i)
      SendDlgItemMessageW(hwnd, i, TBM_SETRANGE, (WPARAM)TRUE, (LPARAM)MAKELONG(interval_min_vals[16], interval_max_vals[16]));

    // create tooltips
    HWND hwndTip = createTooltipWnd(hwnd, &toolInfo);
    for (i = IDC_CONF_BEGIN; i <= IDC_CONF_CHECK_END; ++i) {
      toolInfo.uId = (UINT_PTR)GetDlgItem(hwnd, i);
      SendMessageW(hwndTip, TTM_ADDTOOLW, 0, (LPARAM)&toolInfo);
    }
    // for groupbox, its window seems "invisible" to tooltip, so have to do it in a different way (by RECT rather than HWND; toolInfo.rect has been calculated above). Ref: https://forums.codeguru.com/showthread.php?390175-Mouse-Events-for-Group-Box
    toolInfo.uFlags = TTF_SUBCLASS;
    toolInfo.uId = IDC_CONF_STATIC_BUG;
    SendMessageW(hwndTip, TTM_ADDTOOLW, 0, (LPARAM)&toolInfo);

    checkAllPatches();
    DragAcceptFiles(hwnd, TRUE); // accept TSW EXE file drag-drop to this dialog [Theoretically, the receiving window can be the textbox; however, that will make the textbox receive the WM_DROPFILES message, and the parent window will not be able to get such a message unless subclassing is implemented]
    return FALSE; // prevent the system from setting the default keyboard focus; ref: https://learn.microsoft.com/en-us/windows/win32/dlgbox/wm-initdialog

  case WM_SHOWMSGBOX: // delayed processing for startup messageboxes
    ShowWindow(hwnd, SW_SHOWNOACTIVATE); // make sure dialog window is visible
    msgbox(hwnd, MB_ICONEXCLAMATION, wparam); // wparam is uID of error message
    SetFocusedItemAsync(IDC_CONF_CHECK_BEGIN_2);
    if (wparam == IDS_ERR_INVALID_VALUE)
      break; // show "*" in dialog title since there are changed value(s)
    return TRUE;

  case WM_SAVECONFIG: // delayed processing of patch saving
    closeDlg(IDOK);
    return TRUE;

  case WM_CLOSE:
    closeDlg(IDCANCEL);
    return TRUE;

  case WM_DROPFILES: // user drag-drops a TSW executable file to this dialog
    i = DragQueryFile((HDROP)wparam, 0, (char*)buf, MAX_PATH); // only the first 260 bytes of `buf` will be filled; the later 260 bytes are still vacant
    DragFinish((HDROP)wparam);
    if (!i) {
      msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"DragQueryFile");
      return TRUE;
    }
    goto newExe;

  case WM_NOTIFY:
    ; // low version GCC doesn't allow a declaration immediately after a label (error: a label can only be part of a statement and a declaration is not a statement). Fine, let's make it happy
    NMHDR* nmh = (NMHDR*)lparam;
    UINT_PTR id = wparam; // or nmh->idFrom; they are the same
    int newState;

    // dynamically set icon / title / description of the tooltip
    if (nmh->code == TTN_NEEDTEXTW) {
      HWND hWndItem;
      if (id == IDC_CONF_STATIC_BUG) {
        if (!IsDlgButtonChecked(hwnd, IDC_CONF_BUTTON_MORE))
          return TRUE; // hide tooltip
          // in this case, tooltip will not be shown, because no description text is set (ref: https://learn.microsoft.com/en-us/windows/win32/controls/ttm-settitle#remarks)
        hWndItem = GetDlgItem(hwnd, id);
      } else {
        hWndItem = (HWND)id;
        id = GetDlgCtrlID(hWndItem);
      }
      if (id >= IDC_CONF_SLIDER_BEGIN && id <= IDC_CONF_SLIDER_END)
        return FALSE; // in this case, tooltip will show the value of the slider (because TBS_TOOLTIPS is set)
      WCHAR* bufTitle;
      if (id == IDC_CONF_EDIT_EXE_NAME)
        bufTitle = TEXTBOX_EXE_NAME_CONF;
      else if (id == IDC_CONF_BUTTON_EXE_MORE)
        bufTitle = BUTTON_EXE_NAME_CONF;
      else {
        bufTitle = buf;
        INT_PTR n = GetWindowTextW(hWndItem, bufTitle, sizeof(buf)/sizeof(WCHAR));
        if (id >= IDC_CONF_BUTTON_BEGIN && id <= IDC_CONF_BUTTON_END)
          wcscat(buf, BUTTON_NAME_CONF);
        else {
          if (is_chinese_exe) { // the newLine char is invisible, so in Chinese, it will be automatically hidden, and in most cases, nothing needs to be done
            if ((id == IDC_CONF_CHECK_DOOR || id == IDC_CONF_CHECK_STAIR) &&
                (n = (INT_PTR)wmemchr(bufTitle, L'\n', n)))
              *(WCHAR*)n = L'\0'; // in these cases, don't show the second line
          } else if ((n = (INT_PTR)wmemchr(bufTitle, L'\n', n))) { // change newLine to space; only necessary for English
            n -= 2;
            if (*(WCHAR*)n == L'-' || *(WCHAR*)n == L' ')
              *(WCHAR*)n = L'\n'; // eliminate hyphen or space (again, newLine is invisible))
            else
              *(WCHAR*)(n+2) = L' ';
          }
          if (id >= IDC_CONF_CHECK_BEGIN && id <= IDC_CONF_CHECK_END)
            wcscat(buf, CHECKBOX_NAME_CONF);
        }
      }
      SendMessageW(nmh->hwndFrom, TTM_SETTITLEW, (id == IDC_CONF_STATIC_INTV || id == IDC_CONF_STATIC_BUG) ? TTI_WARNING : TTI_INFO, (LPARAM)bufTitle);
      LoadStringLangW((id == IDC_CONF_BUTTON_OK && has_item_changed) ? IDS_TIP_BUTTON_OK_2 : IDS_TIP_CONF_BEGIN-IDC_CONF_BEGIN + id, APP_CONF_LANGUAGE, (WCHAR*)tooltip_descr);
      ((NMTTDISPINFOW*)lparam)->lpszText = (WCHAR*)tooltip_descr;
      return TRUE;
    }

    // updown changed
    if (nmh->code == UDN_DELTAPOS) {
      if (id == IDC_CONF_SPIN_TILE_HIGH || // always do this
         ((id == IDC_CONF_SPIN_EVENT_HIGH ||
           id == IDC_CONF_SPIN_MOVE_HIGH  ||
           id == IDC_CONF_SPIN_KEYBD_HIGH)&&
           IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_SUPER) != 1)) // doesn't have superfast speed mode
        SetUpdownVal(id-1, ((NMUPDOWN*)lparam)->iPos+((NMUPDOWN*)lparam)->iDelta); // copy HIGH value to SUPER
      return TRUE; // this is not the return value for UDN_DELTAPOS (or TRBN_THUMBPOSCHANGING below); to prevent updown / trackbar control from changing value, call `SetWindowLong(hwnd, DWL_MSGRESULT, 1);` before `return TRUE` instead (ref: https://stackoverflow.com/a/48105475/11979352)
    }

    // trackbar changed
    if (nmh->code == TRBN_THUMBPOSCHANGING) // Note: this notification involves TBS_NOTIFYBEFOREMOVE which requires Windows Vista+ to work
      newState = ((NMTRBTHUMBPOSCHANGING*)lparam)->dwPos;
    else if (LOWORD(winVer) < _WIN32_WINNT_VISTA && // for WinXP, must do this judgement in a more circuitous way
             nmh->code == NM_CUSTOMDRAW && // unfortunately, trackbar does not send NM_KILLFOCUS notification (one can find that by looking at the source code: https://github.com/tongzx/nt5src/blob/master/Source/XPSP1/NT/shell/comctl32/v6/trackbar.c, and compare it with other common controls like treeview (.../treeview.c) which send such notification), so we have to do some *hacky* tricks here by making use of the drawing notification
             id >= IDC_CONF_SLIDER_BEGIN && id <= IDC_CONF_SLIDER_END && // trackbar
             IsWindowEnabled(GetDlgItem(hwnd, id))) { // must be enabled
      newState = GetTrackbarVal(id);
    } else
      return TRUE;
    if (id == IDC_CONF_SLIDER_MISOP_HIGH &&
        IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_SUPER) != 1) // doesn't have superfast speed mode
      SetTrackbarVal(IDC_CONF_SLIDER_MISOP_SUP, newState); // copy HIGH value to SUPER
    if (newState == misop_vals[id-IDC_CONF_SLIDER_BEGIN]) // compare with initial value
      return TRUE;
    break; // item changed

  case WM_COMMAND:
    id = LOWORD(wparam);

    switch (id) {
    // pressed ESC
    case IDCANCEL:
      closeDlg(IDCANCEL);
      return TRUE;

    // pressed OK
    case IDC_CONF_BUTTON_OK:
      SetFocusedItemSync(IDC_CONF_BUTTON_OK); // this will make sure the changes to the currently focused item will take effect (because after this, the xx_KILLFOCUS notifications are properly processed)
      PostMessage(hwnd, WM_SAVECONFIG, 0, 0); // defer saving configs until all checks are done (by posting a message, which will be processed after all queued messages are processed)
      return TRUE;

    // clicked ...
    case IDC_CONF_BUTTON_EXE_MORE:
      buf[0] = 0; // only takes effect when clicking IDC_CONF_BUTTON_EXE_MORE; buf[0] will be non-zero when WM_DROPFILES
newExe:
      if (!saveAllPatches(IDTRYAGAIN)) // check whether current file needs saving
        return TRUE;
      if (!has_item_changed &&
          GetWindowTextW(hwnd, buf+MAX_PATH/sizeof(WCHAR), MAX_PATH/sizeof(WCHAR)) && // only the last 260 bytes of `buf` will be filled; the first 260 bytes may have been reserved for filename
          buf[MAX_PATH/sizeof(WCHAR)] == L'*') // title starts with an asterisk
        SetWindowTextW(hwnd, buf+MAX_PATH/sizeof(WCHAR)+1); // remove asterisk sign (reset title)

      if (!buf[0]) { // only takes effect when clicking IDC_CONF_BUTTON_EXE_MORE; will be skipped when WM_DROPFILES, in which case filename has already been obtained
        strcpy((char*)buf, tsw_exe_conf_path); // the initially selected file of the open-file dialog will be the last `tsw_exe_conf_path`
        ofn.nFilterIndex = 1;
        ofn.lpstrFile = (char*)buf;
        ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_LONGNAMES;
        if (!GetOpenFileName(&ofn))
          return TRUE;
      }

      BOOL is_chinese_exe_old = is_chinese_exe;
      if (!checkInit((char*)buf))
        return TRUE;
      strcpy(tsw_exe_conf_path, (char*)buf); // when initial check is successful, replace `tsw_exe_conf_path`
      if (is_chinese_exe != is_chinese_exe_old) { // new dialog with new language
        EndDialog(hwnd, IDTRYAGAIN); // DialogBoxIndirectParamW of new dialog in new lang will be called later in dialog_main_proc
        return TRUE;
      }
      // first re-enable all items; then disable them when needed in `checkAllPatches` below
      EnableItem(IDC_CONF_CHECK_MISOP, TRUE);
      for (i = IDC_CONF_SPIN_BEGIN_2; i <= IDC_CONF_EDIT_END; ++i)
        EnableItem(i, TRUE);
      // reset title (custom executable; no asterisk sign at the beginning)
      id = APP_CONF_LANGUAGE;
      if ((i = LoadStringLangW(IDS_CONF_TITLE, id, buf))) {
        if (LoadStringLangW(IDS_ENTRY_TYPE_CUSTOM, id, buf+i+sizeof(TITLE_SEPARATOR)-1))
          wmemcpy(buf+i, WT(TITLE_SEPARATOR), sizeof(TITLE_SEPARATOR)-1);
        SetWindowTextW(hwnd, buf);
      }
      SetDlgItemText(hwnd, IDC_CONF_EDIT_EXE_NAME, tsw_exe_conf_path); // reset textbox text
      checkAllPatches();
      return TRUE;

    // clicked More fixes...
    case IDC_CONF_BUTTON_MORE:
      ; // low version GCC doesn't allow a declaration immediately after a label (error: a label can only be part of a statement and a declaration is not a statement). Fine, let's make it happy
      int val = IsDlgButtonChecked(hwnd, IDC_CONF_BUTTON_MORE);
      newState = val ? SW_SHOWNOACTIVATE : SW_HIDE;
      // show / hide new controls
      ShowWindow(GetDlgItem(hwnd, IDC_CONF_STATIC_BUG), newState);
      for (i = IDC_CONF_CHECK_33F; i <= IDC_CONF_CHECK_END; ++i)
        ShowWindow(GetDlgItem(hwnd, i), newState);
      // resize dialog
      SetWindowPos(hwnd, NULL, 0, 0, dimDlgWin[2], dimDlgWin[val], SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOZORDER);
      return TRUE;

    // changed any checkbox
    case IDC_CONF_CHECK_BEGIN ... IDC_CONF_CHECK_END:
      val = IsDlgButtonChecked(hwnd, id);
      if (val == 2 && // invalid patch state
          msgbox(hwnd, MB_ICONEXCLAMATION | MB_YESNO, IDS_ERR_RECTIFY_BYTE) == IDNO)
        return TRUE;

      val = ((val == 1) ? 0 : 1); // 2->1; 1->0; 0->1;
      CheckDlgButton(hwnd, id, val);
      // special checks
      switch (id) {
      case IDC_CONF_CHECK_SUPER:
        checkSuper(val, FALSE);
        break;
      case IDC_CONF_CHECK_MOVE:
        checkMove(val);
        break;
      case IDC_CONF_CHECK_KEYBD:
        checkKeybd(val);
        break;
      case IDC_CONF_CHECK_MISOP:
        checkMisop(val);
      }
      break; // item changed

    // changed any updown-bound textbox
    case IDC_CONF_EDIT_BEGIN_2 ... IDC_CONF_EDIT_END:
      if (HIWORD(wparam) == EN_CHANGE) {
        if (id == IDC_CONF_EDIT_EVENT_SUP &&
            has_item_changed >= 0) // don't do anything if the dialog is initializing
          is_v_3_1_0 = FALSE; // for v3.1.0, when the "event:super" value is changed (either by direct editing, or due to change of "event:high" value in the "no superfast-mode" case), then no longer need for special treatment anymore
        break; // item changed
      }
      if (HIWORD(wparam) == EN_KILLFOCUS) { // user moves focus away from a edit box with an UpDown buddy
        val = GetDlgItemInt(hwnd, id, NULL, FALSE);
        SetUpdownVal(id+IDC_CONF_SPIN_BEGIN_2-IDC_CONF_EDIT_BEGIN_2, val); // sending UDM_SETPOS will force the value to fall within the upper and lower limits
        if (id == IDC_CONF_EDIT_TILE_HIGH || // always do this
           ((id == IDC_CONF_EDIT_EVENT_HIGH ||
             id == IDC_CONF_EDIT_MOVE_HIGH  ||
             id == IDC_CONF_EDIT_KEYBD_HIGH)&&
             IsDlgButtonChecked(hwnd, IDC_CONF_CHECK_SUPER) != 1)) // doesn't have superfast speed mode
          SetUpdownVal(id-1+IDC_CONF_SPIN_BEGIN_2-IDC_CONF_EDIT_BEGIN_2, val); // copy HIGH value to SUPER
      }
      return TRUE;

    // changed font
    case IDC_CONF_COMBO_FONT:
      if (HIWORD(wparam) == CBN_EDITCHANGE) // changed text directly
        break; // item changed
      id = GetComboboxVal(IDC_CONF_COMBO_FONT);
      if (HIWORD(wparam) == CBN_SELCHANGE) { // changed selected item
        if (id == 3) {
defaultFontEntry:
          id = is_chinese_exe ? 1 : 0;
          SetComboboxVal(IDC_CONF_COMBO_FONT, id); // select default entry
        }
      } else if (HIWORD(wparam) == CBN_KILLFOCUS) { // user moves focus away
        GetDlgItemTextW(hwnd, IDC_CONF_COMBO_FONT, buf, sizeof(buf)/sizeof(WCHAR)); // get text in the associated edit box
        val = isFontNameTooLong(buf);
        if (val == -1) // should not be empty
          goto defaultFontEntry;
        else if (id == 3 || memcmp(buf, WT(FONT_LIST_SEPARATOR), sizeof(WT(FONT_LIST_SEPARATOR))) == 0) // selected "---"
          goto defaultFontEntry;
        else if (val) { // font name too long
          msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_FONT_TOO_LONG);
          goto defaultFontEntry;
        }
        // TODO: fontName might have an alias in a different language. Check?
      //HIWORD(wparam) == CBN_SELENDOK: // user selects an item by either mouse, or by expanding the dropdown and pressing enter, or by using arrow keys without expanding the dropdown
      //HIWORD(wparam) == CBN_SELENDCANCEL: // user expands the dropdown and uses arrow keys to select an item, but does not press enter and leaves the combobox; however, in this case, the item is still selected, without triggering CBN_SELENDOK [in this case, the current selection returned by CB_GETCURSEL might be incorrect: It won't be the item shown in the associated edit box, but rather, the item that user's mouse last "touches" (not clicked, though) before CBN_SELENDCANCEL (i.e. the dropdown closes); therefore, must directly compare the text]
      } else if (readFontIndex == CB_ERR && HIWORD(wparam) == CBN_DROPDOWN) {
        break; // if there is no matching font on the system, mark this item as changed as long as the dropdown shows. This is because if there is a font whose name starts with `readFontName`, Windows will automatically select this entry without triggering `CBN_SELCHANGE` (see CB_FINDSTRING vs CB_FINDSTRINGEXACT)
      } else
        return FALSE;
      if (id != readFontIndex)
        break; // item changed
    default:
      return FALSE;
    }
    break; // item changed
  default:
    return FALSE;
  }

  // item changed
  if (has_item_changed == 0) { // -1: ignore
    has_item_changed = TRUE;
    buf[0] = L'*'; // add an asterisk sign at the beginning of the title
    if (GetWindowTextW(hwnd, buf+1, sizeof(buf)/sizeof(WCHAR)-1))
      SetWindowTextW(hwnd, buf);
  }
  return TRUE;
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
    for (int i = IDS_ENTRY_TYPE_BEGIN_2; i <= IDS_ENTRY_TYPE_END; ++i) {
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
      // change exe filename
      memcpy(tsw_exe_conf_path, tsw_exe_path, cur_path_len+1);
      strcpy(tsw_exe_conf_path+cur_path_len+1, tsw_exe[type]);
      // check if the exe file is legitimate (if not, no need to show dialog)
      if (checkInit(tsw_exe_conf_path)) {
        while (DialogBoxIndirectParamW(hIns, pDlg_new[is_chinese_exe] ? pDlg_new[is_chinese_exe] : pDlg_old[is_chinese_exe], hwnd, (DLGPROC)dialog_conf_proc, type) == IDTRYAGAIN) // when choosing a new exe file with a different language by clicking on button IDC_CONF_BUTTON_EXE_MORE, the return value will be IDTRYAGAIN, in which case should remain in the loop
          type = -1; // unless for the first time, in which case `type` is specified, in all later times when a new conf dialog reshows, they are for a custom TSW exe
      }
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
  app_title[0] = (WORD)LoadStringLangW(IDS_TITLE, APP_LANGUAGE, app_title+1); // set unicode string length at the same time

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
