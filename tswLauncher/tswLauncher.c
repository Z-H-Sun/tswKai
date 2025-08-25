#include "tswLauncher.h"
#include <shlwapi.h>

#define hwnd hWndMain // in this file, hwnd is mainly for the main window
extern HWND hWndMain;
extern WCHAR app_title[]; // note: app_title[0] is (WORD)length; the actual unicode string starts from app_title+1
extern BOOL is_chinese;

char ini_state = 2; // 2 = have .ini and .bak.ini; 1 = have .ini but not .bak.ini; 0 = have neither
char data_path[MAX_PATH] = {0}, cur_path[MAX_PATH] = {0}, tsw_exe_path[MAX_PATH] = {0}, tsw_ini_path[MAX_PATH] = {0}, tsw_ini_bak_path[MAX_PATH] = {0};
const char* tsw_exe[] = {TARGET_EXE_1, TARGET_EXE_2, TARGET_EXE_3, TARGET_EXE_4};
int data_path_len, cur_path_len;

static size_t unicode2ansi(WCHAR* u, size_t uLen, char* a, size_t aLen) { // unicode wide char to ANSI char; returns 0 if there is an invalid char
  int acp = GetACP();
  BOOL invalid_char = FALSE;
  BOOL* p_invalid_char = NULL;
  if (acp != CP_UTF7 && acp != CP_UTF8) // for UTF-7 or UTF-8, it's unlikely for data loss to happen; also, according to MSDN, lpUsedDefaultChar must be NULL in these cases
    p_invalid_char = &invalid_char;
  int len = WideCharToMultiByte(CP_ACP, 0, u, uLen, a, aLen-1, NULL, p_invalid_char);
  a[len] = '\0'; // terminate string; note: MSDN: `WideCharToMultiByte` won't automatically terminate the string if `cchWideChar` is not -1
  if (invalid_char) return 0; // must check this, because TSW is not unicode-compatible and thus won't work if there is any invalid char under the current system code page
  return len;
}

static void get_ini_path() { // %windir\\TSW12.ini
// Note: TSW saves the paths into a file under Windows dir, which is a privileged path: %windir%\\TSW12.ini
// For Windows Vista and above, the UAC views TSW as a legacy program and will virtualize it and will thus redirect the file output to%LocalAppData%\\VirtualStore\\Windows\\TSW12.ini
// Therefore, for our app, tswLauncher, to "see" the same file as TSW does, we need to meet several criteria:
// * It must be 32-bit (so we must use a 32-bit C compiler)
// * It is not run as administrator and should not contain <trustInfo> node in the manifest (provided in this dir: 2.manifest)
// See https://learn.microsoft.com/en-us/previous-versions/technet-magazine/cc138019(v=msdn.10)
  WCHAR tsw_ini_path_w[MAX_PATH];
  DWORD len = GetWindowsDirectoryW(tsw_ini_path_w, MAX_PATH);
  len = unicode2ansi(tsw_ini_path_w, len, tsw_ini_path, MAX_PATH); // %windir% is unlikely to include invalid char, but just to make sure it doesn't; otherwise TSW won't work
  if (!len || len+strlen(TSW_INI_BAK) >= MAX_PATH) {
    msgbox(HWND_TOPMOST, MB_ICONERROR, IDS_ERR_WINDIR_INVALID);
    safe_exit(1);
  }
  tsw_ini_path[len++] = '\\';
  memcpy(tsw_ini_path+len, TSW_INI, sizeof(TSW_INI));
  memcpy(tsw_ini_bak_path, tsw_ini_path, len);
  memcpy(tsw_ini_bak_path+len, TSW_INI_BAK, sizeof(TSW_INI_BAK));
}

static void get_app_path() { // .
  WCHAR cur_path_w[MAX_PATH];
  WCHAR* title_path = app_title+1+app_title[0]; // since `app_title` was initialized with '\0's, it is ensured that it's always terminated with '\0' without the need to manually do it (so `memcpy` also does not need to copy the trailing '\0')
  memcpy(title_path, L" - ", 3*sizeof(WCHAR));
  title_path += 3;
  DWORD len_w = GetModuleFileNameW(NULL, cur_path_w, MAX_PATH);
  if (!len_w)
    goto app_path_fail;
  if (len_w >= MAX_PATH)
    goto app_path_too_long;
  WCHAR* basename_w = wcsrchr(cur_path_w, L'\\');
  if (!basename_w)
    goto app_path_fail;
  len_w = (++basename_w)-cur_path_w + sizeof(TSW_DIR)-1;
  if (app_title[0]+3+len_w >= MAX_PATH) { // make sure the title is not too long
app_path_too_long:
    memcpy(title_path, cur_path_w, 64*sizeof(WCHAR)); // only copy part of the path
    memcpy(title_path+64, L"...", 3*sizeof(WCHAR)); // then end it with ellipses
    goto app_path_fail;
  }
  memcpy(basename_w, WT(TSW_DIR), sizeof(TSW_DIR)*sizeof(WCHAR)); // replace basename with TSW_DIR
  memcpy(title_path, cur_path_w, len_w*sizeof(WCHAR));
  cur_path_len = unicode2ansi(cur_path_w, len_w, cur_path, MAX_PATH);
  if ((!cur_path_len) || (cur_path_len+1+strlen(TARGET_EXE_3) >= MAX_PATH)) { // make sure exe filename "./TSW1.2r3/TSW.CNJP.exe" is not too long
app_path_fail:
    msgbox(HWND_TOPMOST, MB_ICONERROR, IDS_ERR_APPDIR_INVALID);
    safe_exit(1);
  }
  memcpy(tsw_exe_path, cur_path, cur_path_len);
  tsw_exe_path[cur_path_len] = '\\'; // the basename for TSW executable will be appended later
}

