// It is both more human-readable and more efficient to use `push` than `mov esp...`: https://stackoverflow.com/a/4535996; therefore the following 3 "-m..." options were added while compiling: https://stackoverflow.com/a/24982391
// Likewise, no need to align stack on 16-byte boundaries (because this is not Linux; Windows use 4-byte boundaries instead), so added the 4-th "-m..." option: https://stackoverflow.com/a/43597693/11979352
// Likewise, no need for procedure prolog and epilog (push ebp; mov ebp, esp; ...; leave), so added the following "-f..." option: https://stackoverflow.com/a/21620940/11979352
// You MUST use a 32-bit compiler because only 32-bit DLL can be loaded by 32-bit TSW exe
// gcc -std=gnu99 -Os -s -DNDEBUG -shared -Wl,--enable-auto-image-base,--enable-auto-import -mpush-args -mno-accumulate-outgoing-args -mno-stack-arg-probe -mpreferred-stack-boundary=2 -fomit-frame-pointer dmg.dll.def dmg.dll.c -o dmg.dll -lgdi32 -lmsimg32

#include "TSW_memory.h"
#define NOINLINE __attribute__((noinline))
#define get_p(p) *(DWORD*)(p) // get the DWORD value from the given pointer in memory
#define get_h(p) *(HANDLE*)(p) // same as above; but the type is instead HANDLE

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
NOINLINE static void REGCALL msgboxDWORD(HANDLE TTSW10, DWORD i, int base) { // for debug use; show value of int `i`
    HWND TTSW10_hWnd = *(HWND*)((DWORD)TTSW10+TCONTROL_HWND_OFFSET);
    char st[10];
    itoa(i, st, base);
    MessageBoxA(TTSW10_hWnd, st, "Debug Output", MB_ICONINFORMATION | MB_SETFOREGROUND);
}

