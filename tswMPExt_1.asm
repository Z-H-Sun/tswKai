4BA300:
sub_dmp:	// eax=[IN] TTSW10_TCanvas; edx=[not used] TSW_map_left; ecx=[not used] TSW_map_top; [ebp+8]=[IN] TSW_cur_mBitmap
	push ebp
	push edi
	push esi
	push ebx	// ebx=HANDLE TTSW10 from TTSW10.Timer1Timer
	push eax	// TTSW10_TCanvas
	mov eax, [ebx+0254]	// TTSW10.Image6 (directly read pointer of TTSW10 from ebx, which has not been implemented in 'dmg.dll.c')
	push [eax+2C]	// TSW_tileSize
	// [esp]=DWORD TSW_tileSize; [esp+4]=argv[0]=TTSW_TCanvas; [esp+1C]=argv[3]=TSW_cur_mBitmap
	cmp byte ptr [489DE4], 0	// polyline_state
	je +0E

	mov eax, [esp+1C]	// TSW_cur_mBitmap
	call sub_drawConnectivityOnBitmap
	// edi=TSW_mBitmap_hDC will be set to TSW_cur_mBitmap's corresponding hDC in `sub_drawConnectivityOnBitmap` (this has not been implemented in 'dmg.dll.c'); see comments there
	jmp loc_dmp_draw	// edi=TSW_mBitmap_hDC

	mov eax, [esp+1C]	// TSW_cur_mBitmap
	call 41DAD8	// TBitmap_GetCanvas
	call 41A950	// TCanvas_GetHandle
	mov edi, eax	// edi=TSW_mBitmap_hDC

	mov esi, 4BA1B6	// p_need_update
	cmp byte ptr [esi+1], 1	// always_show_overlay
	jz +1F

	cmp [4B86CC], 1	// player has OrbOfHero or not
	je +16
	no_overlay:
	test byte ptr [esi], 10
	jnz loc_dmp_draw
	call sub_restoreGameBitmaps
	or byte ptr [esi], 13
	jmp loc_dmp_draw

	test byte ptr [esi], 08
	jz +0C
	cmp [48C5AC], 0	// TSW_event_count
	jg no_overlay
	and byte ptr [esi], F3

	test byte ptr [esi], 04
	jz +10

	cmp [48C5AC], 0	// TSW_event_count
	jg loc_dmp_draw
	and byte ptr [esi], FB

	call sub_cmp
	movzx ecx, byte ptr [48C5D2]	// TSW_cur_frame
	lea eax, [ecx+1]
	test [esi], al
	jz loc_dmg_update_player_tile	// need to especially consider the tile at player's prev/current/next position

	loc_dmp_update_map:	// need to update the whole map tiles
	mov al, 2
	sub eax, ecx
	and [esi], al

	mov eax, [4BA1B8]	// hMemDC
	xor ebx, ebx	// i (now =0)
	imul edx, [esp], #11	// TSW_mapSize
	push 00CC0020
	push ebx	// 0
	push ebx
	push eax
	push edx
	push edx
	push ebx
	push ebx
	push edi	// TSW_mBitmap_hDC
	push [ecx*4+4BA1BC]	// hMemBmp[TSW_cur_frame]
	push eax
	call 404DCC	// SelectObject
	call 404C5C	// BitBlt

	push [4BA1CC]	// hFont_dmg
	push edi	// TSW_mBitmap_hDC
	push [4BA1C4]	// hPen_stroke
	push edi
	push 01	// TRANSPARENT
	push edi
	call 404DE4	// SetBkMode
	call 404DCC	// SelectObject
	mov esi, eax	// store hPen_old
	call 404DCC	// SelectObject
	mov ebp, eax	// store hFont_old

	loc_dmp_update_map_loop:
	mov cl, #11
	mov eax, ebx	// i
	div cl	// ix+iy*11=i
	inc eax	// al=++iy
	mov cl, ah	// cl=ix
	mul byte ptr [esp]	// tileSize
	shl eax, 10	// HIWORD(eax)=y
	mov al, cl
	mul byte ptr [esp]	// LOWORD(eax)=x
	mov ecx, eax	// xy
	mov edx, ebx	// i
	or dl, 80
	mov eax, edi	// TSW_mBitmap_hDC
	call sub_dtl
	inc ebx
	cmp ebx, #121
	jne loc_dmp_update_map_loop

	push ebp	// hFont_old
	push edi
	push esi	// hPen_old
	push edi
	call 404DCC	// SelectObject
	call 404DCC	// SelectObject
	jmp loc_dmp_draw

	loc_dmg_update_player_tile:
	cmp [48C5AC], 0
	jg loc_dmp_draw
	mov ecx, [4B86A0]	// cur_ix
	mov eax, [4B86A4]	// cur_iy
	imul ebx, eax, #11
	add ebx, ecx	// ebx=cur_i
	inc eax
	mul byte ptr [esp]	// (iy+1)*tileSize
	shl eax, 10	// HIWORD(eax)=y
	mov al, cl
	mul byte ptr [esp]	// LOWORD(eax)=ix*tileSize
	mov ecx, eax	// xy
	mov edx, ebx	// i
	mov eax, edi	// TSW_mBitmap_hDC
	call sub_dtl

	mov eax, [48C514]
	mov edx, [48C518]
	cmp eax, [esp+1C]	// TSW_cur_mBitmap
	cmove eax, edx	// TSW_nxt_mBitmap
	call 41DAD8	// TBitmap_GetCanvas
	call 41A950	// TCanvas_GetHandle
	mov ebp, eax	// TSW_mBitmap2_hDC

	mov edx, 48C580	// p_prev_i
	mov eax, [edx]	// prev_i
	mov [edx], ebx	// prev_i=cur_i
	cmp al, #121
	jae +32
	cmp eax, ebx
	jz +2E
	mov bh, al	// store i
	mov cl, #11
	div cl	// ix+iy*11=i
	inc eax	// al=++iy
	mov cl, ah	// cl=ix
	mul byte ptr [esp]	// tileSize
	shl eax, 10	// HIWORD(eax)=y
	mov al, cl
	mul byte ptr [esp]	// LOWORD(eax)=x
	mov esi, eax	// store xy
	mov ecx, eax	// xy
	mov dl, bh	// i
	mov eax, edi	// TSW_mBitmap_hDC
	call sub_dtl
	mov ecx, esi
	mov dl, bh
	mov bh, 0
	mov eax, ebp	// TSW_mBitmap2_hDC
	call sub_dtl

	mov edx, 48C584	// p_next_i
	mov eax, [edx]	// next_i
	mov [edx], ebx	// next_i=cur_i
	cmp al, #121
	jae +5F	// loc_dmp_draw
	sub ebx, eax	// cur_i-next_i
	mov edx, [4B86A0]	// cur_ix
	dec ebx
	jne +4	// cur_i-next_i==1
	test edx, edx
	jne +13
	inc ebx
	inc ebx
	jne +5	// next_i-cur_i==1
	cmp edx, #10
	jne +0A
	cmp ebx, #11
	je +5
	cmp ebx, #-11
	jne +3D	// loc_dmp_draw

	imul edx, [4B8698], #123
	cmp byte ptr [eax+edx+4B8934+2], 6
	jne +2C	// loc_dmp_draw
	mov ebx, eax	// store i
	mov cl, #11
	div cl	// ix+iy*11=i
	inc eax	// al=++iy
	mov cl, ah	// cl=ix
	mul byte ptr [esp]	// tileSize
	shl eax, 10	// HIWORD(eax)=y
	mov al, cl
	mul byte ptr [esp]	// LOWORD(eax)=x
	mov esi, eax	// store xy
	mov ecx, eax	// xy
	mov edx, ebx	// i
	mov eax, edi	// TSW_mBitmap_hDC
	call sub_dtl
	mov ecx, esi
	mov edx, ebx
	mov eax, ebp	// TSW_mBitmap2_hDC
	call sub_dtl

	loc_dmp_draw:
	pop esi	// TSW_tileSize
	imul esi, esi, #11	// TSW_mapSize
	pop eax	// TTSW10_TCanvas
	call 41A950	// TCanvas_GetHandle
	push 00CC0020
	push 0
	push 0
	push edi	// TSW_mBitmap_hDC
	push esi
	push esi
	push [48C57C]	// TSW_map_top
	push [48C578]	// TSW_map_left
	push eax
	call 404C5C	// BitBlt
	pop ebx
	pop esi
	pop edi
	pop ebp
	ret 4
	nop


