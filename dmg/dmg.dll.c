// Delphi uses "Borland register" calling convention (argv passed to eax/edx/ecx), so each extern function bears with __attribute__((__regparm__(3))): https://en.wikipedia.org/wiki/X86_calling_conventions#Borland_register
// It is both more human-readable and more efficient to use `push` than `mov esp...`: https://stackoverflow.com/a/4535996; therefore the following 3 "-m..." options were added while compiling: https://stackoverflow.com/a/24982391
// Likewise, no need to align stack on 16-byte boundaries (because this is not Linux; Windows use 4-byte boundaries instead), so added the 4-th "-m..." option: https://stackoverflow.com/a/43597693/11979352
// Likewise, no need for procedure prolog and epilog (push ebp; mov ebp, esp; ...; leave), so added the following "-f..." option: https://stackoverflow.com/a/21620940/11979352
// You MUST use a 32-bit compiler because only 32-bit DLL can be loaded by 32-bit TSW exe
// gcc -std=gnu99 -Os -s -DNDEBUG -shared -Wl,--enable-auto-image-base,--enable-auto-import -mpush-args -mno-accumulate-outgoing-args -mno-stack-arg-probe -mpreferred-stack-boundary=2 -fomit-frame-pointer dmg.dll.def dmg.dll.c -o dmg.dll -lgdi32 -lmsimg32

#define WINVER 0x0500 // minimum windows 2000
#include <windows.h>

#define TTSW10_ADDR 0x48C510
#define TTSW10_HERO_ITEM_ADDR 0x4B86C4
#define TTSW10_HERO_STATUS_ADDR 0x4B8688
#define TTSW10_ENEMY_STATUS_ADDR 0x489910
#define TTSW10_MAP_STATUS_ADDR 0x4B8934
#define TTSW10_STATUS_FACTOR_ADDR 0x4B8904
#define TTSW10_GAMEMAP_BITMAP_1_ADDR 0x48C514
#define TTSW10_GAMEMAP_BITMAP_2_ADDR 0x48C518
#define TTSW10_GAMEMAP_LEFT_ADDR 0x48C578
#define TTSW10_GAMEMAP_TOP_ADDR 0x48C57C
#define TTSW10_EVENT_COUNT_ADDR 0x48C5AC
#define TTSW10_IMAGE6_OFFSET 0x254
#define TCONTROL_WIDTH_OFFSET 0x2C
#define TCONTROL_HWND_OFFSET 0xC0
#define TFORM_TCANVAS_OFFSET 0x120
#define REGCALL __attribute__((__regparm__(3)))
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
typedef DWORD REGCALL func0(void);
typedef DWORD REGCALL func1(DWORD);
typedef DWORD REGCALL func2(DWORD, DWORD);
typedef DWORD REGCALL func3(DWORD, DWORD, DWORD);
func1* TCanvas_GetHandle = (func1*)0x41A950;
func1* TBitmap_GetCanvas = (func1*)0x41DAD8;
FARPROC WINAPI Kernel32_LoadLibraryA = (FARPROC)0x404BFC;
FARPROC WINAPI Kernel32_GetProcAddress = (FARPROC)0x404B84;
FARPROC WINAPI User32_MessageBoxA = (FARPROC)0x401260;
FARPROC WINAPI User32_DrawTextA = (FARPROC)0x404F0C;
FARPROC WINAPI Gdi32_BitBlt = (FARPROC)0x404C5C;
FARPROC WINAPI Gdi32_CreateCompatibleBitmap = (FARPROC)0x404C7C;
FARPROC WINAPI Gdi32_CreateCompatibleDC = (FARPROC)0x404C84;
FARPROC WINAPI Gdi32_CreateFontIndirect = (FARPROC)0x404C94;
FARPROC WINAPI Gdi32_CreatePenIndirect = (FARPROC)0x404CA4;
FARPROC WINAPI Gdi32_DeleteObject = (FARPROC)0x404CCC;
FARPROC WINAPI Gdi32_SelectObject = (FARPROC)0x404DCC;
FARPROC WINAPI Gdi32_SaveDC = (FARPROC)0x404DC4;
FARPROC WINAPI Gdi32_RestoreDC = (FARPROC)0x404DBC;
FARPROC WINAPI Gdi32_DeleteDC = (FARPROC)0x404CBC;
FARPROC WINAPI Gdi32_SetBkMode = (FARPROC)0x404DE4;
FARPROC WINAPI Gdi32_SetROP2 = (FARPROC)0x404DF4;
FARPROC WINAPI Gdi32_SetTextColor = (FARPROC)0x404E04;
FARPROC WINAPI Gdi32_TextOut = (FARPROC)0x404E34;
const COLORREF color_OK = RGB(0x22, 0xAA, 0x22);
const COLORREF color_suspicious = RGB(0xC0, 0xA0, 0x60);
const COLORREF color_no_go = RGB(0xFF, 0x22, 0x22);
const COLORREF color_item = RGB(0x40, 0x7F, 0xC0);
const COLORREF color_polyline = RGB(0x88, 0x99, 0x88);
const COLORREF color_background = RGB(0x66, 0x66, 0x66);
const COLORREF color_foreground = RGB(0xFE, 0xFE, 0xFE);
const LOGFONTA lfont_dmg = {16, 6, 0, 0, 700, // height, width, esc, orient, weight
    0, 0, 0, 0, 0, 0, 3, 0, // italic, underline, strike, charset, out, clip, quality, pitch
    "Tahoma"};
