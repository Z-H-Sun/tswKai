; extension functions realized in addition to those achieved in the 'tswMPExt' subfolder
; the assembly codes here can be loaded by CheatEngine's auto-assembler; before doing so, replace all semicolons (;) with double slashes (//) as CheatEngine won't recognize simicolons as comments
; use CheatEngine 6.7. Higher versions are known to have bugs in auto-assembler, which tend to use longer opcodes for some specific assembly operations, and that will mess up everything

;;;;;;;;;; Fix a bug when player moves to/from an animated tile ;;;;;;;;;;
; this is impossible unless you use a game mod such as tswMP, so not a particularly serious bug
; however, if you use tswMP to move to/from an animated tile, such as a monster, lava, etc.
; that animated tile will become static (non-animated), which is because in the following subroutines:
; TTSW10.yusyai1/i2/i3/i4/hyouji, it is always the first of the two "oscillating" image will be drawn
; onto both game bitmaps. Actually, on the second game bitmap, another different image, whose new index
; can becalculated using TTSW10.imagework, should be drawn instead

443EDA:	; part of TTSW10.yusyai1 [yuusya=rōmaji of 勇者; hero], which draws hero overlay moving down
; this subroutine is called by TTSW10.yusyaidou [rōmaji of 勇者移動; movement of hero]
; basically, it will draw a 40*80 (or 32*64) TBitmap @ [0x48C51C], containing the two tiles during the hero moves down
; which will then be copied to one of the two game bitmaps at the desired coordinate
; first off, before drawing the hero overlay the underlying two tiles need to be drawn first
	xor eax, eax	; Y=eax=0
	mov ecx, eax	; X=ecx=0
	cdq	; dI=edx=0
	push loc_yusyai1_draw_underlying_tile_2
	; will continue to execute `sub_draw_underlying_tile`, which draws the first tile at the same location as the player to (0,0) of the 40*80 (or 32*64) TBitmap
	; then, upon `ret`, will go to `loc_yusyai1_draw_underlying_tile_2`, which draws the second tile; see below