sub_ini:	// eax=[IN]HANDLE TTSW10
	push edi
	push esi
	push ebx
	mov eax, [eax+0120]
	call 41A950	// TCanvas_GetHandle
	mov esi, eax	// TTSW10_TCanvas_hDC
	push eax
	call 404C84	// CreateCompatibleDC
	mov [4BA1B8], eax	// hMemDC
	mov edi, eax	// hMemDC
	xor eax, eax
	// use 16-byte stack space for temporary pointer for LOGPEN structure
	push [4BA234]	// LOGPEN.lopnColor=color_background
	push eax	// LOGPEN.lopnWidth.y=0
	push 3	// LOGPEN.lopnWidth.x=3
	push eax	// LOGPEN.lopnStyle=PS_SOLID
	push esp
	call 404CA4	// CreatePenIndirect
	mov [4BA1C4], eax	// hPen_stroke
	mov eax, [4BA230]	// color_polyline
	mov [esp+0C], eax	// LOGPEN.lopnColor=color_polyline
	push esp
	call 404CA4	// CreatePenIndirect
	mov [4BA1C8], eax	// hPen_polyline
	add esp, 10	// balance stack
	push 4BA1FC	// p_lfont_dmg
	call 404C94	// CreateFontIndirectA
	mov [4BA1CC], eax	// hFont_dmg
	push 4BBC5E	// "gdi32.dll"
	call 4012B0	// GetModuleHandleA
	push 489DF0	// "SetDCBrushColor"
	push eax
	push 4BA1F0	// "StrokePath"
	push eax
	push 4BA1E8	// "EndPath"
	push eax
	push 4BA1DC	// "BeginPath"
	push eax
	call 404B84	// GetProcAddress
	mov [4BA1D0], eax	// FARPROC BeginPath
	call 404B84
	mov [4BA1D4], eax	// FARPROC EndPath
	call 404B84
	mov [4BA1D8], eax	// FARPROC StrokePath
	call 404B84
	mov [489DEC], eax	// FARPROC SetDCBrushColor
	push #18	// DC_BRUSH
	call 404D44	// GetStockObject
	mov [48A6DC], eax	// was NULL_BRUSH, assigned in _Unit8.InitGraphics, now used to store DC_BRUSH
	xor ebx, ebx
	inc ebx	// i=1/0

	loc_ini_loop:
	push #480
	push #440
	push esi	// TTSW10_TCanvas_hDC
	call 404C7C	// CreateCompatibleBitmap
	mov [ebx*4+4BA1BC], eax	// hMemBmp[TSW_cur_frame]
	push eax
	push edi	// hMemDC
	call 404DCC	// SelectObject
	mov eax, [ebx*4+48C514]	// pTBitmap[i]
	call 41DAD8	// TBitmap_GetCanvas
	call 41A950	// TCanvas_GetHandle
	xor edx, edx	// edx=0
	mov ecx, #440
	push 00CC0020
	push edx
	push edx
	push eax	// TSW_mBitmap_hDC
	push ecx
	push ecx
	push edx
	push edx
	push edi	// hMemDC
	call 404C5C	// BitBlt
	dec ebx
	je loc_ini_loop

	or byte ptr [4BA1B6], 3	// need_update: always update map
	mov byte ptr [4BA1B5], 1
	pop ebx
	pop esi
	pop edi
	ret