HPEN hPen_stroke, hPen_polyline; HFONT hFont_dmg;
HDC hMemDC; HBITMAP hMemBmp;

#define msgboxDWORD10(h,i) msgboxDWORD(h,i,10) // use 10-base
static void REGCALL msgboxDWORD(HANDLE TTSW10, DWORD i, int base) { // for debug use; show value of int `i`
    HWND TTSW10_hWnd = *(HWND*)((DWORD)TTSW10+TCONTROL_HWND_OFFSET);
    char st[10];
    itoa(i, st, base);
    User32_MessageBoxA(TTSW10_hWnd, st, "Debug Output", MB_ICONINFORMATION | MB_SETFOREGROUND);
}

static int REGCALL itoa2(WORD i, char* a){ // return value is `len`; output string is (char*)a
    if (i == 0xFFFF) { // infinity
        *(DWORD*)a = *(DWORD*)"???"; // set first four bytes
        return 3;
    }
    char len, digit;
    if (i < 10) len = 1;
    else if (i < 100) len = 2;
    else if (i < 1000) len = 3;
    else if (i < 10000) len = 4;
    else len = 5;
    for (char k = len; --k >= 0; ) {
        digit = i % 10u;
        i = i / 10u;
        a[k] = digit + 0x30;
    }
    return (int)len;
}

static char REGCALL getMonsterID(UCHAR tileID) { // tileID -> monsterID
    if (tileID < 61)
        return -1; // 1-60: not a monster tile
    else if (tileID < 97)
        return tileID-61 >> 1; // slimeG - vampire
    else if (tileID < 106)
        return 18; // octopus
    else if (tileID == 122)
        return 19; // dragon
    else if (tileID < 133)
        return -1; // octopus/dragon not for battle
    else if (tileID < 159)
        return tileID-93 >> 1; // goldenKnight - GatemanA
    else return -1; // invalid tile
}

