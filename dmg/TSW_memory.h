// aliases (a trick from https://stackoverflow.com/a/17615531/11979352)
// do not use the linked win32 api if already loaded in TSW.exe
#define LoadLibraryA __LoadLibraryA
#define GetProcAddress __GetProcAddress
#define MessageBoxA __MessageBoxA
#define DrawTextA __DrawTextA
#define BitBlt __BitBlt
#define CreateCompatibleBitmap __CreateCompatibleBitmap
#define CreateCompatibleDC __CreateCompatibleDC
#define CreateFontIndirectA __CreateFontIndirectA
#define CreatePenIndirect __CreatePenIndirect
#define DeleteObject __DeleteObject
#define SelectObject __SelectObject
#define SaveDC __SaveDC
#define RestoreDC __RestoreDC
#define DeleteDC __DeleteDC
#define SetBkMode __SetBkMode
#define SetROP2 __SetROP2
#define SetTextColor __SetTextColor
#define TextOutA __TextOutA

#define WINVER 0x0500 // minimum windows 2000
#include <windows.h>

// Delphi uses "Borland register" calling convention (argv passed to eax/edx/ecx)
// so each extern function bears with __attribute__((__regparm__(3))) (using 3 registers before pushing params on stack)
// __stdcall means that the callee will clean up the stack
// https://en.wikipedia.org/wiki/X86_calling_conventions#Borland_register
#define REGCALL __stdcall __attribute__((__regparm__(3)))

#define TTSW10_ADDR 0x48C510
#define TTSW10_HERO_ITEM_ADDR 0x4B86C4
#define TTSW10_HERO_STATUS_ADDR 0x4B8688
#define TTSW10_HERO_SACRED_SHIELD_ADDR 0x4B872C
#define TTSW10_ENEMY_STATUS_ADDR 0x489910
#define TTSW10_MAP_STATUS_ADDR 0x4B8934
#define TTSW10_STATUS_FACTOR_ADDR 0x4B8904
#define TTSW10_IS_IN_3RD_ROUND_ADDR 0x4B8908
#define TTSW10_GAMEMAP_FRAME_ADDR 0x48C5D2
#define TTSW10_GAMEMAP_BITMAP_1_ADDR 0x48C514
#define TTSW10_GAMEMAP_BITMAP_2_ADDR 0x48C518
#define TTSW10_GAMEMAP_LEFT_ADDR 0x48C578
#define TTSW10_GAMEMAP_TOP_ADDR 0x48C57C
#define TTSW10_EVENT_COUNT_ADDR 0x48C5AC

#define TTSW10_IMAGE6_OFFSET 0x254
#define TCONTROL_WIDTH_OFFSET 0x2C
#define TCONTROL_HWND_OFFSET 0xC0
#define TFORM_TCANVAS_OFFSET 0x120
#define TCANVAS_TCONTROL_OFFSET 0x34 // according to reverse engineering of TBitmap.GetCanvas and TBitmapCanvas.Create, [TBitmapCanvas+0x28/0x30/0x34] all are the corresponding TBitmap; in TControlCanvas.SetControl, only [TControlCanvas+0x34] is the corresponding TCanvas

typedef struct {
    INT32 HP;
    INT32 ATK;
    INT32 DEF;
    INT32 GOLD;
} HADG;
typedef struct {
    HADG HADG;
    INT32 floor; INT32 maxFloor; INT32 x; INT32 y;
    INT32 ylKey; INT32 redKey; INT32 blueKey; INT32 altarLv;
} STATUS;
typedef struct {
    INT32 swordLv; INT32 shieldLv;
    BOOL orbHero; BOOL orbWisdom; BOOL orbFlight;
    BOOL cross; BOOL elixir; BOOL mattock;
    BOOL desBall; BOOL warpWing; BOOL upWing;
    BOOL loWing; BOOL dragonSl; BOOL snowXtal;
    BOOL magicKey; BOOL supMatk; BOOL luckGold;
} ITEM;