sub_res:	// void sub_res(void)
// sub_res is called when the damage overlay function is no longer needed
// sub_fin is called when TSW quits
// the difference is that sub_fin does not need to restore the two game map bitmaps (i.e. no need to BitBlt as is done in `sub_restoreGameBitmaps`)
// this subtle difference has not yet been implemented in 'dmg.dll.c'
	mov byte ptr [4BA1B5], 0
	push loc_fin_no_check	// will continue to execute `sub_restoreGameBitmaps` below and then `ret` to this address, i.e., disposing of all GDI objects


sub_restoreGameBitmaps:	// void sub_restoreGameBitmaps(void)
	push ebx
	xor ebx, ebx
	inc ebx	// i=1/0

	loc_res_loop:
	mov eax, [ebx*4+48C514]	// pTBitmap[i]
	call 41DAD8	// TBitmap_GetCanvas
	call 41A950	// TCanvas_GetHandle
	mov edx, [4BA1B8]	// hMemDC
	mov ecx, #440
	push 00CC0020
	push 0
	push 0
	push edx
	push ecx
	push ecx
	push 0
	push 0
	push eax	// TSW_mBitmap_hDC
	push [ebx*4+4BA1BC]	// hMemBmp[TSW_cur_frame]
	push edx	// hMemDC
	call 404DCC	// SelectObject
	call 404C5C	// BitBlt
	dec ebx
	je loc_res_loop
	pop ebx
	ret


sub_fin:	// void sub_fin(void)
	cmp byte ptr [4BA1B5], 0
	je +31	// loc_fin_ret
	loc_fin_no_check:
	push esi
	mov esi, 4BA1B8	// p_hMemDC
	push 0
	push 0
	push [esi]
	call 404C7C	// CreateCompatibleBitmap
	push eax
	push [esi]
	call 404DCC	// SelectObject
	cld
	lodsd
	push eax
	call 404CBC	// DeleteDC
	loc_fin_loop:
	lodsd
	push eax
	call 404CCC	// DeleteObject
	cmp esi, 4BA1CC	// p_hFont_dmg
	jbe loc_fin_loop
	pop esi
	loc_fin_ret:
	ret
	nop


