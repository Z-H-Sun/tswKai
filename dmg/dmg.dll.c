// It is both more human-readable and more efficient to use `push` than `mov esp...`: https://stackoverflow.com/a/4535996; therefore the following 3 "-m..." options were added while compiling: https://stackoverflow.com/a/24982391
// Likewise, no need to align stack on 16-byte boundaries (because this is not Linux; Windows use 4-byte boundaries instead), so added the 4-th "-m..." option: https://stackoverflow.com/a/43597693/11979352
// Likewise, no need for procedure prolog and epilog (push ebp; mov ebp, esp; ...; leave), so added the following "-f..." option: https://stackoverflow.com/a/21620940/11979352
// You MUST use a 32-bit compiler because only 32-bit DLL can be loaded by 32-bit TSW exe
// gcc -std=gnu99 -Os -s -DNDEBUG -shared -Wl,--enable-auto-image-base,--enable-auto-import -mpush-args -mno-accumulate-outgoing-args -mno-stack-arg-probe -mpreferred-stack-boundary=2 -fomit-frame-pointer dmg.dll.def dmg.dll.c -o dmg.dll -lgdi32

#include "TSW_memory.h"
#define NOINLINE __attribute__((noinline))
#define get_p(p) *(const DWORD *const)(p) // get the DWORD value from the given pointer in memory
#define get_h(p) *(const HANDLE *const)(p) // same as above; but the type is instead HANDLE
#define get_t(p, t) *(const t *const)(p) // same as above; but the type is user-defined `t`

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

#define DWORD_M_DMG_CRI_ADDR (DWORD *const)0x489C00 // idle memory block from 0x489BA8 till 0x48A000
#define BOOL_NEED_UPDATE_ADDR (BYTE *const)0x4BA1B6 // idle memory block from 0x4BA1B5 till 0x4BB000
#define HMEMDC_ADDR (HDC *const)0x4BA1B8
#define HMEMBMP_1_ADDR (HBITMAP *const)0x4BA1BC
#define HMEMBMP_2_ADDR (HBITMAP *const)0x4BA1C0
#define HPEN_STROKE_ADDR (HPEN *const)0x4BA1C4
#define HPEN_POLYLINE_ADDR (HPEN *const)0x4BA1C8
#define HFONT_DMG_ADDR (HFONT *const)0x4BA1CC
DWORD *const p_m_dmg_cri = DWORD_M_DMG_CRI_ADDR; // 121 DWORDs; this stores each tile's damage / critical value of the current floor
BYTE *const p_need_update = BOOL_NEED_UPDATE_ADDR; // the i-th bit: should update hMemBmp[i] or not (i=0,1; from right to left); if the 2-rd bit is set, do not update; the initial value is 3
HDC *const p_hMemDC = HMEMDC_ADDR;
HBITMAP *const p_hMemBmp = HMEMBMP_1_ADDR; // 2 HBITMAPs; 2 game map bitmaps because there are 2 frames
HPEN *const p_hPen_stroke = HPEN_STROKE_ADDR, *p_hPen_polyline = HPEN_POLYLINE_ADDR;
HFONT *const p_hFont_dmg = HFONT_DMG_ADDR;
#define m_dmg_cri p_m_dmg_cri
#define need_update (*p_need_update)
#define hMemDC (*p_hMemDC)
#define hMemBmp p_hMemBmp
#define hPen_stroke (*p_hPen_stroke)
#define hPen_polyline (*p_hPen_polyline)
#define hFont_dmg (*p_hFont_dmg)

#define msgboxDWORD10(h,i) msgboxDWORD(h,i,10) // use 10-base
NOINLINE static void REGCALL msgboxDWORD(const HANDLE TTSW10, const DWORD i, const int base) { // for debug use; show value of int `i`
    const HWND TTSW10_hWnd = get_t((DWORD)TTSW10+TCONTROL_HWND_OFFSET, HWND);
    char st[10];
    itoa(i, st, base);
    MessageBoxA(TTSW10_hWnd, st, "Debug Output", MB_ICONINFORMATION | MB_SETFOREGROUND);
}

