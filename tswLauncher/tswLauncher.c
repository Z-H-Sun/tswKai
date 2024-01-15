#include "tswLauncher.h"
#include <shlwapi.h>

extern char app_title[MAX_PATH];

char ini_state = 2; // 2 = have .ini and .bak.ini; 1 = have .ini but not .bak.ini; 0 = have neither
char data_path[MAX_PATH] = {0}, cur_path[MAX_PATH] = {0}, tsw_exe_path[MAX_PATH] = {0}, tsw_ini_path[MAX_PATH] = {0}, tsw_ini_bak_path[MAX_PATH] = {0};
char *tsw_exe[4] = TSW_EXE;
int data_path_len, cur_path_len;

void get_ini_path() { // %windir\\TSW12.ini
// Note: TSW saves the paths into a file under Windows dir, which is a privileged path: %windir%\\TSW12.ini
// For Windows Vista and above, the UAC views TSW as a legacy program and will virtualize it and will thus redirect the file output to%LocalAppData%\\VirtualStore\\Windows\\TSW12.ini
// Therefore, for our app, tswLauncher, to "see" the same file as TSW does, we need to meet several criteria:
// * It must be 32-bit (so we must use a 32-bit C compiler)
// * It is not run as administrator and should not contain <trustInfo> node in the manifest (provided in this dir: 2.manifest)
// See https://learn.microsoft.com/en-us/previous-versions/technet-magazine/cc138019(v=msdn.10)
  int len = GetWindowsDirectory(tsw_ini_path, MAX_PATH);
  if (!len || len+strlen(TSW_INI_BAK) >= MAX_PATH) {
    msgbox(MB_ICONERROR, IDS_ERR2);
    safe_exit(1);
  }
  strcat(tsw_ini_bak_path, tsw_ini_path);
  strcat(tsw_ini_bak_path, TSW_INI_BAK);
  strcat(tsw_ini_path, TSW_INI);
}

void get_app_path() { // .
  int len = GetModuleFileName(NULL, cur_path, MAX_PATH);
  if (!len || len >= MAX_PATH) {
    strncat(app_title, cur_path, MAX_PATH/4);
    msgbox(MB_ICONERROR, IDS_ERR3);
    safe_exit(1);
  }
  char *basename = strrchr(cur_path, '\\');
  basename[0] = '\0'; // mask basename
  strcat(cur_path, TSW_DIR);
  strcat(tsw_exe_path, cur_path); // the basename for TSW executable will be appended later
  strcat(app_title, cur_path);
  cur_path_len = strlen(cur_path);
//return (int)(basename - cur_path);
}

