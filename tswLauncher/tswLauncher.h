// encoding: GBK
#define APP_TITLE "tswLauncher"
#define APP_TITLE_CN "魔塔启动器"
#define APP_VERSION 1,0,0,0
#define APP_VERSION_STR "v1.0"
#define APP_MUTEX APP_TITLE "_MuTeX"
#define APP_MUTEX_BUFSIZE sizeof(MUTEXINFO)
#define TARGET_TITLE "TSW"
#define TARGET_TITLE_CN "魔塔"
#define TARGET_PTR_LEN sizeof(DWORD)
#define TARGET_BASE_ADDR 0x400000
#define TARGET_HWND_OFFSET 0xC0
#define TARGET_TTSW_ADDR (TARGET_BASE_ADDR + 0x08C510)
#define TARGET_STATUS_ADDR (TARGET_BASE_ADDR + 0x0B8688)
#define TARGET_WAIT_CYCLES 20
#define TARGET_WAIT_INTERVAL 200
#define IDI_APP 1
#define IDD_APP 1
#define IDS_TITLE 1
#define IDS_ENTRY1 101
#define IDS_ENTRY2 102
#define IDS_ENTRY3 103
#define IDS_ENTRY4 104
#define IDS_TIP1 201
#define IDS_TIP2 202
#define IDS_TIP3 203
#define IDS_ERR1 301
#define IDS_ERR2 302
#define IDS_ERR3 303
#define IDS_ERR4 304
#define IDS_ERR5 305
#define IDS_ERR6 306
#define IDS_ERR7 307
#define IDS_ERR8 308
#define IDS_ERR9 309
#define IDS_ERRA 310
#define IDS_ERRB 311
#define IDS_ERRC 312
#define IDS_ERRD 313
#define IDC_TYPE 101
#define IDC_OPEN 102
#define IDC_INIT 103
#define IDM_MANIFEST 1
#define DLG_FONT_SIZE 9
#define DAT_DIR "\\Savedat"
#define TSW_DIR "\\TSW1.2r1"
#define TSW_EXE {"\\TSW.exe", "\\TSW.EN.exe", "\\TSW.CN.exe", "\\TSW.CNJP.exe"}
#define TSW_INI "\\TSW12.INI"
#define TSW_INI_BAK "\\TSW12.BAK.INI"
#define TSW_CLS "TTSW10"

#define WINVER 0x0500 // minimum windows 2000
#define _WIN32_IE 0x0500 // minimal version 5.8 for common control
#include <windows.h>
#include <commctrl.h>

#include <stdio.h>
#include <stdint.h>

int msgbox(unsigned int uType, unsigned int uID, ...);
void centerTSW(HWND hwndTSW);
void safe_exit(int status);
void init_path();
BOOL delete_ini();
BOOL launch_tsw(int type);