#define norm44(x,f) (x-1)/f+1 // this will divide x by 44 and ceil [NOTE: to minimize the risk of INT32 overflow of `x` (though unlikely), this is unsigned division, so need to rule out the case when x==0]
static DWORD REGCALL getMonsterDmgCri(char monsterID) { // HIWORD=cri (0-32766; 0x7FFF=no show); LOWORD=dmg (0-65534; 0xFFFF=???); if the most significant bit is 1 (i.e., cri < 0), it means that the dmg is greater or equal to hero's HP
    ITEM TSW_hero_items = *(ITEM*)TTSW10_HERO_ITEM_ADDR;
    HADG TSW_hero_HADG = *(HADG*)TTSW10_HERO_STATUS_ADDR;
    HADG* TSW_enemy_HADG = (HADG*)TTSW10_ENEMY_STATUS_ADDR; // 33 monsters
    BOOL cross = TSW_hero_items.cross, dragonSl = TSW_hero_items.dragonSl;
    UINT factor = *(UINT*)TTSW10_STATUS_FACTOR_ADDR; // 0 or 43 (back side)
    int hHP = TSW_hero_HADG.HP, hATK = TSW_hero_HADG.ATK, hDEF = TSW_hero_HADG.DEF;
    int mHP = TSW_enemy_HADG[monsterID].HP, mATK = TSW_enemy_HADG[monsterID].ATK, mDEF = TSW_enemy_HADG[monsterID].DEF;
    if (factor) {
        factor++; // 0 or 44 (back side)
        mHP *= factor; mATK *= factor; mDEF *= factor;
    }
    int dmg, cri;

    int oneTurnDmg = mATK - hDEF;
    if (oneTurnDmg < 0)
        oneTurnDmg = 0;
    BOOL hATKDouble = FALSE;
    if (((monsterID == 17 || monsterID == 12 || monsterID == 13) && cross) || (monsterID == 19 && dragonSl))
        hATKDouble = TRUE;
    int oneTurnDmg2Mon = hATK - mDEF;
    if (oneTurnDmg2Mon <= 0) { // in TSW, when you battle with vampire / dragon, even with Cross / DragonSlayer, you will not be able to attack it if your ATK <= its DEF, despite that your ATK*2 > its DEF
        dmg = 0xFFFF; // infinity
        cri = 1-oneTurnDmg2Mon;
        if (factor)
            cri = norm44(cri, factor);
        if (cri > 0x7FFF) // max val [not likely, through]
            cri = 0xFFFF; // no show + set most significant bit
        else
            cri |= 0x8000; // set most significant bit
    }
    else {
        if (hATKDouble)
            oneTurnDmg2Mon = (hATK << 1) - mDEF; // this is real `oneTurnDmg2Mon` when fighting vampire / dragon
        // Note: there is risk of INT32 overflow here (though unlikely, and TSW will also crash in such cases); need to convert to unsigned int below
        int turnsCount = 0;
        if (mHP) // do not calculate if mHP is 0 [not likely, through]
            turnsCount = (mHP-1) / (UINT)oneTurnDmg2Mon;
        dmg = turnsCount * oneTurnDmg; // this step might overflow (though unlikely)
        if (dmg == 0)
            cri = 0x7FFF; // no show
        else {
            int tmp = (mHP-1)/turnsCount + mDEF;
            if (hATKDouble)
                tmp >>= 1;
            cri = tmp + 1 - hATK;
            if (factor)
                cri = norm44(cri, factor);
            if (cri > 0x7FFF) // max val [not likely, through]
                cri = 0x7FFF; // no show
            if ((UINT)dmg > hHP) // this comparison must be done before the dmg value is normalized by 44
                cri |= 0x8000; // set most significant bit
            if (factor)
                dmg = norm44(dmg, factor);
            if ((UINT) dmg > 0xFFFF) // max val [not likely, through] (dmg might have overflown, though unlikely)
                dmg = 0xFFFF; // infinity
            }        
    }
    return dmg | (cri << 16); // MAKELONG(dmg, cri)
}

