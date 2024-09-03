; works similarly to 'tswMPExt/dmg.exe.c'; see 'tswMPExt/README.txt' for more information
; the assembly codes here can be loaded by CheatEngine's auto-assembler; before doing so, replace all semicolons (;) with double slashes (//) as CheatEngine won't recognize simicolons as comments
; use CheatEngine 6.7. Higher versions are known to have bugs in auto-assembler, which tend to use longer opcodes for some specific assembly operations, and that will mess up everything

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
  m_dmg_cri: ; dword[121]
489DF0:
  db 'SetDCBrushColor', 0
4BA1B5:
  tswMP_overlay_enabled: ; byte
  db 0
4BA1B6:
  need_update: ; byte
  db 3
4BA1B7:
  always_show_overlay: ; byte
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
str_gdi32: ; gdi32.dll
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
  dd #16, 6, 0, 0, #700 ; height, width, esc, orient, weight
  db 0, 0, 0, 0, 0, 0, 3, 0 ; italic, underline, strike, charset, out, clip, quality, pitch
  db 'Tahoma', 0 ; name
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

; new functions will start from 4BA23C



;;;;;;;;;; Handle Routine Dmg Overlay ;;;;;;;;;;
4BA23C:
sub_backup_tile_TCanvas_Draw:
	mov ebx, eax	; TCanvas (dest)
	mov esi, [ebp+8]	; TBitmap (src)

	xor edx, edx	; now edx=0
	cmp byte ptr [tswMP_overlay_enabled], dl
	je +54	; loc_backup_tile_TCanvas_Draw_fin

	mov ecx, hMemBmp_1
	mov eax, [eax+34]	; corresponding TBitmap of TBitmapCanvas (dest)
	cmp eax, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
	je +0B	; loc_backup_tile_TCanvas_Draw_work

	cmp eax, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
	jne +3C	; loc_backup_tile_TCanvas_Draw_fin
	add ecx, 4	; hMemBmp_2

	loc_backup_tile_TCanvas_Draw_work:
	push 00CC0020	; rop: SRCCOPY
	push edx	; y1: 0
	push edx	; x1: 0

	push [ecx]	; HGDIOBJ h
	push [hMemDC]	; HDC hdc
	call Gdi32_SelectObject

	mov eax, esi	; TBitmap (src)
	call TBitmap_GetCanvas
	call TCanvas_GetHandle
	push eax	; hdcSrc
	mov eax, [esi+10]	; see TBitmap_GetWidth and TBitmap_GetHeight
	push [eax+18]	; cy: height of TBitmap (src)
	push [eax+14]	; cx: width of TBitmap (src)
	push [ebp-4]	; y: top of TCanvas (dest) to draw
	push edi	; x: left of TCanvas (dest) to draw
	push [hMemDC]	; hdc

	call Gdi32_BitBlt
	loc_backup_tile_TCanvas_Draw_fin:
	ret


sub_backup_tile_TCustomImageList_Draw:
	xor edx, edx	; now edx=0
	cmp byte ptr [tswMP_overlay_enabled], dl
	je +41	; loc_backup_tile_TCustomImageList_Draw_fin

	mov ecx, hMemBmp_1
	mov esi, [esi+34]	; corresponding TBitmap of TBitmapCanvas (dest) [its himl is already saved in eax; esi is now idle]
	cmp esi, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
	je +0B	; loc_backup_tile_TCustomImageList_Draw_work

	cmp esi, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
	jne +29	; loc_backup_tile_TCustomImageList_Draw_fin
	add ecx, 4	; hMemBmp_2

	loc_backup_tile_TCustomImageList_Draw_work:
	push edx	; fStyle: 0
	push -1	; rgbFg: CLR_NONE
	push edx	; rgbBk: 0
	push edx	; dy: 0 (full size)
	push edx	; dx: 0 (full size)
	push [ebp+C]	; y (from argv)
	push edi	; x (from argv)
	push [hMemDC]	; hdc
	push [ebp+8]	; i (from argv)
	push eax	; himl (from argv (processed in earlier codes in TCustomImageList_Draw))

	push [ecx]	; HGDIOBJ h
	push [hMemDC]	; HDC hdc
	call Gdi32_SelectObject

	call Comctl32_ImageList_DrawEx
	loc_backup_tile_TCustomImageList_Draw_fin:
	jmp Comctl32_ImageList_DrawEx