NOINLINE static int REGCALL itoa2(WORD i, char* a){ // return value is `len`; output string is (char*)a
    if (i == 0xFFFF) { // infinity
        get_p(a) = get_p("???"); // set first four bytes
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

NOINLINE static char REGCALL getMonsterID(UCHAR tileID) { // tileID -> monsterID
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
NOINLINE static DWORD REGCALL getMonsterDmgCri(char monsterID) { // HIWORD=cri (0-32766; 0x7FFF=no show); LOWORD=dmg (0-65534; 0xFFFF=???); if the most significant bit is 1 (i.e., cri < 0), it means that the dmg is greater or equal to hero's HP
    ITEM TSW_hero_items = *(ITEM*)TTSW10_HERO_ITEM_ADDR;
    HADG TSW_hero_HADG = *(HADG*)TTSW10_HERO_STATUS_ADDR;
    HADG* TSW_enemy_HADG = (HADG*)TTSW10_ENEMY_STATUS_ADDR; // 33 monsters
    BOOL cross = TSW_hero_items.cross, dragonSl = TSW_hero_items.dragonSl;
    UINT factor = get_p(TTSW10_STATUS_FACTOR_ADDR); // 0 or 43 (back side)
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

extern void REGCALL dmg(HANDLE TTSW10_TCanvas, DWORD TSW_mapLeft, DWORD TSW_mapTop, HANDLE TSW_cur_mBitmap) {
    HANDLE TTSW10 = get_h(TTSW10_ADDR);
    DWORD TSW_tileSize = get_p(get_p((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
    WORD TSW_mapSize = 11u * (UCHAR)TSW_tileSize;
    HDC TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_cur_mBitmap));
    BitBlt(hMemDC, 0, 0, TSW_mapSize, TSW_mapSize, TSW_mBitmap_hDC, 0, 0, SRCCOPY);

    STATUS TSW_hero_status = *(STATUS*)TTSW10_HERO_STATUS_ADDR;
    WORD offset = 123u*(UCHAR)TSW_hero_status.floor + 2u;
    char* TSW_curFloor_tiles = (char*)TTSW10_MAP_STATUS_ADDR+offset;
    char strInt_1[8]; int lenInt_1;
    char strInt_2[8]; int lenInt_2;
    for (UCHAR i = 0; i < 121; i++) {
        char mID = getMonsterID(TSW_curFloor_tiles[i]);
        if (mID == -1)
            continue;
        WORD x = i % 11u * (UCHAR)TSW_tileSize + 1;
        WORD y = (i / 11u + 1) * (UCHAR)TSW_tileSize - 15;
        DWORD dmgCri = getMonsterDmgCri(mID); // TODO: create a hash for existing monsters...
        WORD dmg = LOWORD(dmgCri), cri=HIWORD(dmgCri) & 0x7FFF;

        if ((INT32)dmgCri < 0) { // most significant bit set; inadequate HP
            SetTextColor(hMemDC, color_no_go);
            SetROP2(hMemDC, R2_WHITE);
        }
        else {
            SetTextColor(hMemDC, color_foreground);
            SetROP2(hMemDC, R2_COPYPEN);
        }
        BeginPath(hMemDC); // TODO:
        lenInt_1 = itoa2(dmg, strInt_1);
        TextOutA(hMemDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF) {
            lenInt_2 = itoa2(cri, strInt_2);
            TextOutA(hMemDC, x, y-12, strInt_2, lenInt_2);
        }
        EndPath(hMemDC); // TODO:
        StrokePath(hMemDC); // TODO:
        TextOutA(hMemDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF) {
            TextOutA(hMemDC, x, y-12, strInt_2, lenInt_2);
        }
    }

    HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    BitBlt(TTSW10_TCanvas_hDC, TSW_mapLeft, TSW_mapTop, TSW_mapSize, TSW_mapSize, hMemDC, 0, 0, SRCCOPY);
}

extern void ini(void) { // initialize
    HANDLE TTSW10 = get_h(TTSW10_ADDR);
    LOGPEN lpen = {PS_SOLID, {3, 0}, color_background};
    hPen_stroke = CreatePenIndirect(&lpen);
    lpen.lopnColor = color_polyline;
    hPen_polyline = CreatePenIndirect(&lpen);
    hFont_dmg = CreateFontIndirectA(&lfont_dmg);

    HANDLE TTSW10_TCanvas = get_h((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    hMemDC = CreateCompatibleDC(TTSW10_TCanvas_hDC);
    hMemBmp = CreateCompatibleBitmap(TTSW10_TCanvas_hDC, 440, 440);
    SetBkMode(hMemDC, TRANSPARENT);
    SaveDC(hMemDC); // see `RestoreDC` in `finalize`
    SelectObject(hMemDC, hMemBmp);
    SelectObject(hMemDC, hPen_stroke);
    SelectObject(hMemDC, hFont_dmg);

    //RECT rect = {180, 30, 620, 440};
    //DrawTextA(TTSW10_TCanvas_hDC, "Golden Knight is Tsundere!\nSays Zeno.", -1, &rect, DT_CENTER);
}
extern void fin(void) { // finalize
    RestoreDC(hMemDC, -1); // this will deselect custom GDI objects so they can be properly disposed of
    DeleteDC(hMemDC);
    DeleteObject(hMemBmp);
    DeleteObject(hPen_stroke);
    DeleteObject(hPen_polyline);
    DeleteObject(hFont_dmg);
}
extern void inj(void) { // inject
    HANDLE TTSW10 = get_h(TTSW10_ADDR);
    HANDLE TTSW10_TCanvas = get_h((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    DWORD TSW_mapLeft = get_p(TTSW10_GAMEMAP_LEFT_ADDR), TSW_mapTop = get_p(TTSW10_GAMEMAP_TOP_ADDR);
    HANDLE TSW_mBitmap_1 = get_h(TTSW10_GAMEMAP_BITMAP_1_ADDR);
    HANDLE TSW_mBitmap_2 = get_h(TTSW10_GAMEMAP_BITMAP_2_ADDR);
    BYTE TSW_cur_frame = (BYTE)get_p(TTSW10_GAMEMAP_FRAME_ADDR);
    HANDLE TSW_cur_mBitmap = TSW_cur_frame ? TSW_mBitmap_2 : TSW_mBitmap_1;

    //DWORD TSW_event_count = get_p(TTSW10_EVENT_COUNT_ADDR);
    //if (!TSW_event_count)
        dmg(TTSW10_TCanvas, TSW_mapLeft, TSW_mapTop, TSW_cur_mBitmap);
    /*
    HANDLE TSW_mBitmap_1 = get_h(TTSW10_GAMEMAP_BITMAP_1_ADDR);
    HANDLE TSW_mBitmap_2 = get_h(TTSW10_GAMEMAP_BITMAP_2_ADDR);
    HDC TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_mBitmap_1));
    draw_dmg(TTSW10, TSW_mBitmap_hDC);
    TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_mBitmap_2));
    draw_dmg(TTSW10, TSW_mBitmap_hDC);*/
}
