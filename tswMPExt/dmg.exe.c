// gcc -mwindows -std=gnu99 -Os -s -DNDEBUG dmg.exe.c -o dmg.exe

#include "patch.h"
const PATCH patches[] = { /*
4012B0:
  Kernel32_GetModuleHandleA:
404B24:
  Kernel32_FreeLibrary:
404BFC:
  Kernel32_LoadLibraryA:
404B84:
  Kernel32_GetProcAddress:
404C5C:
  Gdi32_BitBlt:
404DCC:
  Gdi32_SelectObject:
40EC98:
  Comctl32_ImageList_DrawEx:

489B1F:
  TTSW10_SPIRAL_I_SEQUENCE:
48C514:
  TTSW10_GAMEMAP_BITMAP_1_ADDR:
48C518:
  TTSW10_GAMEMAP_BITMAP_2_ADDR:
48C51C:
  TTSW10_TEMP_BITMAP_1_ADDR:
48C54C:
  TTSW10_TEMP_x_1_ADDR:
48C550:
  TTSW10_TEMP_y_1_ADDR:
48C554:
  TTSW10_TEMP_i_1_ADDR:
48C558:
  TTSW10_TEMP_i_2_ADDR:
48C55C:
  TTSW10_TEMP_x_2_ADDR:
48C568:
  TTSW10_TEMP_x_3_ADDR:
48C570:
  TTSW10_TEMP_j_1_ADDR:
48C5AC:
  TTSW10_EVENT_COUNT_ADDR:
4B8698:
  TTSW10_HERO_FLOOR_ADDR:
4B86A0:
  TTSW10_HERO_x_ADDR:
4B86CC:
  TTSW10_HERO_ORB_OF_HERO_ADDR:
4B8934:
  TTSW10_MAP_TILE_ID_ADDR:

402C34:
  TObject_Free:
417E44:
  TCustomImageList_Draw:
41A5B8:
  TCanvas_Draw:
41A950:
  TCanvas_GetHandle:
41DAD8:
  TBitmap_GetCanvas:
4433A4:
  TTSW10_yusyaidou1:
480A90:
  TTSW10_monidouwork:

489C00:
  m_dmg_cri: // dword[121]
4BA1B5:
  DLL_IsInit: // byte
  db 0
4BA1B6:
  need_update: // byte
  db 3
4BA1B7:
  always_show_overlay: // byte
  db 0
4BA1B8:
  hMemDC:
4BA1BC:
  hMemBmp_1:
4BA1C0:
  hMemBmp_2:
4BA1C4:
  hPen_stroke:
4BA1C8:
  hPen_polyline:
4BA1CC:
  hFont_dmg:

4BA1D0:
  Gdi32_BeginPath:
4BA1D4:
  Gdi32_EndPath:
4BA1D8:
  Gdi32_StrokePath:

4BBC5E:
str_gdi32: // gdi32.dll
4BA1DC:
str_BeginPath:
  db 'BeginPath', 0
align 04
str_EndPath:
  db 'EndPath', 0
str_StrokePath:
  db 'StrokePath', 0
align 04

4BA1FC:
struct_damage_font:
  dd #16, 6, 0, 0, #700 // height, width, esc, orient, weight
  db 0, 0, 0, 0, 0, 0, 3, 0 // italic, underline, strike, charset, out, clip, quality, pitch
  db 'Tahoma', 0 // name
align 10

4BA220:
color_OK:
  db 22, AA, 22, 00
color_suspicious:
  db C0, A0, 60, 00
color_no_go:
  db FF, 22, 22, 00
color_item:
  db 40, 7F, C0, 00
color_polyline:
  db 88, 99, 88, 00
color_background:
  db 66, 66, 66, 00
color_foreground:
  db FF, FF, FF, 00

4BA23C:
  DLL_cmp_addr:
4BA240:
  DLL_dtl_addr:
4BA244:
  DLL_dmp_addr:
4BA248:
// future functions start here...

47D2D8:
TTSW10_Help2Click: // F1
  cmp byte ptr [DLL_IsInit], 0
  jne 47D2D6 // ret
  push eax // store TTSW10 handle
  push DLL_str
  call Kernel32_LoadLibraryA
  push DLL_ini_str
  push eax
  push DLL_cmp_str
  push eax
  jmp 4638B0 // we run out of space here, will continue somewhere else
  db 90,90,90
  47D300:
  DLL_str:
  db 'dmg',0
  DLL_ini_str:
  db 'ini',0
  DLL_fin_str:
  db 'fin',0
  DLL_cmp_str:
  db 'cmp',0
  DLL_dtl_str:
  db 'dtl',0
  DLL_dmp_str:
  db 'dmp',0
  4638B0: // part of TTSW10_GameQuit1Click; see below
  push DLL_dtl_str
  push eax
  push DLL_dmp_str
  push eax
  call Kernel32_GetProcAddress
  mov [DLL_dmp_addr], eax
  call Kernel32_GetProcAddress
  mov [DLL_dtl_addr], eax
  call Kernel32_GetProcAddress
  mov [DLL_cmp_addr], eax
  call Kernel32_GetProcAddress
  mov ecx, eax // dmg.ini
  pop eax // retrieve TTSW10 handle
  call ecx
  ret

463874:
TTSW10_GameQuit1Click: // F9
  cmp byte ptr [DLL_IsInit], 0
  je +1D // ret
  push DLL_str
  call Kernel32_GetModuleHandleA
  push eax
  push DLL_fin_str
  push eax
  call Kernel32_GetProcAddress
  call eax
  call Kernel32_FreeLibrary
  ret
  db 90,90,90,90,90,90,90,90,90,90,90,90,90
  4638A8: // this is within TTSW10_GameQuit1Click (won't be executed anymore, but patch it anyway)
  pop ebx
  jmp TTSW10_TSW10close
  xchg ax, ax // 2-byte nop
  4638B0: // the vacant space below has been used for initialization (see above)
  // ...

463933: // part of TTSW10_Exit1Click
  jmp TTSW10_TSW10close

484B14:
TTSW10_TSW10close:
  call TTSW10_GameQuit1Click // free dmg drawing-related GDI obj
  mov ebx, TTSW10_GAMEMAP_BITMAP_1_ADDR // TTSW10_GAMEMAP_BITMAP_1_ADDR
  mov eax, [ebx]
  call TObject_Free
  mov eax, [ebx+04] // TTSW10_GAMEMAP_BITMAP_2_ADDR
  call TObject_Free
  mov eax, [ebx+08] // TTSW10_TEMP_BITMAP_1_ADDR (used in TTSW10_idou/monidou)
  call TObject_Free
  mov eax, [ebx+0C] // TTSW10_TEMP_BITMAP_2_ADDR
  call TObject_Free
  mov eax, [ebx+10] // TTSW10_TEMP_BITMAP_3_ADDR (all three used in TTSW10_kasanegaki)
  call TObject_Free
  nop


//////////////////// Handle Routine Dmg Overlay ////////////////////
44314D: // part of TTSW10_Timer1Timer
  call sub_draw_map
443275:
  call sub_draw_map

41A5C6: // part of TCanvas_Draw
  call sub_backup_tile_TCanvas_Draw
417EA7: // part of TCustomImageList_Draw
  call sub_backup_tile_TCustomImageList_Draw

480838: // saved space from TTSW10_monidou (see "Handle Dmg Overlay of Moving Monters")
sub_draw_map:
  cmp byte ptr [DLL_IsInit], 0
  je TCanvas_Draw
  jmp [DLL_dmp_addr]
  nop

sub_backup_tile_TCanvas_Draw:
  mov ebx, eax // TCanvas (dest)
  mov esi, [ebp+8] // TBitmap (src)

  xor edx, edx // now edx=0
  cmp byte ptr [DLL_IsInit], dl
  je +54 // loc_backup_tile_TCanvas_Draw_fin

  mov ecx, hMemBmp_1
  mov eax, [eax+34] // corresponding TBitmap of TBitmapCanvas (dest)
  cmp eax, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
  je +0B // loc_backup_tile_TCanvas_Draw_work

  cmp eax, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
  jne +3C // loc_backup_tile_TCanvas_Draw_fin
  add ecx, 4 // hMemBmp_2

  loc_backup_tile_TCanvas_Draw_work:
  push CC0020 // rop: SRCCOPY
  push edx // y1: 0
  push edx // x1: 0

  push [ecx] // HGDIOBJ h
  push [hMemDC] // HDC hdc
  call Gdi32_SelectObject

  mov eax, esi // TBitmap (src)
  call TBitmap_GetCanvas
  call TCanvas_GetHandle
  push eax // hdcSrc
  mov eax, [esi+10] // see TBitmap_GetWidth and TBitmap_GetHeight
  push [eax+18] // cy: height of TBitmap (src)
  push [eax+14] // cx: width of TBitmap (src)
  push [ebp-4] // y: top of TCanvas (dest) to draw
  push edi // x: left of TCanvas (dest) to draw
  push [hMemDC] // hdc

  call Gdi32_BitBlt
  loc_backup_tile_TCanvas_Draw_fin:
  ret

sub_backup_tile_TCustomImageList_Draw:
  xor edx, edx // now edx=0
  cmp byte ptr [DLL_IsInit], dl
  je +41 // loc_backup_tile_TCustomImageList_Draw_fin

  mov ecx, hMemBmp_1
  mov esi, [esi+34] // corresponding TBitmap of TBitmapCanvas (dest) [its himl is already saved in eax; esi is now idle]
  cmp esi, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
  je +0B // loc_backup_tile_TCustomImageList_Draw_work

  cmp esi, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
  jne +29 // loc_backup_tile_TCustomImageList_Draw_fin
  add ecx, 4 // hMemBmp_2

  loc_backup_tile_TCustomImageList_Draw_work:
  push edx // fStyle: 0
  push -1 // rgbFg: CLR_NONE
  push edx // rgbBk: 0
  push edx // dy: 0 (full size)
  push edx // dx: 0 (full size)
  push [ebp+C] // y (from argv)
  push edi // x (from argv)
  push [hMemDC] // hdc
  push [ebp+8] // i (from argv)
  push eax // himl (from argv (processed in earlier codes in TCustomImageList_Draw))

  push [ecx] // HGDIOBJ h
  push [hMemDC] // HDC hdc
  call Gdi32_SelectObject

  call Comctl32_ImageList_DrawEx
  loc_backup_tile_TCustomImageList_Draw_fin:
  jmp Comctl32_ImageList_DrawEx


//////////////////// Handle Dmg Redrawing upon Events ////////////////////
442C4A: // part of TTSW10_mhyouji; need to `or byte ptr [need_update], 3` (refresh map dmg display)
  inc eax // eax was 0
  mov esi, eax // saved 2 bytes w.r.t. `mov esi, 00000001`
  jmp +2 // execute `or byte ptr [need_update], 3`

  loc_TTSW10_mhyouji_loop:
  jmp +7 // bypass `or byte ptr [need_update], 3`
  or byte ptr [need_update], 3
// save some space by rewrting the coordinate calculation code below
  mov [edi], esi
  mov eax, esi
  mov al, [TTSW10_SPIRAL_I_SEQUENCE+eax] // this returns the actual i (=ix+11*iy) of the current index (=esi) in a spiral sequence (although I don't think is useful in this function because everytile is refreshed all at once without any pause)
  mov cl, 0B
  div cl // al=iy; ah=ix
  mov edx, [ebx+0254] // TTSW10.Image6
  mov ecx, [edx+2C] // tile size
  mov ch, ah // store ix
  mul cl // iy*tile_size
  mov [TTSW10_TEMP_y_1_ADDR], eax
  push eax
  mov al, ch // retrieve ix
  mul cl // iy*tile_size
  mov [TTSW10_TEMP_x_1_ADDR], eax // x
  jmp 442C99 // now enough space has been saved to insert our code (`or byte ptr [need_update], 3`)

450BE7: // part of TTSW10_Button38Click; use item; need to `or byte ptr [need_update], 4` (defer dmg drawing update; otherwise the drawing might be erased by TSW's redrawing)
  or byte ptr [need_update], 4
  xchg ax, ax
451939: // 13=MagicKey; always need to update dmg overlay even if no dmgCri value is changed (because the magic attack dmg on some doors might be erased after it turns into road)
  mov [eax*2+48C74E], 0
  or byte ptr [need_update], 3
  xchg ax, ax

44A54A: // part of TTSW10_taisen; need to `or byte ptr [need_update], 4` (defer dmg drawing update; no need to refresh map dmg during battle)
  mov edx, TTSW10_TEMP_i_1_ADDR // difference of tile index b/w the 2nd and 1st frame (usually 1, but not for Dragon or Octopus)
  mov eax, [edx]
  sub eax, 00C6 // don't know what's the doing here, but we can save a bit space here to insert our code, `or byte ptr [need_update], 4`
  mov [edx+08], eax // 48C55C
  mov [edx+64], eax // 48C5B8
  or byte ptr [need_update], 4

449E66: // part of TTSW10_zyouout (gameover when [48C5A4]==9); need to `or byte ptr [need_update], 8` (hide dmg display)
  xor ebx, ebx
  mov dword ptr [edx+ecx*2], ebx
  or byte ptr [need_update], 8
  nop


//////////////////// Handle Dmg Overlay When Moving on Stairs ////////////////////
442F1D:	// part of TTSW10_kaidanwork
	push 442F61	// the address to return to when the second `ret` is executed below
	// the original code sets the Timer2 interval to 2ms/6ms/10ms for high/middle/low-speed modes for showing stair animation; however, the theoretical minimal interval supported by the Windows `SetTimer` API is 10ms, so there is no use setting the interval less than 10ms. Therefore, the useless code can be skipped and can directly jump to the part where the timer interval is set to 10ms
	push [DLL_cmp_addr]	// the address to return to when the first `ret` is executed below
	// need to update map damage calculation before drawing
	// will continue to execute `sub_check_need_overlay` below
442F28:
sub_check_need_overlay:	// when `tswMP_overlay_enabled`, `ret` to continue normal operation either if `always_show_overlay` or `TTSW10_HERO_ORB_OF_HERO_ADDR`; otherwise, stop the current caller function and `ret` to caller's caller
	cmp byte ptr [DLL_IsInit], 0
	je +14	// loc_check_need_overlay_false
	cmp byte ptr [always_show_overlay], 0
  js +0B	// loc_check_need_overlay_false
	jne +0C	// loc_check_need_overlay_true
	cmp byte ptr [TTSW10_HERO_ORB_OF_HERO_ADDR], 1
	je +03	// loc_check_need_overlay_true

	loc_check_need_overlay_false:	// `ret` to caller's caller (stop the current caller function)
	add esp, 4	// pop the return address; do not execute the remaining commands in the caller function and jump back to caller's caller

	loc_check_need_overlay_true:	// `ret` to caller function (continue normal operation)
	ret


// everything below is part of TTSW10_stackwork where an event sequence like (21, 1, j) is processed; for more details on the event sequence, see tswBGM.asm
// (21, 0, j) shows the j-th "sword-and-staff" tile; (21, 1, j) hides that "sword-and-staff" tile and shows the actual tile on the next map; since the tile shows/hides in a spiral sequence, the actual map index `i` is different from `j` and is obtained by ((*byte*)0x489B1F)[j]
45458F: // below, the j-th tile is drawn onto the screen; and if the tile happens to be the player's current location, call `TTSW10_yusyaidou1`
  push loc_stackwork_stair1_end // the address to return to when `ret` is executed below
454594:
// save some space by rewrting the coordinate calculation code below
sub_stackwork_stair_draw_on_screen:
  mov eax, [TTSW10_TEMP_j_1_ADDR] // `j`; only lobyte is used; all high bytes vacant
  mov al, [TTSW10_SPIRAL_I_SEQUENCE+eax] // eax=`i`
  push eax // store `i` (argv[2] for our `dmg.dtl` call)
  mov esi, TTSW10_HERO_x_ADDR // at this point, `esi` and `edi` are vacant, but `edi` has been used in our patch for speeding up stair animation (see Rev6 in tswRev.asm)
  imul edx, [esi+4], 0B // h_iy*11
  add edx, [esi] // h_i=h_iy*11+h_ix; player's current location
  cmp eax, edx // call `TTSW10_yusyaidou1` if the tile happens to be the player's current location
  jnz +7
  mov eax, ebx
  call TTSW10_yusyaidou1

  mov edx, TTSW10_TEMP_x_1_ADDR
  mov eax, [edx+30] // edx+30=[TTSW10_GAMEMAP_TOP_ADDR] (e.g., 70 if 800x500)
  add eax, [edx+4] // y=[y_1]+[gamemap_top]
  mov ecx, [edx+2C] // edx+2C=[TTSW10_GAMEMAP_LEFT_ADDR] (e.g., 180 if 800x500)
  add ecx, [edx] // x=[x_1]+[gamemap_left]; meanwhile, this (ecx) is argv[2] for TCustomImageList_Draw

  mov edx, [ebx+254] // TTSW10.Image6
  mov edx, [edx+2C] // tile size
  add edx, eax // y+tile_size; recall that we draw dmg at the left **bottom** position of the tile
  push dx // HIWORD
  push cx // LOWORD
  // now `xy` is pushed on stack; stored as argv[1] for our `dmg.dtl` call
  push eax // y; this is argv[3] for TCustomImageList_Draw

  mov eax, [esp+8] // retrieve `i`; only lobyte is used; all high bytes vacant
  imul edx, [esi-8], 7B // esi-8=TTSW10_HERO_FLOOR_ADDR; floor_id*123
  mov al, byte ptr [TTSW10_MAP_TILE_ID_ADDR+2+edx+eax] // map_tile[floor_id*123+i] is the tile id (the first two bytes are the location you will show up when going up/downstairs)
  dec eax // need to -1 because the image list index is 0-based
  push eax // index; this is argv[4] for TCustomImageList_Draw

  mov edx, [ebx+120] // TFormCanvas
  mov esi, edx // store for future use in our `dmg.dtl` call
  mov eax, [ebx+1B0] // TTSW10.ImageList1
  call TCustomImageList_Draw

  mov eax, esi // retrieve TFormCanvas
  call TCanvas_GetHandle // eax=hDC of TSW window; argv[0] for our `dmg.dtl` call
  pop ecx // retrieve `xy`
  pop edx // retrieve `i`
  call sub_check_need_overlay
  jmp [DLL_dtl_addr]
  ret
  nop
454610:
loc_stackwork_stair1_end:
// save some space by rewrting the code below
  mov ecx, TTSW10_EVENT_COUNT_ADDR
  imul eax, [ecx], 6
  cmp byte ptr [eax+ecx-66], 15 // 48C546; if the next event sequence is still (21, ...)
  jne 4547B4 // else do nothing
  cmp byte ptr [eax+ecx-64], 1 // 48C548; if the next event sequence is still (21, 1, ...)
  jne 4547B4 // else do nothing
  dec [ecx] // if so, process the next event sequence as well (TSW draws two tiles at a time); decrease event count by 1
  mov eax, [ecx]
  nop

454741: // this is the second time drawing the tile, can reuse the previous patch
  call sub_stackwork_stair_draw_on_screen
  jmp 4547B4


//////////////////// Handle Dmg Overlay of Moving Monters ////////////////////
// everything below is part of TTSW10_monidou
48074B:
  mov eax, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
  cmovnz eax, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
  call TBitmap_GetCanvas
  push eax // store TBitmapCanvas

  push [TTSW10_TEMP_BITMAP_1_ADDR] // it is now of 40x80 or 80x40 dimension
  mov edx, [TTSW10_TEMP_x_1_ADDR]
  mov ecx, [TTSW10_TEMP_y_1_ADDR]
  call TCanvas_Draw // draw moved monster onto [TTSW10_GAMEMAP_BITMAP_i_ADDR]

  pop eax
  call sub_draw_moving_dmg
  jmp 480791 // draw [TTSW10_GAMEMAP_BITMAP_1_ADDR] onto physical screen

4807C5: // this part draws the final state onto [TTSW10_GAMEMAP_BITMAP_2_ADDR]
// no need to recalculate the variables that have not changed; a lot of space can be saved here
  inc [TTSW10_TEMP_i_2_ADDR] // tile index; previously, was the 1st of the 2 frames of the monster; now +1 to indicate the second
  inc [TTSW10_TEMP_i_1_ADDR] // previously was 0 (indicating bitmap #1); now +1 to indicate bitmap #2

  mov eax, ebx
  call TTSW10_monidouwork // draw [TTSW10_TEMP_BITMAP_1_ADDR]
  jmp loc_TTSW10_monidou_finalize
  xchg ax, ax // 2-byte nop
loc_draw_moving_dmg_ret:
  ret // this is used for sub_draw_moving_dmg

4807E0: // all recalcuation in the middle is avoided; now we have space for our own codes
sub_draw_moving_dmg: // eax=TBitmapCanvas of [TTSW10_GAMEMAP_BITMAP_i_ADDR]; ebx=[TTSW10]
  call sub_check_need_overlay
  call TCanvas_GetHandle // TBitmapCanvas already given in eax from argv

  mov edx, [ebx+254] // TTSW10.Image6
  mov edx, [edx+2C] // tile size; only lobyte is used; dl=32 or 40

  mov ecx, [TTSW10_TEMP_x_2_ADDR] // distance w.r.t. the original coordinate; only lobyte is used; 0<=cl<=dl; all high bytes vacant
  mov dh, [TTSW10_TEMP_x_3_ADDR] // a temp var: here: used to indicate the monster moving direction: 1-down; 2-left; 3-right; 4-up (of different use elsewhere; e.g., in battles, used to store total damage)
  test dh, 1 // 1 || 3
  jne +4 // do nothing for 2 || 4 (+x or +y direction)
  sub cl, dl // otherwise, the result will be tile_size-x_2
  neg cl // because whether moving in +x/+y or -x/-y direction, redrawing always starts with the tile cell with the smaller x/y coordinate

  sub dh, 2
  cmp dh, 1 // 1 || 4
  jbe +3 // do nothing for 2 || 3 (moving in x direction); delta_x is saved to LOWORD of ecx
  shl ecx, 10 // delta_y is saved to HIWORD of ecx

  mov dh, 0 // now edx=dl=tile size
  add edx, [TTSW10_TEMP_y_1_ADDR] // y+tile_size; recall that we draw dmg at the left **bottom** position of the tile
  shl edx, 10 // save to HIWORD
  mov dx, [TTSW10_TEMP_x_1_ADDR] // save to LOWORD
  add ecx, edx // xy: LOWORD: x+delta_x; HIWORD: y+delta_y

  imul edx, [edi], 6
  mov dl, [esi+edx+2] // monster's original i: ix+11*iy

  jmp [DLL_dtl_addr] // eax = hDC of TBitmapCanvas (not changed since the first call)
  db 90,90,90,90 // vacant space for new functions starting from 480838

480A29:
loc_TTSW10_monidou_finalize:
  mov eax, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
  call TBitmap_GetCanvas
  push eax // store TBitmapCanvas

  push [TTSW10_TEMP_BITMAP_1_ADDR]
  mov edx, [TTSW10_TEMP_x_1_ADDR]
  mov ecx, [TTSW10_TEMP_y_1_ADDR]
  call TCanvas_Draw

  pop eax
  call sub_draw_moving_dmg
  xchg ax, ax // 2-byte nop

// need to handle the map change below
// ebx/ebp/esi/edi is now free to use
  imul edx, [edi], 6
  movzx edi, word ptr [esi+edx+2] // monster's original i: ix+11*iy
  movzx esi, word ptr [esi+edx+4] // monster's current i
  mov edx, m_dmg_cri
  mov eax, [edx+edi*4]
  mov [edx+edi*4], -2 // no dmg overlay for plain road
  mov [edx+esi*4], eax // change the current i's tile to monster's dmgCri value

  imul eax, [TTSW10_HERO_FLOOR_ADDR], 7B // floor_id*123
  add eax, TTSW10_MAP_TILE_ID_ADDR+2 // map_tile[floor_id*123+i] is the tile id (the first two bytes are the location you will show up when going up/downstairs)
  mov cl, [eax+edi]
  mov byte ptr [eax+edi], 6 // change original i to road
  mov byte ptr [eax+esi], cl // change current i to monster
*/
    {0x4BA1B5, 147, "\0\3\0" "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
        "BeginPath\0\0\0" "EndPath\0" "StrokePath\0\0"
        "\x10\0\0\0" "\6\0\0\0" "\0\0\0\0" "\0\0\0\0" "\xBC\2\0\0" "\0\0\0\0\0\0\3\0" "Tahoma\0\0"
        "\x22\xAA\x22\0" "\xC0\xA0\x60\0" "\xFF\x22\x22\0" "\x40\x7F\xC0\0" "\x88\x99\x88\0" "\x66\x66\x66\0" "\xFF\xFF\xFF\0"
        "\0\0\0\0\0\0\0\0\0\0\0\0"},
    {0x47D2D8, 64, "\x80\x3D\xB5\xA1\x4B\x00\x00\x75\xF5\x50\x68\x00\xD3\x47\x00\xE8\x10\x79\xF8\xFF\x68\x04\xD3\x47\x00\x50\x68\x0C\xD3\x47\x00\x50\xE9\xB3\x65\xFE\xFF\x90\x90\x90"
        "dmg\0" "ini\0" "fin\0" "cmp\0" "dtl\0" "dmp\0"},
    {0x463874, 113, "\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x1D\x68\x00\xD3\x47\x00\xE8\x29\xDA\xF9\xFF\x50\x68\x08\xD3\x47\x00\x50\xE8\xF1\x12\xFA\xFF\xFF\xD0\xE8\x8A\x12\xFA\xFF\xC3\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x5B\xE9\x66\x12\x02\x00\x66\x90\x68\x10\xD3\x47\x00\x50\x68\x14\xD3\x47\x00\x50\xE8\xC3\x12\xFA\xFF\xA3\x44\xA2\x4B\x00\xE8\xB9\x12\xFA\xFF\xA3\x40\xA2\x4B\x00\xE8\xAF\x12\xFA\xFF\xA3\x3C\xA2\x4B\x00\xE8\xA5\x12\xFA\xFF\x8B\xC8\x58\xFF\xD1\xC3"},
    {0x484B14, 50, "\xE8\x5B\xED\xFD\xFF\xBB\x14\xC5\x48\x00\x8B\x03\xE8\x0F\xE1\xF7\xFF\x8B\x43\x04\xE8\x07\xE1\xF7\xFF\x8B\x43\x08\xE8\xFF\xE0\xF7\xFF\x8B\x43\x0C\xE8\xF7\xE0\xF7\xFF\x8B\x43\x10\xE8\xEF\xE0\xF7\xFF\x90"},
    {0x44314E, 4, "\xE6\xD6\x03\x00"},
    {0x443276, 4, "\xBE\xD5\x03\x00"},
    {0x417EA8, 4, "\x04\x8A\x06\x00"},
    {0x41A5C6, 5, "\xE8\x81\x62\x06\x00"},
    {0x463933, 5, "\xE9\xDC\x11\x02\x00"},
    {0x442C4A, 58, "\x40\x8B\xF0\xEB\x02\xEB\x07\x80\x0D\xB6\xA1\x4B\x00\x03\x89\x37\x8B\xC6\x8A\x80\x1F\x9B\x48\x00\xB1\x0B\xF6\xF1\x8B\x93\x54\x02\x00\x00\x8B\x4A\x2C\x88\xE5\xF6\xE1\xA3\x50\xC5\x48\x00\x50\x88\xE8\xF6\xE1\xA3\x4C\xC5\x48\x00\xEB\x15"},
    {0x450BE7, 9, "\x80\x0D\xB6\xA1\x4B\x00\x04\x66\x90"},
    {0x451939, 20, "\xC7\x04\x45\x4E\xC7\x48\x00\x00\x00\x00\x00\x80\x0D\xB6\xA1\x4B\x00\x03\x66\x90"},
    {0x44A54A, 25, "\xBA\x54\xC5\x48\x00\x8B\x02\x2D\xC6\x00\x00\x00\x89\x42\x08\x89\x42\x64\x80\x0D\xB6\xA1\x4B\x00\x04"},
    {0x449E66, 13, "\x31\xDB\x89\x1C\x4A\x80\x0D\xB6\xA1\x4B\x00\x08\x90"},
    {0x442F1D, 44, "\x68\x61\x2F\x44\x00\xFF\x35\x3C\xA2\x4B\x00\x80\x3D\xB5\xA1\x4B\x00\x00\x74\x14\x80\x3D\xB7\xA1\x4B\x00\x00\x78\x0B\x75\x0C\x80\x3D\xCC\x86\x4B\x00\x01\x74\x03\x83\xC4\x04\xC3"},
    {0x45458F, 164, "\x68\x10\x46\x45\x00\xA1\x70\xC5\x48\x00\x8A\x80\x1F\x9B\x48\x00\x50\xBE\xA0\x86\x4B\x00\x6B\x56\x04\x0B\x03\x16\x39\xD0\x75\x07\x8B\xC3\xE8\xEE\xED\xFE\xFF\xBA\x4C\xC5\x48\x00\x8B\x42\x30\x03\x42\x04\x8B\x4A\x2C\x03\x0A\x8B\x93\x54\x02\x00\x00\x8B\x52\x2C\x01\xC2\x66\x52\x66\x51\x50\x8B\x44\x24\x08\x6B\x56\xF8\x7B\x8A\x84\x10\x36\x89\x4B\x00\x48\x50\x8B\x93\x20\x01\x00\x00\x8B\xF2\x8B\x83\xB0\x01\x00\x00\xE8\x4A\x38\xFC\xFF\x8B\xC6\xE8\x4F\x63\xFC\xFF\x59\x5A\xE8\x20\xE9\xFE\xFF\xFF\x25\x40\xA2\x4B\x00\xC3\x90\xB9\xAC\xC5\x48\x00\x6B\x01\x06\x80\x7C\x08\x9A\x15\x0F\x85\x91\x01\x00\x00\x80\x7C\x08\x9C\x01\x0F\x85\x86\x01\x00\x00\xFF\x09\x8B\x01\x90"},
    {0x454741, 7, "\xE8\x4E\xFE\xFF\xFF\xEB\x6C"},
    {0x48074B, 49, "\xA1\x14\xC5\x48\x00\x0F\x45\x05\x18\xC5\x48\x00\xE8\x7C\xD3\xF9\xFF\x50\xFF\x35\x1C\xC5\x48\x00\x8B\x15\x4C\xC5\x48\x00\x8B\x0D\x50\xC5\x48\x00\xE8\x44\x9E\xF9\xFF\x58\xE8\x66\x00\x00\x00\xEB\x15"},
    {0x4807C5, 315, "\xFF\x05\x58\xC5\x48\x00\xFF\x05\x54\xC5\x48\x00\x8B\xC3\xE8\xB8\x02\x00\x00\xE9\x4C\x02\x00\x00\x66\x90\xC3\xE8\x43\x27\xFC\xFF\xE8\x66\xA1\xF9\xFF\x8B\x93\x54\x02\x00\x00\x8B\x52\x2C\x8B\x0D\x5C\xC5\x48\x00\x8A\x35\x68\xC5\x48\x00\xF6\xC6\x01\x75\x04\x28\xD1\xF6\xD9\x80\xEE\x02\x80\xFE\x01\x76\x03\xC1\xE1\x10\xB6\x00\x03\x15\x50\xC5\x48\x00\xC1\xE2\x10\x66\x8B\x15\x4C\xC5\x48\x00\x01\xD1\x6B\x17\x06\x8A\x54\x32\x02\xFF\x25\x40\xA2\x4B\x00\x90\x90\x90\x90\x80\x3D\xB5\xA1\x4B\x00\x00\x0F\x84\x73\x9D\xF9\xFF\xFF\x25\x44\xA2\x4B\x00\x90\x8B\xD8\x8B\x75\x08\x31\xD2\x38\x15\xB5\xA1\x4B\x00\x74\x54\xB9\xBC\xA1\x4B\x00\x8B\x40\x34\x3B\x05\x14\xC5\x48\x00\x74\x0B\x3B\x05\x18\xC5\x48\x00\x75\x3C\x83\xC1\x04\x68\x20\x00\xCC\x00\x52\x52\xFF\x31\xFF\x35\xB8\xA1\x4B\x00\xE8\x42\x45\xF8\xFF\x8B\xC6\xE8\x47\xD2\xF9\xFF\xE8\xBA\xA0\xF9\xFF\x50\x8B\x46\x10\xFF\x70\x18\xFF\x70\x14\xFF\x75\xFC\x57\xFF\x35\xB8\xA1\x4B\x00\xE8\xAD\x43\xF8\xFF\xC3\x31\xD2\x38\x15\xB5\xA1\x4B\x00\x74\x41\xB9\xBC\xA1\x4B\x00\x8B\x76\x34\x3B\x35\x14\xC5\x48\x00\x74\x0B\x3B\x35\x18\xC5\x48\x00\x75\x29\x83\xC1\x04\x52\x6A\xFF\x52\x52\x52\xFF\x75\x0C\x57\xFF\x35\xB8\xA1\x4B\x00\xFF\x75\x08\x50\xFF\x31\xFF\x35\xB8\xA1\x4B\x00\xE8\xD6\x44\xF8\xFF\xE8\x9D\xE3\xF8\xFF\xE9\x98\xE3\xF8\xFF"},
    {0x480A29, 95, "\xA1\x18\xC5\x48\x00\xE8\xA5\xD0\xF9\xFF\x50\xFF\x35\x1C\xC5\x48\x00\x8B\x15\x4C\xC5\x48\x00\x8B\x0D\x50\xC5\x48\x00\xE8\x6D\x9B\xF9\xFF\x58\xE8\x8F\xFD\xFF\xFF\x66\x90\x6B\x17\x06\x0F\xB7\x7C\x32\x02\x0F\xB7\x74\x32\x04\xBA\x00\x9C\x48\x00\x8B\x04\xBA\xC7\x04\xBA\xFE\xFF\xFF\xFF\x89\x04\xB2\x6B\x05\x98\x86\x4B\x00\x7B\x05\x36\x89\x4B\x00\x8A\x0C\x38\xC6\x04\x38\x06\x88\x0C\x30"},
    };

int main() {
    patch(patches, (&patches)[1]);
    return 0;
}