sub_draw_map:
	cmp byte ptr [tswMP_overlay_enabled], 0
	jne sub_dmp
	jmp TCanvas_Draw
	xchg ax, ax	; 2-byte nop

; new functions will starts from 4BA300


44314D:	; part of TTSW10_Timer1Timer
	call sub_draw_map
443275:
	call sub_draw_map


41A5C6:	; part of TCanvas_Draw
	call sub_backup_tile_TCanvas_Draw


417EA7:	; part of TCustomImageList_Draw
	call sub_backup_tile_TCustomImageList_Draw


484B50:	; part of TTSW10_TSW10close
	; for the following `TApplication.Terminate` call, setting its argv[0] is not necessary as it is not used; thus saving 5 bytes to insert our code
	call sub_fin	; free dmg drawing-related GDI obj


46396F:	; part of TTSW10_Exit1Click
	call sub_fin	; like above


4638E4:	; part of TTSW10_GameQuit1Click
	call sub_fin	; like above



;;;;;;;;;; Handle Dmg Redrawing upon Events ;;;;;;;;;;
442C4A:	; part of TTSW10_mhyouji; need to `or byte ptr [need_update], 3` (refresh map dmg display)
	inc eax	; eax was 0
	mov esi, eax	; saved 2 bytes w.r.t. `mov esi, 00000001`
	jmp +2	; execute `or byte ptr [need_update], 3`

	loc_TTSW10_mhyouji_loop:
	jmp +7	; bypass `or byte ptr [need_update], 3`
	or byte ptr [need_update], 3