void get_full_path(char *fname, int *p_len) { // normalize filename
  char tmp_path[MAX_PATH] = {0};
  strncat(tmp_path, fname, *p_len);
  tmp_path[*p_len] = '\\'; // GetFullPathName for root dir like "C:" without trailing "\\" will give current dir
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

void init_path() { // dirty work about the old paths in old .ini
// If valid .bak exists: use old data-save path in this file & current installation path; overwrite .ini file and ignore configs therein
// ElseIf valid .ini exists: use old data-save path in this file & current installation path; overwrite .ini file, and when its old installation path differs from the current one, make a backup copy of it as .bak
// Else : use current data-save path and current installation path
  FILE *file_tsw_ini = NULL;

  if (ini_state == 2) {
    get_app_path(); // initial path checks
    get_ini_path();
    if (!PathIsDirectory(cur_path)) {
      msgbox(MB_ICONERROR, IDS_ERR1);
      safe_exit(1);
    }

    file_tsw_ini = fopen(tsw_ini_bak_path, "r"); // first check if there is a backup .ini file
    if (!file_tsw_ini) // file not found
      ini_state--;
    else {
      if (!fgets(data_path, MAX_PATH, file_tsw_ini)) // empty file
        ini_state--;
      fclose(file_tsw_ini);
    }
  }

  if (ini_state == 1) {
    file_tsw_ini = fopen(tsw_ini_path, "r"); // then check the current .ini file
    if (!file_tsw_ini) // same as above
      ini_state--;
    else if (!fgets(data_path, MAX_PATH, file_tsw_ini)) {
      ini_state--;
      fclose(file_tsw_ini);
    }
  } // otherwise, do not close yet, will read the second line as `tsw_path`

  if (ini_state == 0) {
    strcpy(data_path, cur_path);
    strcat(data_path, DAT_DIR); // use `{cur_path}\\Savedat` as new `data_path`
    data_path_len = strlen(data_path);
    if (!PathIsDirectory(data_path) && !CreateDirectory(data_path, NULL)) // mkdir if not existent
      msgbox(MB_ICONEXCLAMATION, IDS_ERR8);
  } else {
    data_path_len = strlen(data_path);
    if (data_path_len && data_path[data_path_len-1] == '\n') // remove the trailing \n
      data_path_len--;
    if (data_path_len >= MAX_PATH-1) // too long path
      data_path_len = 0;
    else
      get_full_path(data_path, &data_path_len);

    if (!data_path_len) { // fail
      if (ini_state == 1)
        fclose(file_tsw_ini);
      if (msgbox(MB_YESNO | MB_ICONEXCLAMATION, IDS_ERR4, (ini_state == 1) ? TSW_INI : TSW_INI_BAK, data_path) == IDNO) {
        MessageBeep(MB_ICONEXCLAMATION);
        safe_exit(1);
      } else { // try next `ini_state`
        if (ini_state == 2 && !DeleteFile(tsw_ini_bak_path)) // remove the .bak file
          msgbox(MB_ICONEXCLAMATION, IDS_ERR5, TSW_INI_BAK);
        ini_state--;
        init_path();
        return;
      }
    }

    if (ini_state == 1) {
      char tsw_path[MAX_PATH] = {0};
      int tsw_path_len;
      fgets(tsw_path, MAX_PATH, file_tsw_ini);
      fclose(file_tsw_ini);
      tsw_path_len = strlen(tsw_path);
      if (tsw_path_len && tsw_path[tsw_path_len-1] == '\n') // remove the trailing \n
        tsw_path_len--;
      get_full_path(tsw_path, &tsw_path_len);
      if (stricmp(tsw_path, cur_path)) { // when 0: same installation path; skip
        DeleteFile(tsw_ini_bak_path); // TSW12.INI -> TSW12.BAK.INI
        if (!MoveFile(tsw_ini_path, tsw_ini_bak_path) && msgbox(MB_YESNO | MB_ICONEXCLAMATION, IDS_ERR6) == IDNO) {
          MessageBeep(MB_ICONEXCLAMATION);
          safe_exit(1);
        }
      } else
        ini_state--; // there will be no .bak file
    }
  }

  file_tsw_ini = fopen(tsw_ini_path, "w"); // now overwrite .ini file
  if (!file_tsw_ini) {
    if (msgbox(MB_YESNO | MB_ICONEXCLAMATION, IDS_ERR7) == IDYES)
      return;
    MessageBeep(MB_ICONEXCLAMATION);
    safe_exit(1);
  }
  cur_path[cur_path_len] = '\n';
  data_path[data_path_len] = '\n';
  fwrite(data_path, 1, data_path_len + 1, file_tsw_ini);
  fwrite(cur_path, 1, cur_path_len + 1, file_tsw_ini);
  cur_path[cur_path_len] = '\0';
  data_path[data_path_len] = '\0';
  fclose(file_tsw_ini);
}

BOOL delete_ini() {
  BOOL success = TRUE;
  if (msgbox(MB_YESNO | MB_ICONINFORMATION, IDS_ERRC) == IDNO)
    return FALSE;
  if (ini_state && !DeleteFile(tsw_ini_bak_path)) { // delete the .bak file only when `ini_state` is not 0
    msgbox(MB_ICONEXCLAMATION, IDS_ERR5, TSW_INI_BAK);
    success = FALSE;
  }
  if (!DeleteFile(tsw_ini_path)) { // always need to delete the .ini file
    msgbox(MB_ICONEXCLAMATION, IDS_ERR5, TSW_INI);
    success = FALSE;
  }
  return success;
}

BOOL wait_read_mem_dword(PROCESS_INFORMATION *p_pi, LPCVOID lpAddr, void *lpOut) {
  int i;
  HANDLE hPrc = p_pi->hProcess;
  for (i = 0; i < TARGET_WAIT_CYCLES; i++) {
    Sleep(TARGET_WAIT_INTERVAL); // wait for 100 ms * 20
    if (!ReadProcessMemory(hPrc, lpAddr, lpOut, TARGET_PTR_LEN, NULL)) {
      msgbox(MB_ICONEXCLAMATION, IDS_ERRA, GetLastError(), "ReadProcessMemory");
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
  strcat(tsw_exe_path, tsw_exe[type]);
  STARTUPINFO si = {0};
  PROCESS_INFORMATION pi = {0};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_FORCEONFEEDBACK;
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
    msgbox(MB_ICONEXCLAMATION, IDS_ERR9, tsw_exe[type]);

  tsw_exe_path[cur_path_len] = '\0';
  return success;
}