static void get_full_path(char *fname, int *p_len) { // normalize filename
  char tmp_path[MAX_PATH];
  memcpy(tmp_path, fname, *p_len);
  tmp_path[*p_len] = '\\'; // GetFullPathName for root dir like "C:" without trailing "\\" will give current dir
  tmp_path[(*p_len)+1] = '\0'; // terminate string
  *p_len = GetFullPathName(tmp_path, MAX_PATH, fname, NULL);
  if (!(*p_len) || *p_len >= MAX_PATH)
    *p_len = 0; // fail
  else if (!PathIsDirectory(fname))
    *p_len = 0; // does not exist
  else if (fname[*p_len - 1] == '\\') { // remove trailing path separator
    (*p_len)--;
    fname[*p_len] = '\0';
  }
}

static BOOL write_ini() {
  FILE* file_tsw_ini = fopen(tsw_ini_path, "w");
  if (!file_tsw_ini)
    return FALSE;
  cur_path[cur_path_len] = '\n';
  data_path[data_path_len] = '\n';
  if (fwrite(data_path, 1, data_path_len + 1, file_tsw_ini) < data_path_len+1 ||
      fwrite(cur_path, 1, cur_path_len + 1, file_tsw_ini) < cur_path_len+1) {
    fclose(file_tsw_ini);
    return FALSE;
  }
  cur_path[cur_path_len] = '\0';
  data_path[data_path_len] = '\0';
  fclose(file_tsw_ini);
  return TRUE;
}