// delphi system functions defined in TSW.exe
typedef HDC REGCALL _TCanvas_GetHandle(HANDLE hTCanvas);
typedef HANDLE REGCALL _TBitmap_GetCanvas(HANDLE hTBitmap);
_TCanvas_GetHandle* TCanvas_GetHandle = (_TCanvas_GetHandle*)0x41A950;
_TBitmap_GetCanvas* TBitmap_GetCanvas = (_TBitmap_GetCanvas*)0x41DAD8;

// win32api functions already loaded in TSW.exe
#undef LoadLibraryA
#undef GetProcAddress
#undef MessageBoxA
#undef DrawTextA
#undef BitBlt
#undef CreateCompatibleBitmap
#undef CreateCompatibleDC
#undef CreateFontIndirectA
#undef CreatePenIndirect
#undef DeleteObject
#undef SelectObject
#undef SaveDC
#undef RestoreDC
#undef DeleteDC
#undef SetBkMode
#undef SetROP2
#undef SetTextColor
#undef TextOutA
typedef HMODULE WINAPI _LoadLibraryA(LPCSTR lpLibFileName);
typedef FARPROC WINAPI _GetProcAddress(HMODULE hModule, LPCSTR lpProcName);
typedef int WINAPI _MessageBoxA(HWND hWnd,LPCSTR lpText,LPCSTR lpCaption,UINT uType);
typedef int WINAPI _DrawTextA(HDC hdc,LPCSTR lpchText,int cchText,LPRECT lprc,UINT format);
typedef WINBOOL WINAPI _BitBlt(HDC hdc,int x,int y,int cx,int cy,HDC hdcSrc,int x1,int y1,DWORD rop);
typedef HBITMAP WINAPI _CreateCompatibleBitmap(HDC hdc,int cx,int cy);
typedef HDC WINAPI _CreateCompatibleDC(HDC hdc);
typedef HFONT WINAPI _CreateFontIndirectA(CONST LOGFONTA *lplf);
typedef HPEN WINAPI _CreatePenIndirect(CONST LOGPEN *plpen);
typedef WINBOOL WINAPI _DeleteObject(HGDIOBJ ho);
typedef HGDIOBJ WINAPI _SelectObject(HDC hdc,HGDIOBJ h);
typedef int WINAPI _SaveDC(HDC hdc);
typedef WINBOOL WINAPI _RestoreDC(HDC hdc,int nSavedDC);
typedef WINBOOL WINAPI _DeleteDC(HDC hdc);
typedef int WINAPI _SetBkMode(HDC hdc,int mode);
typedef int WINAPI _SetROP2(HDC hdc,int rop2);
typedef COLORREF WINAPI _SetTextColor(HDC hdc,COLORREF color);
typedef WINBOOL WINAPI _TextOutA(HDC hdc,int x,int y,LPCSTR lpString,int c);
_LoadLibraryA* LoadLibraryA = (_LoadLibraryA*)0x404BFC;
_GetProcAddress* GetProcAddress = (_GetProcAddress*)0x404B84;
_MessageBoxA* MessageBoxA = (_MessageBoxA*)0x401260;
_DrawTextA* DrawTextA = (_DrawTextA*)0x404F0C;
_BitBlt* BitBlt = (_BitBlt*)0x404C5C;
_CreateCompatibleBitmap* CreateCompatibleBitmap = (_CreateCompatibleBitmap*)0x404C7C;
_CreateCompatibleDC* CreateCompatibleDC = (_CreateCompatibleDC*)0x404C84;
_CreateFontIndirectA* CreateFontIndirectA = (_CreateFontIndirectA*)0x404C94;
_CreatePenIndirect* CreatePenIndirect = (_CreatePenIndirect*)0x404CA4;
_DeleteObject* DeleteObject = (_DeleteObject*)0x404CCC;
_SelectObject* SelectObject = (_SelectObject*)0x404DCC;
_SaveDC* SaveDC = (_SaveDC*)0x404DC4;
_RestoreDC* RestoreDC = (_RestoreDC*)0x404DBC;
_DeleteDC* DeleteDC = (_DeleteDC*)0x404CBC;
_SetBkMode* SetBkMode = (_SetBkMode*)0x404DE4;
_SetROP2* SetROP2 = (_SetROP2*)0x404DF4;
_SetTextColor* SetTextColor = (_SetTextColor*)0x404E04;
_TextOutA* TextOutA = (_TextOutA*)0x404E34;