sub_itoa2:	// ax=[IN]WORD i; edx=[IN/OUT]char* a; return int len
	xor ecx, ecx	// now ecx=0
	cmp ax, FFFF
	jne +0A	// loc_itoa2_num_digits
	mov [edx], 3F3F3F	// "???"
	lea eax, [ecx+3]	// return len=0+3=3
	ret

	loc_itoa2_num_digits:
	cmp ax, #10
	jb +16	// loc_itoa2_get_digits
	inc ecx	// 1
	cmp ax, #100
	jb +0F	// loc_itoa2_get_digits
	inc ecx	// 2
	cmp ax, #1000
	jb +08	// loc_itoa2_get_digits
	inc ecx	// 3
	cmp ax, #10000
	jb +01	// loc_itoa2_get_digits
	inc ecx	// 4

	loc_itoa2_get_digits:
	push ecx	// len-1
	push ebx
	lea ebx, [edx+ecx]	// *a[len-1]
	mov cl, 0A	// cx=10
	loc_itoa2_loop:
	xor edx, edx
	div cx
	add edx, 30
	mov [ebx], dl
	dec ebx
	test ax, ax
	jnz loc_itoa2_loop

	pop ebx
	pop eax
	inc eax	// return len
	ret
	db 0f, 1f, 00	// 3-byte nop


sub_getMonsterID:	// al=[IN]UCHAR tileID; return char ID
	mov dl, -2
	cmp al, #08
	jb +2D	// loc_getMonsterID_ret

	cmp al, #61
	jae +07
	cmp al, #29
	jae +25	// loc_getMonsterID_ret
	mov al, -1
	ret

	cmp al, #97
	jae +05
	sub al, #61
	shr al, 1
	ret

	mov dl, #18
	cmp al, #106
	jb +13	// loc_getMonsterID_ret
	inc edx	// #19
	cmp al, #122
	je +0E	// loc_getMonsterID_ret

	lea edx, [eax-5D]	// al-93
	shr dl, 1
	sub al, #133
	cmp al, #26	// [133, 133+26)
	mov al, -01	// otherwise set dl as -1
	cmovae edx, eax

	loc_getMonsterID_ret:
	mov al, dl
	ret
	xchg ax, ax	// 2-byte nop


sub_getMonsterDmgCri:	// al=[IN]BYTE monsterID; edx=[IN]BOOL isStrikeFirst=0/1; return DWORD: HIWORD=cri LOWORD=dmg
	push ebp
	push edi
	push esi
	push ebx
	sub esp, 0C	// [esp]=BYTE hATKDouble; [esp+04]=int mHP; [esp+08]=DWORD isStrikeFirst
	mov [esp+08], edx
	mov ebp, [4B8904]	// factor
	inc ebp
	mov ebx, [4B868C]	// player's ATK
	movzx edx, al
	shl edx, 04
	lea esi, [edx+489910]	// pointer to monster's HP/ATK/DEF
	mov edi, [esi+8]	// monster's DEF
	imul edi, ebp

	lea ecx, [eax-0C]	// al-12
	cmp cl, 02	// [12, 2+12)
	jb +4

	cmp al, #17
	jne +0C

	cmp [4B86D8], 1	// Cross
	sete al
	jmp +11

	cmp [4B86F4], 1	// DragonSlayer
	sete cl
	cmp al, #19
	sete al
	and eax, ecx

	mov [esp], al	// hATKDouble

	mov ecx, ebx
	sub ecx, edi
	test ecx, ecx
	jg +1F

	mov eax, ecx
	neg eax
	xor edx, edx
	div ebp
	inc eax
	mov edx, 7FFF
	cmp eax, edx
	cmova eax, edx
	or ah, 80
	mov cx, FFFF
	jmp sub_getMonsterDmgCri_end

	cmp byte ptr [esp], 0	// hATKDouble
	je +2
	add ecx, ebx

	mov eax, [esi]
	imul ebp
	mov [esp+04], eax	// mHP
	test eax, eax
	jle +5
	dec eax
	xor edx, edx
	div ecx

	mov ecx, [esi+04]
	mov esi, eax	// esi=turnsCount
	imul ecx, ebp
	xor eax, eax
	sub ecx, [4B8690]
	cmovs ecx, eax	// ecx=oneTurnDmg
	mov eax, [esp+08]
	add eax, esi	// turnsCount++ if isStrikeFirst
	imul ecx, eax	// ecx=dmg
	mov eax, 7FFF	// cri=0x7FFF (no show) if dmg==0
	test ecx, ecx
	jz +47	// sub_getMonsterDmgCri_end

	test esi, esi
	jz +1A

	mov eax, [esp+04]	// mHP
	dec eax
	xor edx, edx
	div esi
	add eax, edi
	cmp byte ptr [esp], 0	// hATKDouble
	je +2
	shr eax, 1
	sub eax, ebx
	xor edx, edx
	div ebp
	inc eax	// eax=cri

	mov ebx, 7FFF
	cmp eax, ebx
	cmovb ebx, eax	// ebx=cri
	cmp ecx, [4B8688]
	jb +3
	or bh, 80
	lea eax, [ecx-01]
	xor edx, edx
	div ebp
	inc eax	// eax=dmg
	mov ecx, FFFF
	cmp eax, ecx
	cmovb ecx, eax	// ecx=dmg
	mov eax, ebx	// eax=cri

	sub_getMonsterDmgCri_end:
	shl eax, 10
	mov ax, cx
	add esp, 0C
	pop ebx
	pop esi
	pop edi
	loc_dtl_ret:	// this will be used for quick return by `sub_dtl` below
	pop ebp
	ret


