// It is both more human-readable and more efficient to use `push` than `mov esp...`: https://stackoverflow.com/a/4535996; therefore the following 3 "-m..." options were added while compiling: https://stackoverflow.com/a/24982391
// Likewise, no need to align stack on 16-byte boundaries (because this is not Linux; Windows use 4-byte boundaries instead), so added the 4-th "-m..." option: https://stackoverflow.com/a/43597693/11979352
// Likewise, no need for procedure prolog and epilog (push ebp; mov ebp, esp; ...; leave), so added the following "-f..." option: https://stackoverflow.com/a/21620940/11979352
// You MUST use a 32-bit compiler because only 32-bit DLL can be loaded by 32-bit TSW exe
// gcc -std=gnu99 -Os -s -DNDEBUG -shared -Wl,--enable-auto-image-base,--enable-auto-import -mpush-args -mno-accumulate-outgoing-args -mno-stack-arg-probe -mpreferred-stack-boundary=2 -fomit-frame-pointer dmg.dll.def dmg.dll.c -o dmg.dll

#include "TSW_memory.h"
#define NOINLINE __attribute__((noinline))
#define get_p(p) *(const DWORD *const)(p) // get the DWORD value from the given pointer in memory
#define get_h(p) *(const HANDLE *const)(p) // same as above; but the type is instead HANDLE
#define get_t(p, t) *(const t *const)(p) // same as above; but the type is user-defined `t`

/*
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
*/
const COLORREF *const p_color_OK         = (const COLORREF *const)0x4BA220;
const COLORREF *const p_color_suspicious = (const COLORREF *const)0x4BA224;
const COLORREF *const p_color_no_go      = (const COLORREF *const)0x4BA228;
const COLORREF *const p_color_item       = (const COLORREF *const)0x4BA22C;
const COLORREF *const p_color_polyline   = (const COLORREF *const)0x4BA230;
const COLORREF *const p_color_background = (const COLORREF *const)0x4BA234;
const COLORREF *const p_color_foreground = (const COLORREF *const)0x4BA238;
const LOGFONTA *const p_lfont_dmg        = (const LOGFONTA *const)0x4BA1FC;

const char *const ___gdi32      = (const char *const)0x4BBC5E; // "gdi32.dll"
const char *const ___BeginPath  = (const char *const)0x4BA1DC; // "BeginPath"
const char *const ___EndPath    = (const char *const)0x4BA1E8; // "EndPath"
const char *const ___StrokePath = (const char *const)0x4BA1F0; // "StrokePath"
DWORD *const __BeginPath  = (DWORD *const)0x4BA1D0;
DWORD *const __EndPath    = (DWORD *const)0x4BA1D4;
DWORD *const __StrokePath = (DWORD *const)0x4BA1D8;
typedef _DeleteDC _BeginPath; // they are of same prototype and return type
typedef _DeleteDC _EndPath;
typedef _DeleteDC _StrokePath;
_BeginPath**  p_BeginPath  = (_BeginPath**)__BeginPath;
_EndPath**    p_EndPath    = (_EndPath**)__EndPath;
_StrokePath** p_StrokePath = (_StrokePath**)__StrokePath;