void init_path() { // dirty work about the old paths in old .ini
// If valid .bak exists: use old data-save path in this file & current installation path; overwrite .ini file and ignore configs therein
// ElseIf valid .ini exists: use old data-save path in this file & current installation path; overwrite .ini file, and when its old installation path differs from the current one, make a backup copy of it as .bak
// Else : use current data-save path and current installation path
  FILE *file_tsw_ini = NULL;
  char tsw_path[MAX_PATH]; // old installation path
  int tsw_path_len = 0;

  if (ini_state == 2) {
    get_app_path(); // initial path checks
    get_ini_path();
    if (!PathIsDirectory(cur_path)) {
      msgbox(HWND_TOPMOST, MB_ICONERROR, IDS_ERR_GAME_PATH_MISSING);
      safe_exit(1);
    }

    file_tsw_ini = fopen(tsw_ini_bak_path, "r"); // first check if there is a backup .ini file
    if (!file_tsw_ini) // file not found
      ini_state--;
    else if (!fgets(data_path, MAX_PATH, file_tsw_ini)) { // empty file
      ini_state--;
      fclose(file_tsw_ini);
    } // otherwise, do not close yet, will read the second line as `tsw_path`
  }

  if (ini_state == 1) {
    file_tsw_ini = fopen(tsw_ini_path, "r"); // then check the current .ini file
    if (!file_tsw_ini) // same as above
      ini_state--;
    else if (!fgets(data_path, MAX_PATH, file_tsw_ini)) {
      ini_state--;
      fclose(file_tsw_ini);
    } // otherwise, do not close yet, will read the second line as `tsw_path`
  }

  if (ini_state == 0) {
    memcpy(data_path, cur_path, cur_path_len);
    memcpy(data_path + cur_path_len, "\\" DAT_DIR, sizeof(DAT_DIR)+1); // use `{cur_path}\\Savedat` as new `data_path`
    data_path_len = cur_path_len+1 + sizeof(DAT_DIR)-1;
    if (!PathIsDirectory(data_path)) {
      msgbox(HWND_TOPMOST, MB_ICONERROR, IDS_ERR_SAVEDIR_MISSING);
      safe_exit(1);
    }
  } else {
    data_path_len = strlen(data_path);
    if (data_path_len && data_path[data_path_len-1] == '\n') // remove the trailing \n
      data_path_len--;
    if (data_path_len >= MAX_PATH-1) // too long path
      data_path_len = 0;
    else
      get_full_path(data_path, &data_path_len);

    if (!data_path_len) { // fail
      fclose(file_tsw_ini);
      if (msgbox(HWND_TOPMOST, MB_YESNO | MB_ICONEXCLAMATION, IDS_ERR_SAVEDIR_INVALID, (ini_state == 1) ? WT(TSW_INI) : WT(TSW_INI_BAK), data_path) == IDNO) {
        MessageBeep(MB_ICONEXCLAMATION);
        safe_exit(1);
      } else { // try next `ini_state`
        if (ini_state == 2) { // remove the .bak file
          SetFileAttributes(tsw_ini_bak_path, FILE_ATTRIBUTE_NORMAL); // remove readonly attribute
          if (!DeleteFile(tsw_ini_bak_path))
            msgbox(HWND_TOPMOST, MB_ICONEXCLAMATION, IDS_ERR_CANT_DELETE, WT(TSW_INI_BAK));
        }
        ini_state--;
        init_path();
        return;
      }
    }

    if (ini_state) {
      fgets(tsw_path, MAX_PATH, file_tsw_ini);
      fclose(file_tsw_ini);
      tsw_path_len = strlen(tsw_path);
      if (tsw_path_len && tsw_path[tsw_path_len-1] == '\n') // remove the trailing \n
        tsw_path_len--;
      get_full_path(tsw_path, &tsw_path_len);
      if (tsw_path_len != cur_path_len || memicmp(tsw_path, cur_path, cur_path_len)) { // different installation path
        if (ini_state == 1) { // TSW12.INI -> TSW12.BAK.INI
          DeleteFile(tsw_ini_bak_path);
          if (!MoveFile(tsw_ini_path, tsw_ini_bak_path) && msgbox(HWND_TOPMOST, MB_YESNO | MB_ICONEXCLAMATION, IDS_ERR_CANT_RENAME) == IDNO) {
            MessageBeep(MB_ICONEXCLAMATION);
            safe_exit(1);
          }
        }
        if (data_path[tsw_path_len] != '\\' ||
            memicmp(data_path, tsw_path, tsw_path_len))
          tsw_path_len = 0; // no migration recommendation
        // otherwise: old data-save path is under old installation path: recommend migration
      } else { // same installation path
        tsw_path_len = 0; // no migration recommendation
        ini_state--; // if `ini_state` was 1, it will become 0, indicating there is no .bak file (so no need to delete the .bak file in `delete_ini`)
      }

      if (tsw_path_len || // recommend migration; bypass check below
          memicmp(data_path, cur_path, cur_path_len) || // dirname is different, or
          memicmp(data_path+cur_path_len, "\\" DAT_DIR, sizeof(DAT_DIR)+1)) // basename is different
        EnableItem(IDC_MGRT, TRUE); // enable migration button
    }
  }

  if (!write_ini() && // now overwrite .ini file
      msgbox(HWND_TOPMOST, MB_YESNO | MB_ICONEXCLAMATION, IDS_ERR_CANT_WRITE) == IDNO) {
    MessageBeep(MB_ICONEXCLAMATION);
    safe_exit(1);
  }

  if (tsw_path_len) { // recommend migration
    if (msgbox(HWND_TOPMOST, MB_YESNO | MB_ICONINFORMATION, IDS_INFO_SUGGEST_MIGRATION, tsw_path) == IDNO)
      return;
    PostMessage(hwnd, WM_MIGRATE, 0, 0); // delay migration until dialog shown
  }
}

BOOL delete_ini() {
  BOOL success = TRUE;
  if (ini_state) { // delete the .bak file only when `ini_state` is not 0
    SetFileAttributes(tsw_ini_bak_path, FILE_ATTRIBUTE_NORMAL); // remove readonly attribute
    if (!PathFileExists(tsw_ini_bak_path) || // ignore if the file no longer exists
        DeleteFile(tsw_ini_bak_path))
      ini_state = 0; // no need to delete .bak file the next time this function is called
    else {
      msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_CANT_DELETE, WT(TSW_INI_BAK));
      success = FALSE;
    }
  }
  SetFileAttributes(tsw_ini_path, FILE_ATTRIBUTE_NORMAL); // remove readonly attribute
  if (PathFileExists(tsw_ini_path) && // ignore if the file no longer exists
      !DeleteFile(tsw_ini_path)) { // always need to delete the .ini file
    msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_CANT_DELETE, WT(TSW_INI));
    success = FALSE;
  }
  return success;
}

