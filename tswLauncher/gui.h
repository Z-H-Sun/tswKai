#include "tswLauncher.h"
#include <stdarg.h>

#define ID_zh_CN MAKELANGID(LANG_CHINESE, SUBLANG_CHINESE_SIMPLIFIED)
#define ID_en_US MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT)
#define APP_LANGUAGE is_chinese ? ID_zh_CN : ID_en_US

#define MODERN_FONT_NAME "Segoe UI"
#define BUTTON_NAME_APP (is_chinese ? (L" " BUTTON_NAME_CN) : (L" " BUTTON_NAME_EN))
#define BUTTON_NAME_EN L"Button"
#define BUTTON_NAME_CN L"按钮"
#define DROPDOWNLIST_NAME_APP (is_chinese ? DROPDOWNLIST_NAME_CN : DROPDOWNLIST_NAME_EN)
#define DROPDOWNLIST_NAME_EN L"Drop-down list"
#define DROPDOWNLIST_NAME_CN L"下拉框"
#define FAIL_FORMAT_MSG_EN L"Warning: App internal error #"
#define FAIL_FORMAT_MSG_CN L"警告：程序内部错误 #"

// in case the following macros are not defined in <Windows.h>...
#ifndef _WIN32_WINNT_VISTA
#define _WIN32_WINNT_VISTA 0x0600
#endif
#ifndef _WIN32_WINNT_WIN7
#define _WIN32_WINNT_WIN7 0x0601
#endif
#ifndef BCM_SETTEXTMARGIN
#define BCM_SETTEXTMARGIN 0x1604
#endif
#ifndef TTI_INFO
#define TTI_INFO 1
#endif
#ifndef TTI_WARNING
#define TTI_WARNING 2
#endif

typedef struct {
  DWORD pid;
  HWND hwnd;
} MUTEXINFO;

// from tswLauncher.c
extern char tsw_exe_path[], data_path[];
extern const char* tsw_exe[];
extern int cur_path_len;