sub_dtl:	// eax=[IN]HDC hDC; dl=[IN]char i; ecx=[IN]DWORD xy
	push ebp
	mov ebp, edx
	and ebp, 7F
	mov ebp, [ebp*4+489C00]	// ebp=dmgCri
	cmp ebp, -2
	je loc_dtl_ret

	push edi
	push esi
	push ebx
	sub esp, 20
	mov ebx, eax	// ebx=hDC
	movzx esi, cx	// esi=DWORD x
	shr ecx, 10
	mov edi, ecx	// edi=DWORD y
	push ebp	// [esp+2]=WORD cri (with its most significant bit indicating whether to show as red color or not)
	and byte ptr [esp+3], 7F	// [esp+2]=WORD cri (0-7FFF; without most significant bit)
	shr dl, 7
	mov [esp], dl	// [esp]=BYTE bypassSelectObject
	// [esp+4]=HPEN hPen_old; [esp+8]=HFONT hFont_old; [esp+C]=char strInt1[8]; ebp will be int lenInt1 in the future
	// for normal dmg: [esp+14]=char strInt2[8]; [esp+1C]=int lenInt2
	// for magic dmg:  [esp+14]=RECT cell (16 bytes)
	// the total assigned stack size is 16(ebx/esi/edi/ebp)+36 bytes

	test ebp, ebp	// bp=WORD dmg
	js +0B
	push 0D	// R2_COPYPEN
	push ebx
	push [4BA238]	// FFFFFF; white color
	jmp +09
	push 10	// R2_WHITE
	push ebx
	push [4BA228]	// 2222FF; red color
	push ebx
	call 404E04	// SetTextColor
	call 404DF4	// SetROP2

	cmp byte ptr [esp], 0	// bypassSelectObject
	jne +28
	push 01	// TRANSPARENT
	push ebx
	call 404DE4	// SetBkMode
	push [4BA1C4]	// hPen_stroke
	push ebx
	call 404DCC	// SelectObject
	mov [esp+4], eax	// store hPen_old
	push [4BA1CC]	// hFont_dmg
	push ebx
	call 404DCC	// SelectObject
	mov [esp+8], eax	// store hFont_old

	push ebx
	call [4BA1D0]	// BeginPath
	mov eax, ebp
	lea edx, [esp+0C]
	call sub_itoa2
	lea edx, [esp+0C]	// edx=char* strInt1
	mov ebp, eax	// ebp=lenInt1
	cmp word ptr [esp+2], 0	// cri (if cri==0, it means it's magic dmg; otherwise, normal dmg)
	je +72	// loc_dtl_mag_dmg

	loc_dtl_norm_dmg:
	sub edi, #15
	inc esi
	push ebp
	push edx
	push edi
	push esi
	push ebx
	call 404E34	// TextOutA
	mov ax, [esp+02]	// cri
	cmp ax, 7FFF
	je +1E

	lea edx, [esp+14]
	call sub_itoa2
	mov [esp+1C], eax	// lenInt2
	lea edx, [esp+14]	// char* strInt2
	lea ecx, [edi-0C]	// y-12
	push eax
	push edx
	push ecx
	push esi
	push ebx
	call 404E34	// TextOutA

	push ebx
	call [4BA1D4]	// EndPath
	push ebx
	call [4BA1D8]	// StrokePath
	lea edx, [esp+0C]	// char* strInt1
	push ebp
	push edx
	push edi
	push esi
	push ebx
	call 404E34	// TextOutA
	cmp word ptr [esp+02], 7FFF
	je +5B	// loc_dtl_fin

	sub edi, 0C	// y-12
	lea edx, [esp+14]	// char* strInt2
	push [esp+1C]	// lenInt2
	push edx
	push edi
	push esi
	push ebx
	call 404E34	// TextOutA
	jmp +45	// loc_dtl_fin

	loc_dtl_mag_dmg:
	mov eax, [48C510]
	mov eax, [eax+0254]
	mov eax, [eax+2C]	// tileSize
	lea ecx, [esp+14]	// RECT* cell
	mov [ecx], esi	// cell.left
	mov [ecx+0C], edi	// cell.bottom
	sub edi, eax
	mov [ecx+04], edi	// cell.top
	add esi, eax
	mov [ecx+08], esi	// cell.right
	// argv for DrawTextA#2
	push 25	// DT_CENTER|DT_VCENTER|DT_SINGLELINE
	push ecx
	push ebp
	push edx
	push ebx
	// argv for StrokePath
	push ebx
	// argv for EndPath
	push ebx
	// argv for DrawTextA#1
	push 25
	push ecx
	push ebp
	push edx
	push ebx
	// start calls
	call 404F0C	// DrawTextA
	call [4BA1D4]	// EndPath
	call [4BA1D8]	// StrokePath
	call 404F0C	// DrawTextA

	loc_dtl_fin:
	cmp byte ptr [esp], 0	// bypassSelectObject
	jne +14
	push [esp+04]	// hPen_old
	push ebx
	call 404DCC	// SelectObject
	push [esp+08]	// hFont_old
	push ebx
	call 404DCC	// SelectObject

	add esp, 24
	pop ebx
	pop esi
	pop edi
	pop ebp
	ret