static void REGCALL draw_dmg(HANDLE TTSW10) {
    DWORD TSW_tileSize = *(DWORD*)(*(DWORD*)((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
    STATUS TSW_hero_status = *(STATUS*)TTSW10_HERO_STATUS_ADDR;
    WORD offset = 123u*(UCHAR)TSW_hero_status.floor + 2u;
    char* TSW_curFloor_tiles = (char*)TTSW10_MAP_STATUS_ADDR+offset;
    char strInt_1[8]; int lenInt_1;
    char strInt_2[8]; int lenInt_2;
    Gdi32_BitBlt(hMemDC, 0, 0, 440, 440, NULL, 0, 0, WHITENESS);
    for (UCHAR i = 0; i < 121; i++) {
        char mID = getMonsterID(TSW_curFloor_tiles[i]);
        if (mID == -1)
            continue;
        WORD x = i % 11u * (UCHAR)TSW_tileSize + 1;
        WORD y = (i / 11u + 1) * (UCHAR)TSW_tileSize - 15;
        DWORD dmgCri = getMonsterDmgCri(mID); // TODO: create a hash for existing monsters...
        WORD dmg = LOWORD(dmgCri), cri=HIWORD(dmgCri) & 0x7FFF;

        if ((INT32)dmgCri < 0) { // most significant bit set; inadequate HP
            Gdi32_SetTextColor(hMemDC, color_no_go);
            Gdi32_SetROP2(hMemDC, R2_BLACK);
        }
        else {
            Gdi32_SetTextColor(hMemDC, color_foreground);
            Gdi32_SetROP2(hMemDC, R2_COPYPEN);
        }
        BeginPath(hMemDC); // TODO:
        lenInt_1 = itoa2(dmg, strInt_1);
        Gdi32_TextOut(hMemDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF) {
            lenInt_2 = itoa2(cri, strInt_2);
            Gdi32_TextOut(hMemDC, x, y-12, strInt_2, lenInt_2);
        }
        EndPath(hMemDC); // TODO:
        StrokePath(hMemDC); // TODO:
        Gdi32_TextOut(hMemDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF) {
            Gdi32_TextOut(hMemDC, x, y-12, strInt_2, lenInt_2);
        }
    }
}

static void REGCALL overlay(HANDLE TTSW10) {
    DWORD TSW_tileSize = *(DWORD*)(*(DWORD*)((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
    WORD TSW_mapSize = 11u * (UCHAR)TSW_tileSize;
    DWORD TSW_mapLeft = *(DWORD*)(TTSW10_GAMEMAP_LEFT_ADDR), TSW_mapTop = *(DWORD*)(TTSW10_GAMEMAP_TOP_ADDR);

    HANDLE TTSW10_TCanvas = *(HANDLE*)((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    HDC TTSW10_TCanvas_hDC = (HDC)TCanvas_GetHandle((DWORD)TTSW10_TCanvas);
    TransparentBlt(TTSW10_TCanvas_hDC, TSW_mapLeft, TSW_mapTop, TSW_mapSize, TSW_mapSize, hMemDC, 0, 0, TSW_mapSize, TSW_mapSize, RGB(0xFF,0xFF,0xFF)); // For some unknown reason, the black color can't be used as the mask color on some computers (what the heck?), see https://stackoverflow.com/q/70062625/11979352
}

extern void ini(void) { // initialize
    HANDLE TTSW10 = *(HANDLE*)TTSW10_ADDR;
    LOGPEN lpen = {PS_SOLID, {3, 0}, color_background};
    hPen_stroke = (HPEN)Gdi32_CreatePenIndirect(&lpen);
    lpen.lopnColor = color_polyline;
    hPen_polyline = (HPEN)Gdi32_CreatePenIndirect(&lpen);
    hFont_dmg = (HFONT)Gdi32_CreateFontIndirect(&lfont_dmg);

    HANDLE TTSW10_TCanvas = *(HANDLE*)((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    HDC TTSW10_TCanvas_hDC = (HDC)TCanvas_GetHandle((DWORD)TTSW10_TCanvas);
    hMemDC = (HDC)Gdi32_CreateCompatibleDC(TTSW10_TCanvas_hDC);
    hMemBmp = (HBITMAP)Gdi32_CreateCompatibleBitmap(TTSW10_TCanvas_hDC, 440, 440);
    Gdi32_SetBkMode(hMemDC, TRANSPARENT);
    Gdi32_SaveDC(hMemDC); // see `RestoreDC` in `finalize`
    Gdi32_SelectObject(hMemDC, hMemBmp);
    Gdi32_SelectObject(hMemDC, hPen_stroke);
    Gdi32_SelectObject(hMemDC, hFont_dmg);

    //RECT rect = {180, 30, 620, 440};
    //User32_DrawTextA(TTSW10_TCanvas_hDC, "Golden Knight is Tsundere!\nSays Zeno.", -1, &rect, DT_CENTER);
}
extern void fin(void) { // finalize
    Gdi32_RestoreDC(hMemDC, -1); // this will deselect custom GDI objects so they can be properly disposed of
    Gdi32_DeleteDC(hMemDC);
    Gdi32_DeleteObject(hMemBmp);
    Gdi32_DeleteObject(hPen_stroke);
    Gdi32_DeleteObject(hPen_polyline);
    Gdi32_DeleteObject(hFont_dmg);
}
extern void inj(void) { // inject
    HANDLE TTSW10 = *(HANDLE*)TTSW10_ADDR;
    DWORD TSW_event_count = *(DWORD*)TTSW10_EVENT_COUNT_ADDR;
    if (!TSW_event_count)
    {
        draw_dmg(TTSW10);
        overlay(TTSW10);
    }/*
    HANDLE TSW_mBitmap_1 = *(HANDLE*)TTSW10_GAMEMAP_BITMAP_1_ADDR;
    HANDLE TSW_mBitmap_2 = *(HANDLE*)TTSW10_GAMEMAP_BITMAP_2_ADDR;
    HDC TSW_mBitmap_hDC = (HDC)TCanvas_GetHandle(TBitmap_GetCanvas((DWORD)TSW_mBitmap_1));
    draw_dmg(TTSW10, TSW_mBitmap_hDC);
    TSW_mBitmap_hDC = (HDC)TCanvas_GetHandle(TBitmap_GetCanvas((DWORD)TSW_mBitmap_2));
    draw_dmg(TTSW10, TSW_mBitmap_hDC);*/
}
