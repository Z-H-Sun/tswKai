#include "tswLauncher.h"
#include <stdarg.h>

#define APP_LANGUAGE is_chinese ? ID_zh_CN : ID_en_US
#define APP_CONF_LANGUAGE is_chinese_exe ? ID_zh_CN : ID_en_US

#define MODERN_FONT_NAME "Segoe UI"
#define EXE_EN L"Executable path"
#define EXE_CN L"可执行文件路径"
#define BUTTON_NAME_APP (is_chinese ? (L" " BUTTON_NAME_CN) : (L" " BUTTON_NAME_EN))
#define BUTTON_NAME_CONF (is_chinese_exe ? (L" " BUTTON_NAME_CN) : (L" " BUTTON_NAME_EN))
#define BUTTON_EXE_NAME_CONF (is_chinese_exe ? (EXE_CN L" " BUTTON_NAME_CN) : (EXE_EN L" " BUTTON_NAME_EN))
#define BUTTON_NAME_EN L"Button"
#define BUTTON_NAME_CN L"按钮"
#define CHECKBOX_NAME_CONF (is_chinese_exe ? (L" " CHECKBOX_NAME_CN) : (L" " CHECKBOX_NAME_EN))
#define CHECKBOX_NAME_EN L"Checkbox"
#define CHECKBOX_NAME_CN L"复选框"
#define TEXTBOX_EXE_NAME_CONF (is_chinese_exe ? (EXE_CN L" " TEXTBOX_NAME_CN) : (EXE_EN L" " TEXTBOX_NAME_EN))
#define TEXTBOX_NAME_EN L"Textbox"
#define TEXTBOX_NAME_CN L"文本框"
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
#ifndef TRBN_THUMBPOSCHANGING
#define TRBN_THUMBPOSCHANGING (0U-1501U-1)
typedef struct {
  NMHDR hdr;
  DWORD dwPos;
  int nReason;
} NMTRBTHUMBPOSCHANGING;
#endif

typedef struct {
  DWORD pid;
  HWND hwnd;
} MUTEXINFO;

// from tswLauncher.c
extern char tsw_exe_path[], data_path[];
extern const char* tsw_exe[];
extern int cur_path_len;

// from patch.c
extern BOOL has_item_changed, is_chinese_exe, is_v_3_1_0;
extern INT_PTR readFontIndex;
extern const int interval_min_vals[], interval_max_vals[], interval_default_vals[];
extern UCHAR misop_vals[];
BOOL isFontNameTooLong(WCHAR* fontName_w);
int isFontDefaultFont(WCHAR* fontName_w);
BOOL checkInit(char* exe_path);
void checkSuper(BOOL chkState, BOOL setAll);
void checkMove(BOOL chkState);
void checkMisop(BOOL chkState);
void checkKeybd(BOOL chkState);
void checkAllPatches();
BOOL saveAllPatches(INT_PTR res);
void closeDlg(INT_PTR res);

// from font.c
extern ULONG_PTR gpToken;
BOOL getFontNameLang(WCHAR* fontName, WORD lang, WCHAR* outFontName);