; save some space by rewrting the coordinate calculation code below
	mov [edi], esi
	mov eax, esi
	mov al, [TTSW10_SPIRAL_I_SEQUENCE+eax]	; this returns the actual i (=ix+11*iy) of the current index (=esi) in a spiral sequence (although I don't think is useful in this function because everytile is refreshed all at once without any pause)
	mov cl, 0B
	div cl	; al=iy; ah=ix
	mov edx, [ebx+0254]	; TTSW10.Image6
	mov ecx, [edx+2C]	; tile size
	mov ch, ah	; store ix
	mul cl	; iy*tile_size
	mov [TTSW10_TEMP_y_1_ADDR], eax
	push eax
	mov al, ch	; retrieve ix
	mul cl	; iy*tile_size
	mov [TTSW10_TEMP_x_1_ADDR], eax	; x
	jmp 442C99	; now enough space has been saved to insert our code (`or byte ptr [need_update], 3`)


450BE7:	; part of TTSW10_Button38Click; use item; need to `or byte ptr [need_update], 4` (defer dmg drawing update; otherwise the drawing might be erased by TSW's redrawing)
	or byte ptr [need_update], 4
	xchg ax, ax	; 2-byte nop
451939:	; 13=MagicKey; always need to update dmg overlay even if no dmgCri value is changed (because the magic attack dmg on some doors might be erased after it turns into road)
	mov [eax*2+48C74E], 0
	or byte ptr [need_update], 3
	xchg ax, ax	; 2-byte nop


44A54A:	; part of TTSW10_taisen; need to `or byte ptr [need_update], 4` (defer dmg drawing update; no need to refresh map dmg during battle)
	mov edx, TTSW10_TEMP_i_1_ADDR	; difference of tile index b/w the 2nd and 1st frame (usually 1, but not for Dragon or Octopus)
	mov eax, [edx]
	sub eax, 00C6	; don't know what's the doing here, but we can save a bit space here to insert our code, `or byte ptr [need_update], 4`
	mov [edx+08], eax	; 48C55C
	mov [edx+64], eax	; 48C5B8
	or byte ptr [need_update], 4


449E66:	; part of TTSW10_zyouout (gameover when [48C5A4]==9); need to `or byte ptr [need_update], 8` (hide dmg display)
	xor ebx, ebx
	mov dword ptr [edx+ecx*2], ebx
	or byte ptr [need_update], 8
	nop



;;;;;;;;;; Handle Dmg Overlay When Moving on Stairs ;;;;;;;;;;
442F1D:	; part of TTSW10_kaidanwork
	push 442F61	; the address to return to when the second `ret` is executed below
	; the original code sets the Timer2 interval to 2ms/6ms/10ms for high/middle/low-speed modes for showing stair animation; however, the theoretical minimal interval supported by the Windows `SetTimer` API is 10ms, so there is no use setting the interval less than 10ms. Therefore, the useless code can be skipped and can directly jump to the part where the timer interval is set to 10ms
	push sub_cmp	; the address to return to when the first `ret` is executed below
	; need to update map damage calculation before drawing
	nop	; will continue to execute `sub_check_need_overlay` below
442F28:
sub_check_need_overlay:	; when `tswMP_overlay_enabled`, `ret` to continue normal operation either if `always_show_overlay` or `TTSW10_HERO_ORB_OF_HERO_ADDR`; otherwise, stop the current caller function and `ret` to caller's caller
	cmp byte ptr [tswMP_overlay_enabled], 0
	je +14	; loc_check_need_overlay_false
	cmp byte ptr [always_show_overlay], 0
	js +0B	; loc_check_need_overlay_false
	jne +0C	; loc_check_need_overlay_true
	cmp byte ptr [TTSW10_HERO_ORB_OF_HERO_ADDR], 1
	je +03	; loc_check_need_overlay_true

	loc_check_need_overlay_false:	; `ret` to caller's caller (stop the current caller function)
	add esp, 4	; pop the return address; do not execute the remaining commands in the caller function and jump back to caller's caller

	loc_check_need_overlay_true:	; `ret` to caller function (continue normal operation)
	ret


; everything below is part of TTSW10_stackwork where an event sequence like (21, 1, j) is processed; for more details on the event sequence, see tswBGM.asm
; (21, 0, j) shows the j-th "sword-and-staff" tile; (21, 1, j) hides that "sword-and-staff" tile and shows the actual tile on the next map; since the tile shows/hides in a spiral sequence, the actual map index `i` is different from `j` and is obtained by ((*byte*)0x489B1F)[j]
45458F:	; below, the j-th tile is drawn onto the screen; and if the tile happens to be the player's current location, call `TTSW10_yusyaidou1`
	push loc_stackwork_stair1_end	; the address to return to when `ret` is executed below
454594:
; save some space by rewrting the coordinate calculation code below
sub_stackwork_stair_draw_on_screen:
	mov eax, [TTSW10_TEMP_j_1_ADDR]	; `j`; only lobyte is used; all high bytes vacant
	mov al, [TTSW10_SPIRAL_I_SEQUENCE+eax]	; eax=`i`
	push eax	; store `i` (argv[2] for our `sub_dtl` call)
	mov esi, TTSW10_HERO_x_ADDR	; at this point, `esi` and `edi` are vacant, but `edi` has been used in our patch for speeding up stair animation (see Rev6 in tswRev.asm)
	imul edx, [esi+4], 0B	; h_iy*11
	add edx, [esi]	; h_i=h_iy*11+h_ix; player's current location
	cmp eax, edx	; call `TTSW10_yusyaidou1` if the tile happens to be the player's current location
	jnz +7
	mov eax, ebx
	call TTSW10_yusyaidou1

	mov edx, TTSW10_TEMP_x_1_ADDR
	mov eax, [edx+30]	; edx+30=[TTSW10_GAMEMAP_TOP_ADDR] (e.g., 70 if 800x500)
	add eax, [edx+4]	; y=[y_1]+[gamemap_top]
	mov ecx, [edx+2C]	; edx+2C=[TTSW10_GAMEMAP_LEFT_ADDR] (e.g., 180 if 800x500)
	add ecx, [edx]	; x=[x_1]+[gamemap_left]; meanwhile, this (ecx) is argv[2] for TCustomImageList_Draw

	mov edx, [ebx+254]	; TTSW10.Image6
	mov edx, [edx+2C]	; tile size
	add edx, eax	; y+tile_size; recall that we draw dmg at the left **bottom** position of the tile
	push dx	; HIWORD
	push cx	; LOWORD
	; now `xy` is pushed on stack; stored as argv[1] for our `sub_dtl` call
	push eax	; y; this is argv[3] for TCustomImageList_Draw

	mov eax, [esp+8]	; retrieve `i`; only lobyte is used; all high bytes vacant
	imul edx, [esi-8], 7B	; esi-8=TTSW10_HERO_FLOOR_ADDR; floor_id*123
	mov al, byte ptr [TTSW10_MAP_TILE_ID_ADDR+2+edx+eax]	; map_tile[floor_id*123+i] is the tile id (the first two bytes are the location you will show up when going up/downstairs)
	dec eax	; need to -1 because the image list index is 0-based
	push eax	; index; this is argv[4] for TCustomImageList_Draw

	mov edx, [ebx+120]	; TFormCanvas
	mov eax, [ebx+1B0]	; TTSW10.ImageList1
	call TCustomImageList_Draw

	mov eax, [ebx+120]	; TFormCanvas
	call TCanvas_GetHandle	; eax=hDC of TSW window; argv[0] for our `sub_dtl` call
	pop ecx	; retrieve `xy`
	pop edx	; retrieve `i`
	call sub_check_need_overlay
	jmp sub_dtl
	nop
454610:
loc_stackwork_stair1_end:
; save some space by rewrting the code below
	mov ecx, TTSW10_EVENT_COUNT_ADDR
	imul eax, [ecx], 6
	cmp byte ptr [eax+ecx-66], 15	; 48C546; if the next event sequence is still (21, ...)
	jne 4547B4	; else do nothing
	cmp byte ptr [eax+ecx-64], 1	; 48C548; if the next event sequence is still (21, 1, ...)
	jne 4547B4	; else do nothing
	dec [ecx]	; if so, process the next event sequence as well (TSW draws two tiles at a time); decrease event count by 1
	mov eax, [ecx]
	nop

454741:	; this is the second time drawing the tile, can reuse the previous patch
	call sub_stackwork_stair_draw_on_screen
	jmp 4547B4



;;;;;;;;;; Handle Dmg Overlay of Moving Monters ;;;;;;;;;;
; everything below is part of TTSW10_monidou
48074B:
	mov eax, [TTSW10_GAMEMAP_BITMAP_1_ADDR]
	cmovnz eax, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
	call TBitmap_GetCanvas
	push eax	; store TBitmapCanvas

	push [TTSW10_TEMP_BITMAP_1_ADDR]	; it is now of 40x80 or 80x40 dimension
	mov edx, [TTSW10_TEMP_x_1_ADDR]
	mov ecx, [TTSW10_TEMP_y_1_ADDR]
	call TCanvas_Draw	; draw moved monster onto [TTSW10_GAMEMAP_BITMAP_i_ADDR]

	pop eax
	call sub_draw_moving_dmg
	jmp 480791	; draw [TTSW10_GAMEMAP_BITMAP_1_ADDR] onto physical screen

4807C5:	; this part draws the final state onto [TTSW10_GAMEMAP_BITMAP_2_ADDR]
; no need to recalculate the variables that have not changed; a lot of space can be saved here
	inc [TTSW10_TEMP_i_2_ADDR]	; tile index; previously, was the 1st of the 2 frames of the monster; now +1 to indicate the second
	inc [TTSW10_TEMP_i_1_ADDR]	; previously was 0 (indicating bitmap #1); now +1 to indicate bitmap #2

	mov eax, ebx
	call TTSW10_monidouwork	; draw [TTSW10_TEMP_BITMAP_1_ADDR]
	jmp loc_TTSW10_monidou_finalize
	db 0f, 1f, 00	; 3-byte nop
4807E0:	; all recalcuation in the middle is avoided; now we have space for our own codes
sub_draw_moving_dmg:	; eax=TBitmapCanvas of [TTSW10_GAMEMAP_BITMAP_i_ADDR]; ebx=[TTSW10]
	call sub_check_need_overlay
	call TCanvas_GetHandle	; TBitmapCanvas already given in eax from argv

	mov edx, [ebx+254]	; TTSW10.Image6
	mov edx, [edx+2C]	; tile size; only lobyte is used; dl=32 or 40

	mov ecx, [TTSW10_TEMP_x_2_ADDR]	; distance w.r.t. the original coordinate; only lobyte is used; 0<=cl<=dl; all high bytes vacant
	mov dh, [TTSW10_TEMP_x_3_ADDR]	; a temp var: here: used to indicate the monster moving direction: 1-down; 2-left; 3-right; 4-up (of different use elsewhere; e.g., in battles, used to store total damage)
	test dh, 1	; 1 || 3
	jne +4	; do nothing for 2 || 4 (+x or +y direction)
	sub cl, dl	; otherwise, the result will be tile_size-x_2
	neg cl	; because whether moving in +x/+y or -x/-y direction, redrawing always starts with the tile cell with the smaller x/y coordinate

	sub dh, 2
	cmp dh, 1	; 1 || 4
	jbe +3	; do nothing for 2 || 3 (moving in x direction); delta_x is saved to LOWORD of ecx
	shl ecx, 10	; delta_y is saved to HIWORD of ecx

	mov dh, 0	; now edx=dl=tile size
	add edx, [TTSW10_TEMP_y_1_ADDR]	; y+tile_size; recall that we draw dmg at the left **bottom** position of the tile
	shl edx, 10	; save to HIWORD
	mov dx, [TTSW10_TEMP_x_1_ADDR]	; save to LOWORD
	add ecx, edx	; xy: LOWORD: x+delta_x; HIWORD: y+delta_y

	imul edx, [edi], 6
	mov dl, [esi+edx+2]	; monster's original i: ix+11*iy

	jmp sub_dtl	; eax = hDC of TBitmapCanvas (not changed since the first call)

480A29:
loc_TTSW10_monidou_finalize:
	mov eax, [TTSW10_GAMEMAP_BITMAP_2_ADDR]
	call TBitmap_GetCanvas
	push eax	; store TBitmapCanvas

	push [TTSW10_TEMP_BITMAP_1_ADDR]
	mov edx, [TTSW10_TEMP_x_1_ADDR]
	mov ecx, [TTSW10_TEMP_y_1_ADDR]
	call TCanvas_Draw

	pop eax
	call sub_draw_moving_dmg
	xchg ax, ax	; 2-byte nop

; need to handle the map change below
; ebx/ebp/esi/edi is now free to use
	imul edx, [edi], 6
	movzx edi, word ptr [esi+edx+2]	; monster's original i: ix+11*iy
	movzx esi, word ptr [esi+edx+4]	; monster's current i
	mov edx, m_dmg_cri
	mov eax, [edx+edi*4]
	mov [edx+edi*4], -2	; no dmg overlay for plain road
	mov [edx+esi*4], eax	; change the current i's tile to monster's dmgCri value

	imul eax, [TTSW10_HERO_FLOOR_ADDR], 7B	; floor_id*123
	add eax, TTSW10_MAP_TILE_ID_ADDR+2	; map_tile[floor_id*123+i] is the tile id (the first two bytes are the location you will show up when going up/downstairs)
	mov cl, [eax+edi]
	mov byte ptr [eax+edi], 6	; change original i to road
	mov byte ptr [eax+esi], cl	; change current i to monster



;;;;;;;;;; Quick Demo w/o tswMP ;;;;;;;;;;
47D2D8:
TTSW10_Help2Click:	; usage: press F1 to enable dmg overlay function
	cmp byte ptr [tswMP_overlay_enabled], 0
	je sub_ini
	ret


463874:
TTSW10_GameQuit1Click:	; usage: press F9 to disable dmg overlay function
	cmp byte ptr [tswMP_overlay_enabled], 0
	jne sub_res
	ret