; 443EE4:
	sub_draw_underlying_tile:	; eax=[IN] int Y; ecx=[IN] int X; dl=[IN] char dI; ebx=[IN] HANDLE TTSW10; esi=[IN] HANDLE 0x48C51C; edi=[IN] HANDLE 0x4B8688 (hero's status)
	push eax ; Y of drawing location onto TBitmap @ 48C51C
	; ecx = X of drawing location onto TBitmap @ 48C51C, which is already provided when passing argv
	imul eax, [edi+1C], #11	; iy=[0x4B86A4]
	add eax, [edi+18]	; ix=[0x4B86A0]
	add al, dl	; I=11*iy+ix+dI (dI is the difference of index of the target tile w.r.t hero's current position)
	imul edx, [edi+10], #123	; 123*[0x4B8698] (floorID; each floor contains 121+2 bytes of tile info)
	mov al, [eax+edx+4B8934+2]	; TSW_tileID[I], the tile ID of the target
	mov [48C5A8], eax	; this is the input for TTSW10.imagework, which calculates the image index in the second "oscillating" frame and stores the index difference in [48C554]
	dec eax	; -1 because the index in the image list is zero-based
	push eax	; I
	push ecx	; store X

	; in the original function, it is always the first of the two "oscillating" tile image that will be drawn
	; however, this should only be true for the first of the two game bitmaps; for the second game bitmap, the tile image index should be provided by calculation in TTSW10.imagework
	; to tell whether it is the first or the second game bitmap that TTSW10.yusyaidou is drawing, TSW assigns [48C554] to 0 or 1
	; although for some reason, in the original function, this was not used; here, we will make use of this variable to judge which frame to draw
	cmp [esi+38], 0	; 48C554; 0=will be copied to first bitmap; 1=copied to second game bitmap
	je +0C
	call 454C10	; TTSW10.imagework, which calculates the image index in the second "oscillating" frame and stores the index difference in [48C554]
	mov eax, [esi+38]	; 48C554, the index difference of the second-frame tile w.r.t the first-frame tile
	add [esp+4], eax	; modify I (which was pushed on stack) according to this index difference

	mov eax, [esi]	; 48C51C
	call 41DAD8	; TBitmap.GetCanvas; eax=TBitmapCanvas (dest)
	mov edx, [ebx+1B0]	; TTSW10.ImageList1
	xchg eax, edx	; eax=TTSW10.ImageList1 (src); edx=TBitmapCanvas (dest)
	pop ecx	; ecx=X
	call 417E44	; TCustomImageList.Draw
	ret
; 443F28:
	loc_yusyai1_draw_underlying_tile_2:	; now, will draw the second tile below the player (dI=+11) to (0,40) of the 40*80 TBitmap (or, (0,32) of 32*64 TBitmap)
	mov eax, [ebx+254]	; TTSW10.Image6
	mov eax, [eax+2C]	; Y=TSW_tileSize (40 or 32)
	xor ecx, ecx	; X=0
	mov dl, #11	; dI=+11 (the tile right below the player)
	call sub_draw_underlying_tile
	jmp 443F45	; continue


443CFE:	; part of TTSW10.yusyai2, which draws hero overlay moving left
; like above, this subroutine is also called by TTSW10.yusyaidou; basically, it will draw a 80*40 (or 64*32) TBitmap @ [0x48C51C], containing the two tiles during the hero moves left
	xor eax, eax	; Y=0
	mov ecx, [ebx+254]
	mov ecx, [ecx+2C]	; X=40 or 32
	mov edx, eax	; dI=0
	call sub_draw_underlying_tile	; draw player's tile @ (40/32, 0)
	xor eax, eax	; Y=0
	mov ecx, eax	; X=0
	mov dl, -1	; dI=-1 (the tile left to the player)
	call sub_draw_underlying_tile	; draw the tile left to the player @ (0,0)
	jmp 443D68	; continue


443B2A:	; part of TTSW10.yusyai3, which draws hero overlay moving right
; like above, this subroutine is also called by TTSW10.yusyaidou; basically, it will draw a 80*40 (or 64*32) TBitmap @ [0x48C51C], containing the two tiles during the hero moves right
	xor eax, eax	; Y=0
	mov ecx, eax	; X=0
	mov edx, eax	; dI=0
	call sub_draw_underlying_tile	; draw player's tile @ (0, 0)
	xor eax, eax	; Y=0
	mov ecx, [ebx+254]
	mov ecx, [ecx+2C]	; X=40 or 32
	mov dl, 1	; dI=+1 (the tile right to the player)
	call sub_draw_underlying_tile	; draw the tile right to the player @ (40/32,0)
	jmp 443B94	; continue


4441DF:	; part of TTSW10.yusyai4, which draws hero overlay moving up
; like above, this subroutine is also called by TTSW10.yusyaidou; basically, it will draw a 40*80 (or 32*64) TBitmap @ [0x48C51C], containing the two tiles during the hero moves up
	mov eax, [ebx+254]
	mov eax, [eax+2C]	; Y=40 or 32
	xor ecx, ecx	; X=0
	mov edx, ecx	; dI=0
	call sub_draw_underlying_tile	; draw player's tile @ (0, 40/32)
	xor eax, eax	; Y=0
	mov ecx, eax	; X=0
	mov dl, #-11	; dI=-11 (the tile right above the player)
	call sub_draw_underlying_tile	; draw the tile right above the player @ (0,0)
	jmp 44424A	; continue


443767:	; part of TTSW10.yusyahyouji [rōmaji of 勇者表示; display of hero], which will draw a 40*40 (or 32*32) TBitmap @ [0x48C51C] with hero overlay
; again, before drawing the hero overlay, the underlying tile will be drawn first, and originally, only the first of the two tile frame will always be drawn
; the patches above fixes the bug when the player moves from an animated tile
; here we begin to deal with the bug when the player moves to or teleports to an animated tile
	mov edi, 4B8688	; edi is vacant now, we can use it without the need of `push edi`
	xor eax, eax
	mov ecx, eax
	mov edx, eax
	call sub_draw_underlying_tile	; draw player's tile @ (0,0)
	jmp 4437A0	; continue



;;;;;;;;;; Update hero overlay faster and more efficiently ;;;;;;;;;;
; previously, tswMP will call TTSW10.mhyouji to update player's position, and call TTSW10.Timer1Timer *3 times to update game bitmap after an event is over
; however, there are several drawbacks in doing so
; the two new subroutines below are therefore designed in replacement of the old treatments

480834:
; originally part of TTSW10.monidou; but the space has been saved by rewriting the treatments there (see tswMPExt_2.asm for more details)
; as a result, 480834 through to 480A28 is vacant and can be used to insert our own codes

sub_erase_and_draw_hero:	; this will erase the hero overlay in the old position (by redrawing that tile) and draw hero overlay in the new position
; the previous treatment was to call TTSW10.mhyouji, which has the following problems
; - mhyouji will only update the two game bitmaps, and won't draw the hero overlay, so in certain cases, there will be 3 Timer1 intervals when no hero overlay is visible (2 intervals for drawing the two game bitmaps, and 1 additional interval for drawing onto game window canvas)
; - mhyouji will update all tiles on the map (not necessary and requiring more resources), and will alwasy ask `sub_dmp` to update all damage overlay (see tswMPExt_2.asm), which is not necessary and requires more resources and will cause flickering of damage overlay
	push ebx
	mov ebx, eax

	mov eax, [eax+254]	; Image6
	mov ecx, [eax+2C]	; tileSize

	mov eax, [48C514]	; game bitmap #0
	call 41DAD8	; TBitmap.GetCanvas
	mov edx, eax	; TBitmapCanvas (dest)

	mov eax, [48C580]	; player's previous location i_old = 11*iy_old+ix_old
	mov ch, #11
	div ch
	mov ch, ah	; store ix_old
	mul cl	; al=iy_old
	push eax	; store y=tileSize*iy_old
	mov al, ch
	mul cl
	mov ecx, eax	; x=tileSize*ix_old

	imul eax, [4B8698], #123	; floorID*123 (each floor contains 121+2 bytes of tile data)
	add eax, [48C580]
	movzx eax, [eax+4B8934+2]	; tsw_tileID[i_old]
	mov [48C5A8], eax; this is the input for TTSW10.imagework, which calculates the image index in the second "oscillating" frame and stores the index difference in [48C554]
	dec eax	; -1 because the index in the image list is zero-based
	push eax	; store i
	push ecx	; store x
	push [esp+8]	; y
	push eax	; i
	mov eax, [ebx+1B0]	; TTSW10.ImageList1 (src)
	call 417E44	; TCustomImageList.Draw

	; above: erase the hero overlay in the old position (by redrawing that tile) for game bitmap #0
	; below: do the same thing for game bitmap #1
	call 454C10	; TTSW10.imagework
	mov eax, [48C518]	; game bitmap #1
	call 41DAD8	; TBitmap.GetCanvas
	mov edx, eax; TBitmapCanvas (dest)

	pop ecx	; x
	; y already pushed on stack
	; i also pushed on stack, but need some modification
	mov eax, [48C554]	; the index difference of the second-frame tile w.r.t the first-frame tile
	add [esp], eax	; modify i (which was pushed on stack) according to this index difference
	mov eax, [ebx+1B0]	; ImageList1 (src)
	call 417E44	; TCustomImageList.Draw

	; so far, the two game bitmaps have been redrawn where no hero overlay is visible, which serves the same purpose as TTSW10.mhyouji
	; but without the need of redrawing the whole map nor refreshing all damage overlay
	; but under certain cases, e.g., go to talk to NPCs, because the player won't move immediately, the hero overlay must be drawn right away
	; otherwise, there will be 3 Timer1 intervals when no hero overlay is visible (see discussion at the beginning)
	; so, need to execute `sub_draw_hero` below
	jmp +4	; will continue on `sub_draw_hero`, but skip prolog (push ebx; mov ebx, eax)
	nop


; 4808B4:
sub_draw_hero:	; this will draw hero overlay on the map (and clear bottom status bar text, and if necessary, erase Octopus or Dragon tiles other than its head tile when you defeat it)
	push ebx
	mov ebx, eax
	xor edx, edx
	mov [48C58C], edx	; previously, if there was text in the bottom status bar before you teleport, tswMP will temporarily clear that text, but the text will reappear after you teleport, which is weird and incorrect; therefore, need to clear this variable (which is basically the index for the status bar text)
	push loc_draw_hero_on_canvas
	; will continue to execute `sub_draw_hero_on_game_bitmaps` below, but that only updates the two game bitmaps
	; in order to reflect the change immediately on the game window canvas, need to `ret` to loc_draw_hero_on_canvas afterwards

	sub_draw_hero_on_game_bitmaps:	; ebx=[IN]TTSW10_HANDLE
	mov eax, 443287	; part of TTSW10.Timer1Timer, which updates game bitmap #0 but without drawing it onto game window canvas (the corresponding code is prior to 443287)
	mov ecx, 44315F	; part of TTSW10.Timer1Timer, which updates game bitmap #1 but without drawing it onto game window canvas (the corresponding code is prior to 44315F)
	; by saying "update game bitmap," I mean:
	; - drawing the hero overlay (which calls TTSW10.yusyahyouji and copies [0x48C51C] onto the target game bitmap at the proper location)
	; - erasing Octopus or Dragon tiles other than its head tile when you just defeat it (which calls TTSW10.takowork1 for game bitmap #0 and TTSW10.takowork2 for game bitmap #1 [tako=rōmaji of 蛸; octopus, though it will also do the same thing for Dragon])
	cmp byte ptr [48C5D2], 0	; which frame is being updated: 0=game bitmap #0; 1=game bitmap #1
	je +1
	xchg eax, ecx	; both 443287 and 44315F will be called; generally, the calling order does not matter; however, it will cause a problem in the following cases:
	; - TTSW10.takowork1 has already been called once in Timer1, and now 443287 is called first which means takowork1 is called again
	; - TTSW10.takowork2 has already been called once in Timer1, and now 44315F is called first which means takowork2 is called again
	; in those cases, the Octopus or Dragon tiles in game bitmap #1 / game bitmap #0 won't be correctly erased, and you will see Octopus or Dragon (other than its head) flashing
	; this is because everytime takowork1 or takowork2 is called, [4B88E8] (for Octopus) / [4B88EC] (for Dragon) will be incremented by 1, and these calls will be ignored if the variable's value reaches 2, so if takowork1 is called twice consecutively, the takowork2 will never be called, and vice versa
	; so we must ensure that if [48C5D2] is 0 now, which means takowork1 might have been called, then 44315F must be called first prior to 443287, to make sure takowork2 is called first, and vice versa

	; below, we need to call both 443287 and 44315F to update both game bitmaps
	; since they are just snippets of Timer1Timer, without its prolog (push ebx; mov ebx, eax; push esi), we need to add the prolog manually here to balance the stack
	push ebx
	push esi
	push ecx	; will `ret` to 44315F or 443287 to update the next game bitmap
	push ebx
	push esi
	jmp eax	; go to 443287 or 44315F to update one of the two game bitmaps first
	nop

	loc_draw_hero_on_canvas:
	movzx eax, byte ptr [48C5D2]	; the current frame
	push [eax*4+48C514]	; will draw the corresponding game bitmap directly onto the game window canvas
	mov eax, [ebx+120]	; TFormCanvas of TTSW10
	mov edx, [48C578]	; x of game map (e.g. 180 in a 800x500 window)
	mov ecx, [48C57C]	; y of game map (e.g. 70 in a 800x500 window)
	call 4BA2F0	; sub_draw_map (see tswMPExt_2.asm; will jump to `sub_dmp` if `tswMPExt_enabled` or otherwise `TCanvas.Draw`)
	pop ebx
	ret
	nop

; 480908:
sub_draw_hero_2:
; the previous treatment was to call TTSW10.Timer1Timer *3 times
; (twice for drawing the two game bitmaps, and once more for drawing onto game window canvas)
; but by doing so, game bitmap drawing is done for 1 more time (in the last Timer1Timer call), and canvas drawing onto physical screen (slow if you don't have a good graphic card) is done for 2 more times (in the first two Timer1Timer calls), which is more time-consuming and requires more resources
; additionally, everytime you teleport, the frame will change (all animated tiles will change), which is weird...

; in most cases, sub_draw_hero is a good replacement, which only draws memory bitmap *2 plus physical screen *1 (instead of *3 + *3)
; however, when the player go up/down-stairs, you will see damage overlay flashing, i.e., the damage overlay is not properly drawn on one of the two game bitmaps
; this is because `sub_dmp` is not called in either 443287 nor 44315F, and it is only called once at the end of `sub_draw_hero`, so another game bitmap is not updated with new damage overlay
; thus, sub_draw_map has to be called for one more time at the end to ensure proper damage overlay on both game bitmaps, although at the cost of having to draw the physical screen for one more time (*2 + *2)
	push ebx
	mov ebx, eax
	call sub_draw_hero_on_game_bitmaps
	loc_draw_hero_on_canvas_2:	; so far the codes are identical with sub_draw_hero_2
	; will first draw the next game bitmap and then the current game bitmap onto screen, so that the frame will not change (all animated tiles stays still)
	mov eax, 48C514
	lea edx, [eax+4]
	xor byte ptr [48C5D2], 1	; `sub_dmp` needs to know the correct frame number to decide which game bitmap still needs drawing overlay
	cmovne eax, edx
	push [eax]
	mov eax, [ebx+120]
	mov edx, [48C578]
	mov ecx, [48C57C]
	call 4BA2F0	; sub_draw_map; draw the next game bitmap onto screen first
	xor byte ptr [48C5D2], 1
	jmp loc_draw_hero_on_canvas	; then draw the current game bitmap onto screen
