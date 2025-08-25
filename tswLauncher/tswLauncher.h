#ifdef _WIN64
#error Must use 32-bit C compiler!
#endif
#define WT(text) __WT(text) // convert to wide char unicode string
#define __WT(text) L##text
#define STRINGIFY(x) __S(x) // convert number to text
#define __S(x) #x

#include "msg.h"
#define APP_TITLE "tswLauncher"
#define APP_TITLE_CN "魔塔启动器"
#define APP_VERSION_MAJOR 3
#define APP_VERSION_MINOR 0
#define APP_VERSION APP_VERSION_MAJOR,APP_VERSION_MINOR,0,0
#define APP_VERSION_STR "v" STRINGIFY(APP_VERSION_MAJOR) "." STRINGIFY(APP_VERSION_MINOR)
#define APP_MUTEX APP_TITLE "_MuTeX"
#define APP_MUTEX_BUFSIZE sizeof(MUTEXINFO)
#define TARGET_VERSION_STR "1.2"
#define TARGET_RUN is_chinese ? L"运行" : L"run"
#define TARGET_CONFIG is_chinese ? L"配置" : L"configure"
#define TARGET_CLS_NAME "TTSW10"
#define TARGET_EXE_1 "TSW.exe"
#define TARGET_EXE_2 "TSW.EN.exe"
#define TARGET_EXE_3 "TSW.CN.exe"
#define TARGET_EXE_4 "TSW.CNJP.exe"
#define TARGET_PTR_LEN sizeof(DWORD)
#define TARGET_BASE_ADDR 0x400000
#define TARGET_HWND_OFFSET 0xC0
#define TARGET_TTSW_ADDR (TARGET_BASE_ADDR + 0x08C510)
#define TARGET_STATUS_ADDR (TARGET_BASE_ADDR + 0x0B8688)
#define TARGET_WAIT_CYCLES 20
#define TARGET_WAIT_INTERVAL 200

#define IDI_APP 1
#define IDI_OPEN 101
#define IDI_MGRT 102
#define IDI_INIT 103
#define IDI_CONF 104

#define IDD_APP 1
#define IDD_CONFIG 2

#define IDS_TITLE 1
#define IDS_ENTRY_TYPE_EN 101
#define IDS_ENTRY_TYPE_EN_REV 102
#define IDS_ENTRY_TYPE_CN 103
#define IDS_ENTRY_TYPE_CN_REV 104
#define IDS_TIP_BEGIN 201
#define IDS_TIP_TYPE IDS_TIP_BEGIN
#define IDS_TIP_OPEN 202
#define IDS_TIP_MGRT 203
#define IDS_TIP_INIT 204
#define IDS_TIP_CONF 205

#define IDC_BEGIN 101
#define IDC_TYPE IDC_BEGIN
#define IDC_OPEN 102
#define IDC_MGRT 103
#define IDC_INIT 104
#define IDC_CONF 105
#define IDC_END IDC_CONF

#define IDM_MANIFEST 1
#define DLG_FONT_SIZE 9

#define WINVER 0x0501 // minimum windows xp
#define _WIN32_IE 0x0600 // minimal version 6.0 for common control
#undef UNICODE // must use ASNI code page to read/write TSW.INI file, because TSW is not unicode-compatible
#include <windows.h>
#include <commctrl.h>

#include <stdio.h>
#include <stdint.h>

int msgbox(HWND hwnd, unsigned int uType, unsigned int uID, ...);
void centerTSW(HWND hwndTSW);
void safe_exit(int status);
void init_path();
BOOL delete_ini();
BOOL launch_tsw(int type);

// for gui.c
#define SetFocusedItemAsync(id) PostMessageW(hwnd, WM_NEXTDLGCTL, (WPARAM)GetDlgItem(hwnd, id), TRUE) // set focus; ref: https://devblogs.microsoft.com/oldnewthing/20040802-00/?p=38283
#define SetFocusedItemSync(id) SendMessageW(hwnd, WM_NEXTDLGCTL, (WPARAM)GetDlgItem(hwnd, id), TRUE) // this will cause the thread to wait until the set-focus message is processed
#define GetComboboxVal(id) SendDlgItemMessageW(hwnd, id, CB_GETCURSEL, 0, 0)
#define SetComboboxVal(id, val) SendDlgItemMessageW(hwnd, id, CB_SETCURSEL, (WPARAM)(val), 0)