#define DWORD_M_DMG_CRI_ADDR (DWORD *const)0x489C00 // idle memory block from 0x489BA8 till 0x48A000
#define BYTE_DLL_INIT_ADDR (BYTE *const)0x4BA1B5 // idle memory block from 0x4BA1B5 till 0x4BB000
#define BYTE_NEED_UPDATE_ADDR (BYTE *const)0x4BA1B6
#define BYTE_ALWAYS_SHOW_OVERLAY_ADDR (BYTE *const)0x4BA1B7
#define HMEMDC_ADDR (HDC *const)0x4BA1B8
#define HMEMBMP_1_ADDR (HBITMAP *const)0x4BA1BC
#define HMEMBMP_2_ADDR (HBITMAP *const)0x4BA1C0
#define HPEN_STROKE_ADDR (HPEN *const)0x4BA1C4
#define HPEN_POLYLINE_ADDR (HPEN *const)0x4BA1C8
#define HFONT_DMG_ADDR (HFONT *const)0x4BA1CC
UCHAR *const p_prev_i = (UCHAR *const)TTSW10_PREV_I;
CHAR *const p_next_i = (CHAR*)TTSW10_NEXT_I;
DWORD *const p_m_dmg_cri = DWORD_M_DMG_CRI_ADDR; // 121 DWORDs; this stores each tile's damage / critical value of the current floor
BYTE *const p_dll_init = BYTE_DLL_INIT_ADDR;
BYTE *const p_need_update = BYTE_NEED_UPDATE_ADDR; /* the initial value is 1|2
    Bit # (right-to-left) | Meaning
    0 | should update hMemBmp[0] or not
    1 | should update hMemBmp[1] or not
    2 | do not update until all events are over (to prevent TSW's redrawing from erasing our drawing)
    3 | do not show dmg overlay until all events are over (useful when gameover)
    4 | restored original game map bitmaps or not */
BYTE *const p_always_show_overlay = BYTE_ALWAYS_SHOW_OVERLAY_ADDR; // whether to always show dmg overlay, even without OrbOfHero
HDC *const p_hMemDC = HMEMDC_ADDR;
HBITMAP *const p_hMemBmp = HMEMBMP_1_ADDR; // 2 HBITMAPs; 2 game map bitmaps because there are 2 frames
HPEN *const p_hPen_stroke = HPEN_STROKE_ADDR, *p_hPen_polyline = HPEN_POLYLINE_ADDR;
HFONT *const p_hFont_dmg = HFONT_DMG_ADDR;
#define prev_i (*p_prev_i)
#define next_i (*p_next_i)
#define m_dmg_cri p_m_dmg_cri
#define dll_init (*p_dll_init)
#define need_update (*p_need_update)
#define hMemDC (*p_hMemDC)
#define hMemBmp p_hMemBmp
#define hPen_stroke (*p_hPen_stroke)
#define hPen_polyline (*p_hPen_polyline)
#define hFont_dmg (*p_hFont_dmg)

////////// for connectivity polyline function //////////
HBRUSH *const TControl_default_brush = (HBRUSH *const) 0x48A6DC; // assigned as NULL_BRUSH in _Unit8.InitGraphics; will be replaced by DC_BRUSH
BYTE *const p_no_update_bitmap = (BYTE *const)TTSW10_GAMEMAP_NO_UPDATE_BITMAP; // in TSW, this will be set as TRUE during battle or game over, so the player tile will not be redrawn; in tswMP, when drawing polyline, player will not change position, so this will also be set as TRUE
#define no_update_bitmap (*p_no_update_bitmap)

#define DPo 0xFA0089 // dest || pat
#define BYTE_POLYLINE_STATE_ADDR (BYTE *const)0x489DE4 // DWORD m_dmg_cri[121] uses 484 bytes, thus vacant from here
#define BYTE_POLYLINE_COUNT_ADDR (BYTE *const)0x489DE5
BYTE *const p_polyline_state = BYTE_POLYLINE_STATE_ADDR; // 0th bit: need to draw polyline; 1st/2nd bit: have drawn polyline on hMemBmp[0]/hMemBmp[1] or not
BYTE *const p_polyline_count = BYTE_POLYLINE_COUNT_ADDR; // 0-6th bit: up to 63 segments, i.e., 64 vertices; 7th bit: 0=OK(green); 1=suspicious(yellow); 2=no-go(red)
DWORD *const __SetDCBrushColor = (DWORD *const)0x489DEC;
const char *const ___SetDCBrushColor = (const char *const)0x489DF0; // "SetDCBrushColor"
POINT *const p_polyline_vertices = (POINT *const)0x489E00; // up to 64 vertices, will use 64*8=0x200 bytes
#define polyline_state (*p_polyline_state)
#define polyline_count (*p_polyline_count)