sub_cmp:	// void cmp(void)
	push esi
	push ebx
	push eax	// this value is of no use; equivalent to `add esp, 04`
	// [esp]=int variant
	// for monster tile, [esp] is not used
	// for floor/door/item tile, esp=char adjacent[4] at first; later, [esp]=int factor
	xor ebx, ebx	// ebx=DWORD i; [0, 121)
	imul eax, [4B8698], #123
	lea esi, [eax+4B8934+2]	// char TSW_curFloor_tiles[121]

	loc_cmp_loop:
	mov al, [esi+ebx]	// al=mID
	call sub_getMonsterID
	test al, al
	jns loc_cmp_monster	// non-negative mID means a monster tile

	loc_cmp_checkMag:	// for floor/door/item, need to check if there is magic dmg on it
	inc al
	jz +9
	cmp [4B872C], 0	// have sacred shield or not
	je +23

	loc_cmp_update_trivial_tile:	// for tiles that should be markded as -2 (no dmg display)
	mov eax, -2
	loc_cmp_update:
	lea edx, [ebx*4+489C00]	// DWORD m_dmg_cri[121]
	cmp [edx], eax
	je +9	// loc_cmp_continue
	mov [edx], eax
	or byte ptr [4BA1B6], 3
	loc_cmp_continue:
	inc ebx
	cmp ebx, #121
	jne loc_cmp_loop
	pop eax	// this value is not useful, just serving to balance the stack
	pop ebx
	pop esi
	ret

	xor edx, edx
	mov [esp], edx	// now, esp=char adjacent[4]={0}
	mov eax, ebx
	mov dl, #11
	div dl
	mov ecx, eax	// ch=ix; cl=iy
	test ch, ch
	je +0C
	mov al, [esi+ebx-01]
	call sub_getMonsterID	// this subroutine only uses eax and edx, so the value of ecx will be retained; same below
	mov [esp], al

	cmp ch, 0A
	je +0D
	mov al, [esi+ebx+01]
	call sub_getMonsterID
	mov [esp+01], al

	test cl, cl
	je +0D
	mov al, [esi+ebx-0B]
	call sub_getMonsterID
	mov [esp+02], al

	cmp cl, 0A
	je +0D
	mov al, [esi+ebx+0B]
	call sub_getMonsterID
	mov [esp+03], al

	lea eax, [esp]	// eax=&(adjacent[j]) in the loop below (j=0/1/2/3)
	xor ecx, ecx	// ecx=total magic dmg
	loc_cmp_checkMag_loop:
	mov dl, [eax]
	cmp dl, #29
	jne +6
	add ecx, #200
	cmp dl, #30
	jne +3
	add ecx, #100
	inc eax
	lea edx, [esp+4]
	cmp edx, eax
	jne loc_cmp_checkMag_loop

	mov eax, [4B8904]
	lea edx, [eax+01]	// edx=int factor (1 or 44)
	imul ecx, edx
	mov eax, [4B8688]	// HP
	cmp word ptr [esp], 1010
	je +9
	cmp word ptr [esp+2], 1010
	jne +9

	test eax, eax
	jle +5
	inc eax
	shr eax, 1
	add ecx, eax

	mov [esp], edx	// store factor; now, [esp]=int factor
	test ecx, ecx
	je loc_cmp_update_trivial_tile
	xor edx, edx
	lea eax, [ecx-01]
	div [esp]
	inc eax	// eax=norm44(dmg)
	cmp ecx, [4B8688]
	setae dl
	shl edx, 1F	// most significant bit indicates whether to show as red color or not
	mov ecx, FFFF
	cmp ecx, eax
	cmovb eax, ecx
	or eax, edx
	loc_cmp_jmp_cmp_update:	// "jump transfer station" to save a few bytes
	jmp loc_cmp_update

	loc_cmp_monster:
	xor edx, edx	// only dl will be set later; clear all other bytes first; FALSE (0) by default
	mov ecx, [4B8698]	// floorID
	cmp ecx, #32	// [esp]=int floorID
	jne +0C
	cmp al, #20
	sete dl
	loc_cmp_getMonsterDmgCri:	// al=BYTE mID; edx=BOOL isStrikeFirst
	call sub_getMonsterDmgCri	// eax=DWORD dmgCri
	jmp loc_cmp_jmp_cmp_update
	// end of subroutine //

	cmp ecx, #50
	jne +17
	cmp [4B8904], edx	// edx=0
	je loc_cmp_getMonsterDmgCri	// isStrikeFirst=FALSE
	cmp [4B8908], edx	// edx=0
	jne loc_cmp_getMonsterDmgCri
	cmp al, #15
	sete dl
	jmp loc_cmp_getMonsterDmgCri

	cmp ecx, #40
	jne +14
	cmp byte ptr [esi+47], 07
	je loc_cmp_getMonsterDmgCri
	cmp byte ptr [esi+05], 0B
	je loc_cmp_getMonsterDmgCri
	cmp ebx, #77
	setb dl
	jmp loc_cmp_getMonsterDmgCri

	cmp ecx, #49
	jne +18
	cmp byte ptr [esi+3C], 07
	je loc_cmp_getMonsterDmgCri
	cmp ebx, #44
	jae loc_cmp_getMonsterDmgCri
	loc_cmp_checkIsInEvent:
	cmp [48C5AC], edx	// edx=0
	jle loc_cmp_getMonsterDmgCri
	jmp loc_cmp_continue

	cmp ecx, #20
	jne loc_cmp_getMonsterDmgCri
	cmp byte ptr [esi+52], 07
	je loc_cmp_getMonsterDmgCri
	cmp al, #17
	je loc_cmp_checkIsInEvent
	jmp loc_cmp_getMonsterDmgCri
	xchg ax, ax	// 2-byte nop