BOOL migrate_data() {
  if (data_path_len >= MAX_PATH-1) // too long [SHFILEOPSTRUCT requires f.pFrom is double-\0 terminated, so the length should not exceed 258 (previous check in `get_full_path` only checks if the length exceeds 259)]
    goto migrate_fail;

  if (!delete_ini())
    goto migrate_fail;

  // show fake progress bar
  HWND hwndProgress = GetDlgItem(hwnd, IDC_PROGRESS);
  ShowWindow(hwndProgress, SW_SHOWNOACTIVATE);
  SendMessageW(hwndProgress, PBM_SETMARQUEE, TRUE, 0);
  EnableWindow(hwnd, FALSE); // disallow user input while copying files. Strangely, even if `SHFILEOPSTRUCT.hwnd` is set, the progress dialog window won't use it as the parent window, so need to disable the main window manually

  data_path[data_path_len+1] = '\0'; // SHFILEOPSTRUCT requires f.pFrom being double-\0 terminated
  cur_path[cur_path_len+1] = '\0'; // SHFILEOPSTRUCT requires f.pTo being double-\0 terminated
  SHFILEOPSTRUCT f = {hwnd, FO_COPY, data_path, cur_path, FOF_NOCONFIRMATION | FOF_NOCONFIRMMKDIR | FOF_NOCOPYSECURITYATTRIBS};
  int ret = SHFileOperation(&f);
  f.fAnyOperationsAborted = ret || f.fAnyOperationsAborted; // if `ret` is non-zero, it also indicates failure

  EnableWindow(hwnd, TRUE);
  ShowWindow(hwndProgress, SW_HIDE);
  SendMessageW(hwndProgress, PBM_SETMARQUEE, FALSE, 0);
  if (f.fAnyOperationsAborted)
    goto migrate_fail;

  EnableItem(IDC_MGRT, FALSE); // migration button no longer useful
  memcpy(data_path, cur_path, cur_path_len); // use `{cur_path}\\Savedat` as new `data_path`
  memcpy(data_path + cur_path_len, "\\" DAT_DIR, sizeof(DAT_DIR)+1);
  data_path_len = cur_path_len+1 + sizeof(DAT_DIR)-1;
  if (!write_ini()) { // now overwrite .ini file
migrate_fail:
    msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_MIGRATION);
    return FALSE;
  }
  msgbox(hwnd, MB_ICONINFORMATION, IDS_INFO_MIGRATION_OK);
  return TRUE;
}

static BOOL wait_read_mem_dword(PROCESS_INFORMATION *p_pi, LPCVOID lpAddr, void *lpOut) {
  int i;
  HANDLE hPrc = p_pi->hProcess;
  for (i = 0; i < TARGET_WAIT_CYCLES; i++) {
    Sleep(TARGET_WAIT_INTERVAL); // wait for 200 ms * 20
    if (!ReadProcessMemory(hPrc, lpAddr, lpOut, TARGET_PTR_LEN, NULL)) {
      msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_WINAPI, GetLastError(), L"ReadProcessMemory");
      break;
    }
    if (*(DWORD*)lpOut) // get non-0 value
      return TRUE;
  }
  TerminateProcess(hPrc, 1); // not what we want
  CloseHandle(hPrc);
  CloseHandle(p_pi->hThread);
  return FALSE; // timeout
}

BOOL launch_tsw(int type) {
  strcpy(tsw_exe_path+cur_path_len+1, tsw_exe[type]);
  STARTUPINFO si = {sizeof(si)};
  si.dwFlags = STARTF_FORCEONFEEDBACK;
  PROCESS_INFORMATION pi;
  BOOL success = CreateProcess(tsw_exe_path, NULL, NULL, NULL, FALSE, 0, NULL, cur_path, &si, &pi);

  if (success) {
    MessageBeep(MB_ICONINFORMATION);

    HANDLE TTSW10 = NULL;
    HWND hwndTSW = NULL;
    DWORD hero_status = 0;
    if (! (success = wait_read_mem_dword(&pi, (LPCVOID)TARGET_TTSW_ADDR, &TTSW10)) ) // TTSW10 (main form)
      goto fail;
    if (! (success = wait_read_mem_dword(&pi, (char *)TTSW10 + TARGET_HWND_OFFSET, &hwndTSW)) ) // window handle for TTSW10
      goto fail;
    if (! (success = wait_read_mem_dword(&pi, (LPCVOID)TARGET_STATUS_ADDR, &hero_status)) ) // player's status (HP; ATK; ...), first initialized in TTSW10.syokidata, which can make sure the main form window has been resized and repositioned
      goto fail;
    centerTSW((HWND)hwndTSW);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  } else
fail:
    msgbox(hwnd, MB_ICONEXCLAMATION, IDS_ERR_CANT_RUN, tsw_exe[type]);

  return success;
}