typedef _SetTextColor _SetDCBrushColor; // they are of same prototype and return type
_SetDCBrushColor** p_SetDCBrushColor  = (_SetDCBrushColor**)__SetDCBrushColor;

typedef struct {
    INT32 x;
    INT32 y;
    INT32 w;
    INT32 h;
} SQUARE;

NOINLINE static void REGCALL getHighlightSquare(SQUARE* s) {
    const HANDLE TTSW10 = get_h(TTSW10_ADDR);
    const DWORD TSW_tileSize = get_p(get_p((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
    s->w = TSW_tileSize;
    s->h = TSW_tileSize;
    const POINT xy_center = p_polyline_vertices[0];
    const DWORD TSW_h_tileSize = TSW_tileSize >> 1;
    s->x = xy_center.x - TSW_h_tileSize;
    s->y = xy_center.y - TSW_h_tileSize;
}

NOINLINE static void REGCALL drawPolylineOnDC(const HDC hDC) { // draw only polyline
    UCHAR seg_count = polyline_count & 0x3F; // 0-63; this is the number of line segments; +1 = the number of vertices
    if (!seg_count)
        return;
    SetROP2(hDC, R2_XORPEN);
    const HPEN hPen_old = SelectObject(hDC, hPen_polyline);
    Polyline(hDC, p_polyline_vertices, seg_count+1);
    SelectObject(hDC, hPen_old);
}

NOINLINE static void REGCALL drawConnectivityOnDC(const HDC hDC) { // draw polyline and highlight destination tile
    const UCHAR dest_type = polyline_count >> 6; // 0/1/2 = OK/suspicious/no-go
    (*p_SetDCBrushColor)(hDC, p_color_OK[dest_type]);
    SQUARE s; getHighlightSquare(&s);
    const HBRUSH hBr_old = SelectObject(hDC, *TControl_default_brush);
    PatBlt(hDC, s.x, s.y, s.w, s.h, DPo);
    SelectObject(hDC, hBr_old);
    drawPolylineOnDC(hDC);
}

NOINLINE static HDC REGCALL drawConnectivityOnBitmap(const HANDLE TSW_cur_mBitmap) { // draw polyline and highlight on TTSW10_GAMEMAP_BITMAP_i
    const BYTE TSW_cur_frame = (BYTE)get_p(TTSW10_GAMEMAP_FRAME_ADDR);
    const BYTE test_bit = (TSW_cur_frame + 1 << 1); // (i+1)-th (i=0/1) bit
    const HDC TSW_cur_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_cur_mBitmap));
    if ((polyline_state & test_bit)) // (i+1)-th (i=0/1) bit already set
        return TSW_cur_mBitmap_hDC;

    if (!(polyline_state & 6)) { // both 1st and 2nd bit not set
        const DWORD TSW_mapLeft = get_p(TTSW10_GAMEMAP_LEFT_ADDR), TSW_mapTop = get_p(TTSW10_GAMEMAP_TOP_ADDR);
        UCHAR seg_count = polyline_count & 0x3F;
        for (UCHAR i = 0; i <= seg_count; ++i) { // for form canvas, the origin is (TSW_mapLeft, TSW_mapTop); for bitmap, the origin is (0, 0), so coordinates should be recalculated
            p_polyline_vertices[i].x -= TSW_mapLeft;
            p_polyline_vertices[i].y -= TSW_mapTop;
        }
    }
    polyline_state |= test_bit;

    SQUARE s; getHighlightSquare(&s);
    SelectObject(hMemDC, hMemBmp[TSW_cur_frame]);
    BitBlt(hMemDC, 0, 440, s.w, s.h, TSW_cur_mBitmap_hDC, s.x, s.y, SRCCOPY); // backup the tile cell that will be highlighted at (0, 440), which is definitely outside the map area
    drawConnectivityOnDC(TSW_cur_mBitmap_hDC);
    return TSW_cur_mBitmap_hDC;
}

extern void REGCALL dpl(HANDLE TTSW10) { // draw polyline
    no_update_bitmap = TRUE;
    polyline_state = 1;
    const HANDLE TTSW10_TCanvas = get_h((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    const HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    drawConnectivityOnDC(TTSW10_TCanvas_hDC);
}

extern void REGCALL epl(HANDLE TTSW10) { // erase polyline
    const HANDLE TTSW10_TCanvas = get_h((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    const DWORD TSW_tileSize = get_p(get_p((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
    const HANDLE *const pTBitmap = (const HANDLE *const)TTSW10_GAMEMAP_BITMAP_1_ADDR;
    const HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    const BYTE TSW_cur_frame = (BYTE)get_p(TTSW10_GAMEMAP_FRAME_ADDR);
    for (int i = 0; i < 2; ++i) {
        const HDC TSW_cur_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(pTBitmap[i]));
        const BYTE test_bit = (TSW_cur_frame + 1 << 1); // (i+1)-th (i=0/1) bit
        if (polyline_state & test_bit) { // (i+1)-th (i=0/1) bit set
            drawPolylineOnDC(TSW_cur_mBitmap_hDC); // xor twice = eliminate the polyline

            SQUARE s; getHighlightSquare(&s);
            SelectObject(hMemDC, hMemBmp[i]);
            BitBlt(TSW_cur_mBitmap_hDC, s.x, s.y, s.w, s.h, hMemDC, 0, 440, SRCCOPY); // restore the tile cell without highlight
        }
        if (i == TSW_cur_frame)
            BitBlt(TTSW10_TCanvas_hDC, get_p(TTSW10_GAMEMAP_LEFT_ADDR), get_p(TTSW10_GAMEMAP_TOP_ADDR), TSW_tileSize*11u, TSW_tileSize*11u, TSW_cur_mBitmap_hDC, 0, 0, SRCCOPY); // redraw TSW game window canvas without polyline or highlight
    }
    no_update_bitmap = FALSE;
    polyline_state = 0;
}

/* Demo usage for drawing polyline: F1=draw; F9=erase
   This will highlight (1,1) tile on map and draw an L-shape polyline
489DE5:
db 42 // (1<<6)|2, meaning using yellow highlight color and have 2 polyline segments
489DF0:
db 'SetDCBrushColor', 0
489E00:
dd #240, #90 // mapLeft=180; mapTop=30;
dd #240, #130 // tileSize=40;
dd #270, #130 // central point coordinates for (1,1)--(1,2)--(2,2)

47D2D8: // F1
jmp dmg.dpl
463874: // F9
jmp dmg.epl
*/
////////// ---------------------------------- //////////
/*
#define msgboxDWORD10(h,i) msgboxDWORD(h,i,10) // use 10-base
NOINLINE static void REGCALL msgboxDWORD(const HANDLE TTSW10, const DWORD i, const int base) { // for debug use; show value of int `i`
    const HWND TTSW10_hWnd = get_t((DWORD)TTSW10+TCONTROL_HWND_OFFSET, HWND);
    char st[10];
    itoa(i, st, base);
    MessageBoxA(TTSW10_hWnd, st, "Debug Output", MB_ICONINFORMATION | MB_SETFOREGROUND);
}
*/

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
NOINLINE static DWORD REGCALL getMonsterDmgCri(const UCHAR monsterID, const BOOL isStrikeFirst) { // HIWORD=cri (0-32766; 0x7FFF=no show); LOWORD=dmg (0-65534; 0xFFFF=???); if the most significant bit is 1 (i.e., cri < 0), it means that the dmg is greater or equal to hero's HP
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
                UINT tmp = (mHP-1) / turnsCount + mDEF;
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

NOINLINE static void restoreGameBitmaps(void) {
    const HANDLE *const pTBitmap = (const HANDLE *const)TTSW10_GAMEMAP_BITMAP_1_ADDR;
    HDC TSW_mBitmap_hDC;
    for (int i = 0; i < 2; ++i) { // for the second loop, will be TTSW10_GAMEMAP_BITMAP_2_ADDR
        SelectObject(hMemDC, hMemBmp[i]);
        TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(pTBitmap[i]));
        BitBlt(TSW_mBitmap_hDC, 0, 0, 440, 440, hMemDC, 0, 0, SRCCOPY); // switch back the original game map without dmg / cri overlay
    }
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
                const UCHAR ix = i % 11u, iy = i / 11u;
                char adjacent[4] = {0};
                // need to rule out situations where player is on the map edge: there will not be a magician outside the map (set the corresponding adjacent[i] to zero, meaning Green Slime (not a magician anyway))
                if (ix != 0)
                    adjacent[0] = getMonsterID(TSW_curFloor_tiles[i -  1]);
                if (ix !=10)
                    adjacent[1] = getMonsterID(TSW_curFloor_tiles[i +  1]);
                if (iy != 0)
                    adjacent[2] = getMonsterID(TSW_curFloor_tiles[i - 11]);
                if (iy !=10)
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
                if (TSW_curFloor_tiles[60] != 7 && i < 44 && (int)get_p(TTSW10_EVENT_COUNT_ADDR) > 0) // 49F boss battle (trap triggered; monsters in the boss room)
                    continue; // if the event is still ongoing, then do not consider refreshing the monster damage yet; otherwise it will be erased by TSW's redrawing later
            } else if (floor == 20) {
                if (TSW_curFloor_tiles[82] != 7 && mID == 17 && (int)get_p(TTSW10_EVENT_COUNT_ADDR) > 0) // 20F boss battle (trap triggered; Vampire)
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

extern void REGCALL dtl(const HDC hDC, const char i, const DWORD xy) { // draw the damage / critical value for a specific tile `i` at a given `xy` coordinate (with (x, y) being the bottom left corner of the current tile cell)
    DWORD x = (DWORD)LOWORD(xy), y = (DWORD)HIWORD(xy);
    const BOOL bypassSelectObject = i >> 7; // most significant bit; the main purpose of this check is to avoid redundant SelectObject calls when `sub_dtl` is called in a loop, e.g., in `sub_dmp` (for i in range(0, 121)), but in that case, there should be extra SelectObject calls that wrap around the for loop
    const DWORD dmgCri = m_dmg_cri[i & 0x7F];
    const WORD dmg = LOWORD(dmgCri), cri=HIWORD(dmgCri) & 0x7FFF;
    HPEN hPen_old; HFONT hFont_old;
    char strInt_1[8]; int lenInt_1;
    char strInt_2[8]; int lenInt_2;

    if (dmgCri == (DWORD)(-2)) // no draw
        return;
    if (!bypassSelectObject) {
        SetBkMode(hDC, TRANSPARENT);
        hPen_old = SelectObject(hDC, hPen_stroke);
        hFont_old = SelectObject(hDC, hFont_dmg);
    }
    if ((INT32)dmgCri < 0) { // most significant bit set; inadequate HP
        SetTextColor(hDC, *p_color_no_go);
        SetROP2(hDC, R2_WHITE);
    }
    else {
        SetTextColor(hDC, *p_color_foreground);
        SetROP2(hDC, R2_COPYPEN);
    }
    (*p_BeginPath)(hDC);
    lenInt_1 = itoa2(dmg, strInt_1);
    if (cri) { // for normal monsters, draw dmg (and cri, if applicable) at bottom left of cell
        ++x; y -= 15; // this is the top left corner of the drawing rect
        TextOutA(hDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF) {
            lenInt_2 = itoa2(cri, strInt_2);
            TextOutA(hDC, x, y-12, strInt_2, lenInt_2);
        }
        (*p_EndPath)(hDC);
        (*p_StrokePath)(hDC);
        TextOutA(hDC, x, y, strInt_1, lenInt_1);
        if (cri != 0x7FFF)
            TextOutA(hDC, x, y-12, strInt_2, lenInt_2);
    } else { // cri == 0 means it is magical attack
        const HANDLE TTSW10 = get_h(TTSW10_ADDR);
        const DWORD TSW_tileSize = get_p(get_p((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
        RECT cell = {x, y-TSW_tileSize, x+TSW_tileSize, y}; // current cell bounds
        DrawTextA(hDC, strInt_1, lenInt_1, &cell, DT_CENTER | DT_VCENTER | DT_SINGLELINE); // only draw dmg in the middle of cell
        (*p_EndPath)(hDC);
        (*p_StrokePath)(hDC);
        DrawTextA(hDC, strInt_1, lenInt_1, &cell, DT_CENTER | DT_VCENTER | DT_SINGLELINE); // only draw dmg in the middle of cell
    }
    if (!bypassSelectObject) {
        SelectObject(hDC, hPen_old);
        SelectObject(hDC, hFont_old);
    }
}

extern void REGCALL dmp(const HANDLE TTSW10_TCanvas, const DWORD TSW_mapLeft, const DWORD TSW_mapTop, const HANDLE TSW_cur_mBitmap) { // draw the damage / critical value for the current whole map
    const HANDLE TTSW10 = get_h((DWORD)TTSW10_TCanvas+TCANVAS_TCONTROL_OFFSET); // instead of using `get_h(TTSW10_ADDR)`; saved 2-3 bytes
    const UCHAR TSW_tileSize = (UCHAR)get_p(get_p((DWORD)TTSW10+TTSW10_IMAGE6_OFFSET)+TCONTROL_WIDTH_OFFSET);
    const DWORD TSW_mapSize = 11u * TSW_tileSize;
    const BYTE TSW_cur_frame = (BYTE)get_p(TTSW10_GAMEMAP_FRAME_ADDR);
    HDC TSW_mBitmap_hDC;

    ////////// for connectivity polyline function //////////
    if (polyline_state) {
        TSW_mBitmap_hDC = drawConnectivityOnBitmap(TSW_cur_mBitmap);
        goto draw;
    }
    ////////// ---------------------------------- //////////

    TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_cur_mBitmap));
    if (!(*p_always_show_overlay) && (((ITEM*)TTSW10_HERO_ITEM_ADDR)->orbHero != 1)) // unless (*p_always_show_overlay) is set, show no overlay if without OrbOfHero
        goto no_overlay;
    if (need_update & 8) { // if 3rd bit is set, show no overlay until event is over
        if ((int)get_p(TTSW10_EVENT_COUNT_ADDR) > 0) {
no_overlay:
            if (!(need_update & 16)) { // if 4th bit is not set, restore original game map bitmaps
                restoreGameBitmaps();
                need_update |= (16|3); // once this no_overlay status is cleared, need to update dmg overlay anyways
            }
            goto draw;
        } else
            need_update &= (BYTE)(~(8|4));
    }

    if (need_update & 4) { // if 2nd bit is set, do not update until event is over
        if ((int)get_p(TTSW10_EVENT_COUNT_ADDR) > 0)
            goto draw;
        else
            need_update &= (BYTE)(~4);
    }

    cmp();
    if (need_update & (TSW_cur_frame+1)) { // `TSW_cur_frame`: i=0, 1; if i-th bit (right-to-left) is set
        need_update &= (2-TSW_cur_frame); // `TSW_cur_frame`: i=0, 1; set i-th bit (right-to-left) to be 0; discard 2nd, 3rd, and 4th bits

        SelectObject(hMemDC, hMemBmp[TSW_cur_frame]);
        BitBlt(TSW_mBitmap_hDC, 0, 0, TSW_mapSize, TSW_mapSize, hMemDC, 0, 0, SRCCOPY);

        HPEN hPen_old; HFONT hFont_old;
        SetBkMode(TSW_mBitmap_hDC, TRANSPARENT); // save unnecessary SelectObject calls by moving them outside the loop
        hPen_old = SelectObject(TSW_mBitmap_hDC, hPen_stroke);
        hFont_old = SelectObject(TSW_mBitmap_hDC, hFont_dmg);
        for (UCHAR i = 0; i < 121; ++i) {
            WORD x = i % 11u * TSW_tileSize;
            WORD y = (i / 11u + 1) * TSW_tileSize;
            dtl(TSW_mBitmap_hDC, i|0x80, MAKELONG(x, y)); // i|0x80: indicate that no need to call SelectObject in `dtl`; see comments above
        }
        SelectObject(TSW_mBitmap_hDC, hPen_old); // put back old Pen and Font objects after the loop is done; see comments above
        SelectObject(TSW_mBitmap_hDC, hFont_old);
    } else if ((int)get_p(TTSW10_EVENT_COUNT_ADDR) <= 0) { // even if the map dmg/cri values haven't changed, it is possible that the drawings will be erased by TSW's redrawing, in which case dmg/cri should be redrawn (should wait until the end of event (animation might redraw the tile and erase our drawing))
        const STATUS TSW_hero_status = get_t(TTSW10_HERO_STATUS_ADDR, STATUS);
        const UCHAR cur_ix = TSW_hero_status.x, cur_iy = TSW_hero_status.y, cur_i = cur_ix + cur_iy*11;
        { // firstly, check the player's current location
            WORD x = cur_ix*TSW_tileSize, y = (cur_iy+1)*TSW_tileSize;
            dtl(TSW_mBitmap_hDC, cur_i, MAKELONG(x, y));
        }

        HANDLE TSW_nxt_mBitmap = get_h(TTSW10_GAMEMAP_BITMAP_1_ADDR);
        if (TSW_nxt_mBitmap == TSW_cur_mBitmap)
            TSW_nxt_mBitmap = get_h(TTSW10_GAMEMAP_BITMAP_2_ADDR);
        const HDC TSW_mBitmap2_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(TSW_nxt_mBitmap)); // need to draw another frame as well
        if (prev_i >= 121)
            prev_i = cur_i; // this is unlikely, but rectify this error
        else if (prev_i != cur_i) { // if the player has changed location (either via walking or WarpWing), check player's previous location
            WORD x = prev_i % 11u * TSW_tileSize;
            WORD y = (prev_i / 11u + 1) * TSW_tileSize;
            DWORD xy = MAKELONG(x, y);
            dtl(TSW_mBitmap_hDC, prev_i, xy);
            dtl(TSW_mBitmap2_hDC, prev_i, xy);
            prev_i = cur_i;
        }

        // Finally, check player's next location. In most cases, this won't be triggered, because if player meets an event (monster/item/etc) then player walks to that tile immediately, without the chance of refreshing the game bitmap during this process. The only exception is door opening: Player will not immediately move over after the door opens
        if ((UCHAR)next_i >= 121)
            next_i = cur_i; // this is possible: if the player is on the map edge, TSW will assign a `next_i` will be outside the range of [0,121); rectify this error
        else if ((cur_i - next_i == 1 && cur_ix != 0) || // you won't be able to move left if you are on the left edge of the map
            (next_i - cur_i == 1 && cur_ix !=10) || // you won't be able to move right if you are on the right edge of the map
            (cur_i - next_i ==11) || // for the rest 2 conditions, no need to compare `cur_iy`
            (next_i - cur_i ==11)) { // since those conditions have already been ruled out earlier ((UCHAR)next_i >= 121)
            const UCHAR floor = (const UCHAR)TSW_hero_status.floor;
            const WORD offset = 123u*floor + 2u;
            const char *const TSW_curFloor_tiles = (const char *const)TTSW10_MAP_STATUS_ADDR+offset;
            if (TSW_curFloor_tiles[next_i] != 6)
                goto draw;
            // the door has opened (become road) and the animation is over
            WORD x = (UCHAR)next_i % 11u * TSW_tileSize;
            WORD y = ((UCHAR)next_i / 11u + 1) * TSW_tileSize;
            DWORD xy = MAKELONG(x, y);
            dtl(TSW_mBitmap_hDC, next_i, xy);
            dtl(TSW_mBitmap2_hDC, next_i, xy);
            next_i = cur_i;
        }
    }

draw:
    const HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    BitBlt(TTSW10_TCanvas_hDC, get_p(TTSW10_GAMEMAP_LEFT_ADDR), get_p(TTSW10_GAMEMAP_TOP_ADDR), TSW_mapSize, TSW_mapSize, TSW_mBitmap_hDC, 0, 0, SRCCOPY); // instead of using TSW_mapLeft / TSW_mapTop in argv; no need to push on stack
}

extern void REGCALL ini(HANDLE TTSW10) { // initialize
    LOGPEN lpen = {PS_SOLID, {3, 0}, *p_color_background};
    hPen_stroke = CreatePenIndirect(&lpen);
    lpen.lopnColor = *p_color_polyline;
    hPen_polyline = CreatePenIndirect(&lpen);
    hFont_dmg = CreateFontIndirectA(p_lfont_dmg);

    HMODULE hgdi32 = GetModuleHandleA(___gdi32);
    *__BeginPath  = (DWORD)GetProcAddress(hgdi32, ___BeginPath);
    *__EndPath    = (DWORD)GetProcAddress(hgdi32, ___EndPath);
    *__StrokePath = (DWORD)GetProcAddress(hgdi32, ___StrokePath);

    ////////// for connectivity polyline function //////////
    *TControl_default_brush = GetStockObject(DC_BRUSH);
    *__SetDCBrushColor = (DWORD)GetProcAddress(hgdi32, ___SetDCBrushColor);
    ////////// ---------------------------------- //////////

    const HANDLE TTSW10_TCanvas = get_h((DWORD)TTSW10+TFORM_TCANVAS_OFFSET);
    const HDC TTSW10_TCanvas_hDC = TCanvas_GetHandle(TTSW10_TCanvas);
    hMemDC = CreateCompatibleDC(TTSW10_TCanvas_hDC);
    const HANDLE *const pTBitmap = (const HANDLE *const)TTSW10_GAMEMAP_BITMAP_1_ADDR;
    HDC TSW_mBitmap_hDC;
    for (int i = 0; i < 2; ++i) { // for the second loop, will be TTSW10_GAMEMAP_BITMAP_2_ADDR
        hMemBmp[i] = CreateCompatibleBitmap(TTSW10_TCanvas_hDC, 440, 480); // the extra 40 pixels in height can be useful to store some temp image
        SelectObject(hMemDC, hMemBmp[i]);
        TSW_mBitmap_hDC = TCanvas_GetHandle(TBitmap_GetCanvas(pTBitmap[i]));
        BitBlt(hMemDC, 0, 0, 440, 440, TSW_mBitmap_hDC, 0, 0, SRCCOPY);
    }
    need_update |= 3; // always update upon init; do not show if without OrbOfHero
    dll_init = TRUE;
}

extern void fin(void) { // finalize
    if (!dll_init)
        return;

    dll_init = FALSE;
    restoreGameBitmaps();
    // TODO: BitBlt above only needs to be done when pressing F9 but not when TSW quits

    HBITMAP hStkBmp = CreateCompatibleBitmap(hMemDC, 0, 0); // this retrieves the 1x1 monochromic "stock bitmap" (see https://devblogs.microsoft.com/oldnewthing/20100416-00/?p=14313)
    // equivalently, one can call GetStockObject(PRIV_STOCK_BITMAP) (PRIV_STOCK_BITMAP is a private constant with a value of 19 since Windows 2000), typically =0x85000F
    // equivalently, one can get it from TBitmap, e.g., [48C514], by [TBitmapCanvas+0x38], where TBitmapCanvas=[TBitmap+0x14] (or call 41DAD8) (see TBitmapCanvas.CreateHandle or TBitmapCanvas.FreeContext)
    SelectObject(hMemDC, hStkBmp); // put back the original monochromic 1x1 "stock bitmap"
    // although this is unnecessary as discussed here (see https://github.com/users/Z-H-Sun/projects/2?pane=issue&itemId=55490542), but just to be cautious

    DeleteObject(hMemBmp[0]);
    DeleteObject(hMemBmp[1]);
    DeleteObject(hPen_stroke);
    DeleteObject(hPen_polyline);
    DeleteObject(hFont_dmg);
    DeleteDC(hMemDC);
}