sub_getHighlightSquare:	// eax=[OUT]int square[4] {x, y, w, h}
	mov edx, [48C510]
	mov edx, [edx+0254]
	mov edx, [edx+2C]
	mov [eax+08], edx
	mov [eax+0C], edx
	shr edx, 1
	mov ecx, [489E00]
	sub ecx, edx
	mov [eax], ecx
	mov ecx, [489E04]
	sub ecx, edx
	mov [eax+04], ecx
	loc_drawConnectivityOnBitmap_ret:	// this will be used for quick return by `drawConnectivityOnBitmap` below
	ret
	db 0f, 1f, 00	// 3-byte nop


sub_drawConnectivityOnBitmap:	// eax=HANDLE TSW_cur_mBitmap; return edi=HDC TSW_mBitmap_hDC
// in this subroutine, ebx/esi/edi/ebp values will change, because in the caller subroutine, these registers are vacant up to this point (this has not been implemented in 'dmg.dll.c')
	call 41DAD8
	call 41A950
	mov edi, eax	// TSW_mBitmap_hDC
	movzx ebp, byte ptr [48C5D2]	// TSW_cur_frame
	lea ebx, [ebp+ebp+2]	// test_bit
	mov al, [489DE4]	// polyline_state
	test al, bl
	jnz loc_drawConnectivityOnBitmap_ret
	test al, 6
	jnz +28

	mov edx, [48C578]	// TSW_map_left
	mov ecx, [48C57C]	// TSW_map_top
	mov esi, 489E00	// p_polyline_vertices
	mov al, [489DE5]
	and eax, 3F	// seg_count
	lea eax, [eax*8+esi]
	loc_drawConnectivityOnBitmap_loop:
	sub [esi], edx
	sub [esi+4], ecx
	add esi, 8
	cmp eax, esi
	jae loc_drawConnectivityOnBitmap_loop

	or [489DE4], bl
	push 00CC0020	// rop @ BitBlt
	push ecx	// y1 @ BitBlt; need to be populated later
	push ecx	// x1 @ BitBlt; need to be populated later
	push edi	// hdcSrc @ BitBlt = TSW_mBitmap_hDC
	sub esp, 10	// x/y/w/h @ BitBlt; need to be populated later
	mov eax, esp
	call sub_getHighlightSquare	// fill values for x/y/w/h @ BitBlt
	pop ecx	// x1
	pop edx	// y1
	mov [esp+0C], ecx	// x1 @ BitBlt
	mov [esp+10], edx	// y1 @ BitBlt
	push #440	// y @ BitBlt
	push 0	// x @ BitBlt
	mov eax, [4BA1B8]	// hMemDC
	push eax	// hdc @ BitBlt
	push [4BA1BC+ebp*4]	// h @ SelectObject = hMemBmp[TSW_cur_frame]
	push eax	// hdc @ SelectObject
	call 404DCC	// SelectObject
	call 404C5C	// BitBlt
	mov eax, edi
	jmp +1F	// sub_drawConnectivityOnDC
	db 0f, 1f, 00	// 3-byte nop