NOINLINE static int REGCALL itoa2(WORD i, char* a){ // return value is `len`; output string is (char*)a
    if (i == 0xFFFF) { // infinity
        *(DWORD*)a = get_p("???"); // set first four bytes
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

NOINLINE static char REGCALL getMonsterID(const UCHAR tileID) { // tileID -> monsterID
    if (tileID < 8) // doors/gates/roads
        return -2; // show magic attack if applicable
    else if (tileID < 61) { // 1-60: not a monster tile
        if (tileID >= 29) // items
            return -2; // show magic attack if applicable
        return -1; }
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
NOINLINE static DWORD REGCALL getMonsterDmgCri(const char monsterID, const BOOL isStrikeFirst) { // HIWORD=cri (0-32766; 0x7FFF=no show); LOWORD=dmg (0-65534; 0xFFFF=???); if the most significant bit is 1 (i.e., cri < 0), it means that the dmg is greater or equal to hero's HP
    const ITEM TSW_hero_items = get_t(TTSW10_HERO_ITEM_ADDR, ITEM);
    const HADG TSW_hero_HADG = get_t(TTSW10_HERO_STATUS_ADDR, HADG);
    const HADG *const TSW_enemy_HADG = (const HADG *const)TTSW10_ENEMY_STATUS_ADDR; // 33 monsters
    const BOOL cross = TSW_hero_items.cross, dragonSl = TSW_hero_items.dragonSl;
    UINT factor = get_p(TTSW10_STATUS_FACTOR_ADDR) + 1; // 1 or 44 (back side)
    const int hHP = TSW_hero_HADG.HP, hATK = TSW_hero_HADG.ATK, hDEF = TSW_hero_HADG.DEF;
    const int mHP = TSW_enemy_HADG[monsterID].HP * factor, mATK = TSW_enemy_HADG[monsterID].ATK * factor, mDEF = TSW_enemy_HADG[monsterID].DEF * factor;
    UINT dmg, cri;

    int oneTurnDmg = mATK - hDEF;
    if (oneTurnDmg < 0)
        oneTurnDmg = 0;
    BOOL hATKDouble = FALSE;
    if (((monsterID == 17 || monsterID == 12 || monsterID == 13) && cross) || (monsterID == 19 && dragonSl))
        hATKDouble = TRUE;
    int oneTurnDmg2Mon = hATK - mDEF;
    if (oneTurnDmg2Mon <= 0) { // in TSW, when you battle with vampire / dragon, even with Cross / DragonSlayer, you will not be able to attack it if your ATK <= its DEF, despite that your ATK*2 > its DEF
        dmg = 0xFFFF; // infinity
        cri = norm44(1-oneTurnDmg2Mon, factor);
        if (cri > 0x7FFF) // max val [not likely, through]
            cri = 0xFFFF; // no show + set most significant bit
        else
            cri |= 0x8000; // set most significant bit
    }
    else {
        if (hATKDouble)
            oneTurnDmg2Mon = (hATK << 1) - mDEF; // this is real `oneTurnDmg2Mon` when fighting vampire / dragon
        // Note: there is risk of INT32 overflow here (though unlikely, and TSW will also crash in such cases); need to convert to unsigned int below
        UINT turnsCount = 0;
        if (mHP > 0) // do not calculate if mHP is 0 [not likely, through]
            turnsCount = (mHP-1) / (UINT)oneTurnDmg2Mon;
        dmg = turnsCount * oneTurnDmg; // this step might overflow (though unlikely)
        if (isStrikeFirst)
            dmg += oneTurnDmg;
        if (dmg == 0)
            cri = 0x7FFF; // no show
        else {
            if (turnsCount) {
                int tmp = (mHP-1) / turnsCount + mDEF;
                if (hATKDouble)
                    tmp >>= 1;
                cri = norm44(tmp + 1 - hATK, factor);
                if (cri > 0x7FFF) // max val [not likely, through]
                    cri = 0x7FFF; // no show
            } else
                cri = 0x7FFF; // for strike-first monsters, even if you already one-turn-kill, it is still possible to have a non-zero damage, in which case the critical value is zero (do not draw this value)
            if (dmg >= hHP) // this comparison must be done before the dmg value is normalized by 44
                cri |= 0x8000; // set most significant bit
            dmg = norm44(dmg, factor);
            if (dmg > 0xFFFF) // max val [not likely, through] (dmg might have overflown, though unlikely)
                dmg = 0xFFFF; // infinity
        }
    }
    return MAKELONG(dmg, cri);
}

extern void cmp(void) { // calculate the damage / critical value for the current whole map
    const STATUS TSW_hero_status = get_t(TTSW10_HERO_STATUS_ADDR, STATUS);
    const UCHAR floor = (const UCHAR)TSW_hero_status.floor;
    const WORD offset = 123u*floor + 2u;
    const char *const TSW_curFloor_tiles = (const char *const)TTSW10_MAP_STATUS_ADDR+offset;
    for (UCHAR i = 0; i < 121; ++i) {
        const char mID = getMonsterID(TSW_curFloor_tiles[i]);
        DWORD dmgCri;
        if (mID < 0) {
            if (mID == -1 || get_p(TTSW10_HERO_SACRED_SHIELD_ADDR))
                dmgCri = (DWORD)(-2); // no show (it is not likely to have cri=0xFFFF and dmg=0xFFFE for a monster)
            else { // check magician / sorcerers' magic attack
                UINT dmg = 0;
                const int hHP = TSW_hero_status.HADG.HP;
                const UINT factor = get_p(TTSW10_STATUS_FACTOR_ADDR) + 1;
                const UCHAR x = i % 11u, y = i / 11u;
                char adjacent[4] = {0};
                if (x >  0)
                    adjacent[0] = getMonsterID(TSW_curFloor_tiles[i -  1]);
                if (x < 10)
                    adjacent[1] = getMonsterID(TSW_curFloor_tiles[i +  1]);
                if (y >  0)
                    adjacent[2] = getMonsterID(TSW_curFloor_tiles[i - 11]);
                if (y < 10)
                    adjacent[3] = getMonsterID(TSW_curFloor_tiles[i + 11]);
                for (UCHAR j = 0; j < 4; ++j) { // adjacent magician A/B
                    if (adjacent[j] == 29)
                        dmg += 200;
                    else if (adjacent[j] == 30)
                        dmg += 100;
                }
                dmg *= factor;
                if ((((WORD*)adjacent)[0] == 0x1010 || ((WORD*)adjacent)[1] == 0x1010) // ((adjacent[0] == 16 && adjacent[1] == 16) || (adjacent[2] == 16 && adjacent[3] == 16))
                    && hHP > 0) // flanked by sorcerers
                    dmg += hHP + 1 >> 1;
                if (dmg) {
                    UINT cri = (dmg >= hHP) ? cri = 0x8000 : 0; // set most significant bit
                    dmg = norm44(dmg, factor);
                    if (dmg > 0xFFFF) // max val [not likely unless you cheat]
                        dmg = 0xFFFF; // infinity
                    dmgCri = MAKELONG(dmg, cri);
                } else
                    dmgCri = (DWORD)(-2); // no show
            }
        }
        else {
            BOOL isStrikeFirst = FALSE; // take strike-first monsters into consideration
            if (floor == 32) {
                if (mID == 20) // 32F Golden Knight
                    isStrikeFirst = TRUE;
            } else if (floor == 50) {
                if (get_p(TTSW10_STATUS_FACTOR_ADDR) && (!get_p(TTSW10_IS_IN_3RD_ROUND_ADDR)) && mID == 15) // 2nd round 50F Zeno
                    isStrikeFirst = TRUE;
            } else if (floor == 40) {
                if (TSW_curFloor_tiles[71] != 7 && TSW_curFloor_tiles[5] != 11 && i < 77) // 40F boss battle (trap triggered; the upstairs tile has not yet appear (40F boss battle not clear yet); monsters in the boss room)
                    isStrikeFirst = TRUE;
            } else if (floor == 49) {
                if (TSW_curFloor_tiles[60] != 7 && i < 44 && get_p(TTSW10_EVENT_COUNT_ADDR)) // 49F boss battle (trap triggered; monsters in the boss room)
                    continue; // if the event is still ongoing, then do not consider refreshing the monster damage yet; otherwise it will be erased by TSW's redrawing later
            } else if (floor == 20) {
                if (TSW_curFloor_tiles[82] != 7 && mID == 17 && get_p(TTSW10_EVENT_COUNT_ADDR)) // 20F boss battle (trap triggered; Vampire)
                    continue; // if the event is still ongoing, then no refreshing like above
            }
            dmgCri = getMonsterDmgCri(mID, isStrikeFirst);
        }
        if (m_dmg_cri[i] != dmgCri) {
            m_dmg_cri[i] = dmgCri;
            need_update |= 3; // both frames should be updated
        }
    }
}

extern void REGCALL dtl(const HDC hDC, const char i, const DWORD xy) { // draw the damage / critical value for a specific tile `i` at a given `xy` coordinate
    const DWORD x = (DWORD)LOWORD(xy), y = (DWORD)HIWORD(xy);
    const DWORD dmgCri = m_dmg_cri[i & 0x7F];
    const WORD dmg = LOWORD(dmgCri), cri=HIWORD(dmgCri) & 0x7FFF;
    HPEN hPen_old; HFONT hFont_old;
    char strInt_1[8]; int lenInt_1;
    char strInt_2[8]; int lenInt_2;

    if (dmgCri == (DWORD)(-2)) // no draw
        return;
    SetBkMode(hDC, TRANSPARENT);
    hPen_old = SelectObject(hDC, hPen_stroke);
    hFont_old = SelectObject(hDC, hFont_dmg);
    if ((INT32)dmgCri < 0) { // most significant bit set; inadequate HP
        SetTextColor(hDC, color_no_go);
        SetROP2(hDC, R2_WHITE);
    }
    else {
        SetTextColor(hDC, color_foreground);
        SetROP2(hDC, R2_COPYPEN);
    }
    BeginPath(hDC); // TODO:
    lenInt_1 = itoa2(dmg, strInt_1);
    if (cri) { // for normal monsters, draw dmg (and cri, if applicable) at bottom left of cell
        TextOutA(hDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF) {
            lenInt_2 = itoa2(cri, strInt_2);
            TextOutA(hDC, x, y-12, strInt_2, lenInt_2);
        }
        EndPath(hDC); // TODO:
        StrokePath(hDC); // TODO:
        TextOutA(hDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF)
            TextOutA(hDC, x, y-12, strInt_2, lenInt_2);
    } else { // cri == 0 means it is magical attack
        const HANDLE TTSW10 = get_h(TTSW10_ADDR);
        const DWORD TSW_tileSize = get_p(get_p((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
        RECT cell = {x-1, y+15-TSW_tileSize, x-1+TSW_tileSize, y+15}; // current cell bounds
        DrawTextA(hDC, strInt_1, lenInt_1, &cell, DT_CENTER | DT_VCENTER | DT_SINGLELINE); // only draw dmg in the middle of cell
        EndPath(hDC); // TODO:
        StrokePath(hDC); // TODO:
        DrawTextA(hDC, strInt_1, lenInt_1, &cell, DT_CENTER | DT_VCENTER | DT_SINGLELINE); // only draw dmg in the middle of cell
    }

    SelectObject(hDC, hPen_old);
    SelectObject(hDC, hFont_old);
}

extern void REGCALL dmp(const HANDLE TTSW10_TCanvas, const DWORD TSW_mapLeft, const DWORD TSW_mapTop, const HANDLE TSW_cur_mBitmap) { // draw the damage / critical value for the current whole map
    if (need_update & 4) // if the 2-nd bit is set, do not update
        return;

    const HANDLE TTSW10 = get_h((DWORD)TTSW10_TCanvas+TCANVAS_TCONTROL_OFFSET); // instead of using `get_h(TTSW10_ADDR)`; saved 2-3 bytes
    const DWORD TSW_tileSize = get_p(get_p((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
    const DWORD TSW_mapSize = 11u * (UCHAR)TSW_tileSize;
    const BYTE TSW_cur_frame = (BYTE)get_p(TTSW10_GAMEMAP_FRAME_ADDR);
    const HDC TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_cur_mBitmap));

    cmp();
    if (need_update & (TSW_cur_frame+1)) { // `TSW_cur_frame`: i=0, 1; if i-th bit (right-to-left) is set
        need_update &= (2-TSW_cur_frame); // `TSW_cur_frame`: i=0, 1; set i-th bit (right-to-left) to be 0

        SelectObject(hMemDC, hMemBmp[TSW_cur_frame]);
        BitBlt(TSW_mBitmap_hDC, 0, 0, TSW_mapSize, TSW_mapSize, hMemDC, 0, 0, SRCCOPY);

        for (UCHAR i = 0; i < 121; ++i) {
            WORD x = i % 11u * (UCHAR)TSW_tileSize + 1;
            WORD y = (i / 11u + 1) * (UCHAR)TSW_tileSize - 15;
            dtl(TSW_mBitmap_hDC, i, MAKELONG(x, y));
        }
    }

    const HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    BitBlt(TTSW10_TCanvas_hDC, get_p(TTSW10_GAMEMAP_LEFT_ADDR), get_p(TTSW10_GAMEMAP_TOP_ADDR), TSW_mapSize, TSW_mapSize, TSW_mBitmap_hDC, 0, 0, SRCCOPY); // instead of using TSW_mapLeft / TSW_mapTop in argv; no need to push on stack
}

extern void ini(void) { // initialize
    const HANDLE TTSW10 = get_h(TTSW10_ADDR);
    LOGPEN lpen = {PS_SOLID, {3, 0}, color_background};
    hPen_stroke = CreatePenIndirect(&lpen);
    lpen.lopnColor = color_polyline;
    hPen_polyline = CreatePenIndirect(&lpen);
    hFont_dmg = CreateFontIndirectA(&lfont_dmg);

    const HANDLE TTSW10_TCanvas = get_h((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    const HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    hMemDC = CreateCompatibleDC(TTSW10_TCanvas_hDC);
    const HANDLE *const pTBitmap = (const HANDLE *const)TTSW10_GAMEMAP_BITMAP_1_ADDR;
    HDC TSW_mBitmap_hDC;
    for (int i = 0; i < 2; ++i) { // for the second loop, will be TTSW10_GAMEMAP_BITMAP_2_ADDR
        hMemBmp[i] = CreateCompatibleBitmap(TTSW10_TCanvas_hDC, 440, 440);
        SelectObject(hMemDC, hMemBmp[i]);
        TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(pTBitmap[i]));
        BitBlt(hMemDC, 0, 0, 440, 440, TSW_mBitmap_hDC, 0, 0, SRCCOPY);
    }
    need_update = 3;
    //RECT rect = {180, 30, 620, 440};
    //DrawTextA(TTSW10_TCanvas_hDC, "Golden Knight is Tsundere!\nSays Zeno.", -1, &rect, DT_CENTER);
}
extern void fin(void) { // finalize
    const HANDLE *const pTBitmap = (const HANDLE *const)TTSW10_GAMEMAP_BITMAP_1_ADDR;
    HDC TSW_mBitmap_hDC;
    for (int i = 0; i < 2; ++i) { // for the second loop, will be TTSW10_GAMEMAP_BITMAP_2_ADDR
        SelectObject(hMemDC, hMemBmp[i]);
        TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(pTBitmap[i]));
        BitBlt(TSW_mBitmap_hDC, 0, 0, 440, 440, hMemDC, 0, 0, SRCCOPY); // switch back the original game map without dmg / cri overlay
        // TODO: BitBlt above only needs to be done when pressing F9 but not when TSW quits
        // Maybe add one parameter `BOOL need_change_back_game_bitmap` for this function and add an `if` judgement here?
        DeleteObject(hMemBmp[i]);
    }
    DeleteObject(hPen_stroke);
    DeleteObject(hPen_polyline);
    DeleteObject(hFont_dmg);
    // TODO: Though unlikely, what if hPen and hFont are still using (selected in a DC)?
    DeleteDC(hMemDC);
}
/*
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
        dmp(TTSW10_TCanvas, TSW_mapLeft, TSW_mapTop, TSW_cur_mBitmap);
}*/
    /*
    HANDLE TSW_mBitmap_1 = get_h(TTSW10_GAMEMAP_BITMAP_1_ADDR);
    HANDLE TSW_mBitmap_2 = get_h(TTSW10_GAMEMAP_BITMAP_2_ADDR);
    HDC TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_mBitmap_1));
    draw_dmg(TTSW10, TSW_mBitmap_hDC);
    TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_mBitmap_2));
    draw_dmg(TTSW10, TSW_mBitmap_hDC);*/