sub_dpl:	// eax=[IN]HANDLE TTSW10
	mov byte ptr [4B86B8], 1
	mov byte ptr [489DE4], 1
	mov eax, [eax+0120]
	call 41A950	// TCanvas.GetHandle
	db 0f, 1f, 00	// 3-byte nop
	// will continue to execute `sub_drawConnectivityOnDC` below


sub_drawConnectivityOnDC:	// eax=[IN]HDC hDC
	push ebx
	mov ebx, eax

	push ecx	// h @ SelectObject#2; need to be populated later
	push eax	// hdc @ SelectObject#2

	push 00FA0089 // rop @ PatBlt
	sub esp, 10	// x/y/w/h @ PatBlt; need to be populated later

	movzx eax, byte ptr [489DE5]
	shr al, 6
	push [4BA220+eax*4]	// color @ SetDCBrushColor
	push ebx	// hdc @ SetDCBrushColor
	call [489DEC]	// SetDCBrushColor

	mov eax, esp
	call sub_getHighlightSquare	// fill values for x/y/w/h @ PatBlt

	push [48A6DC]	// h @ SelectObject#1
	push ebx
	call 404DCC	// SelectObject#1

	mov [esp+18], eax	// fill value for h @ SelectObject#2
	push ebx	// hdc @ PatBlt
	call 404D8C	// PatBlt
	call 404DCC	// SelectObject#2

	mov eax, ebx
	pop ebx
	xchg ax, ax	// 2-byte nop
	// will continue to execute `sub_drawPolylineOnDC` below


sub_drawPolylineOnDC:	// eax=[IN]HDC hDC
	mov dl, [489DE5]
	and dl, 3F
	jz +2F	// ret

	movzx edx, dl
	inc edx

	push ecx	// h @ SelectObject#2; need to be populated later
	push eax	// hdc @ SelectObject#2

	push edx	// cpt @ Polyline
	push 489E00	// apt @ Polyline
	push eax	// hdc @ Polyline

	push [4BA1C8]	// h @ SelectObject#1
	push eax	// hdc @ SelectObject#1

	push 07	// rop2 @ SetROP2
	push eax	// hdc @SetROP2

	call 404DF4	// SetROP2
	call 404DCC	// SelectObject#1

	mov [esp+10], eax	// fill value for h @ SelectObject#2
	call 404D9C	// Polyline
	call 404DCC	// SelectObject#2
	ret
	nop


sub_epl:	// eax=[IN]HANDLE TTSW10
	push ebp
	push edi
	push esi
	push ebx
	mov ecx, [eax+0254]	// TTSW10.Image6
	mov esi, [ecx+2C]	// TSW_tileSize
	mov eax, [eax+0120]
	call 41A950	// TCanvas.GetHandle
	mov ebp, eax	// TTSW10_TCanvas_hDC
	xor ebx, ebx
	inc ebx	// i=1/0

	loc_epl_loop:
	mov eax, [ebx*4+48C514]	// pTBitmap[i]
	call 41DAD8	// TBitmap.GetCanvas
	call 41A950	// TCanvas.GetHandle
	mov edi, eax	// TSW_mBitmap_hDC

	lea edx, [ebx+ebx+2]	// test_bit
	test [489DE4], dl	// polyline_state
	je +37	//loc_drawTFormCanvas

	call sub_drawPolylineOnDC
	push 00CC0020	// rop @ BitBlt
	push #440	// y1 @ BitBlt
	push 0	// x1 @ BitBlt
	push [4BA1B8]	// hdcSrc @ BitBlt = hMemDC
	sub esp, 10	// x/y/w/h @ BitBlt; need to be populated later
	mov eax, esp
	call sub_getHighlightSquare	// fill values for x/y/w/h @ BitBlt
	push edi	// hdc @ BitBlt = TSW_mBitmap_hDC
	mov ecx, 4BA1B8
	push [ebx*4+ecx+4]	// h @ SelectObject = hMemBmp[TSW_cur_frame]
	push [ecx]	// hdc @ SelectObject = hMemDC
	call 404DCC	// SelectObject
	call 404C5C	// BitBlt
	loc_drawTFormCanvas:
	cmp [48C5D2], bl	// TSW_cur_frame
	jne +1F

	imul esi, esi, #11	// esi=TSW_tileSize
	push 00CC0020
	push 0
	push 0
	push edi	// TSW_mBitmap_hDC
	push esi
	push esi
	mov ecx, 48C57C
	push [ecx]
	push [ecx-4]
	push ebp	// TTSW10_TCanvas_hDC
	call 404C5C	// BitBlt

	dec ebx
	je loc_epl_loop
	mov byte ptr [4B86B8], 0
	mov byte ptr [489DE4], 0
	pop ebx
	pop esi
	pop edi
	pop ebp
	ret
