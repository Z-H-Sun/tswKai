; extension functions realized in addition to those achieved in the 'tswMPExt' subfolder
; the assembly codes here can be loaded by CheatEngine's auto-assembler; before doing so, replace all semicolons (;) with double slashes (//) as CheatEngine won't recognize simicolons as comments
; use CheatEngine 6.7. Higher versions are known to have bugs in auto-assembler, which tend to use longer opcodes for some specific assembly operations, and that will mess up everything

;;;;;;;;;; Execute arbitrary code from tswKai3 in TSW ;;;;;;;;;;
; basic idea on how this works: a windows msg from tswKai3 will be sent to TSW, mimicking menu-click event
; that menu item is a separator (horizontal dividing line, TTSW10.N9), which normally won't trigger a click event from user
; originally, that menu item does not have a callback function associated with it on click, but tswKai3 changes that prior to sending the msg
; so the sent msg will trigger the OnClick event and then execute the designated function
410680:
Menus_TMenuItem_Click:
; original opcodes:
;	cmp byte ptr [eax+29], 0	; Enabled
;	je loc_TMenuItem_Click	; do nothing if the menu item is disabled; however, this check is unnecessary as disabled menu item won't trigger this event by user
;	cmp word ptr [eax+92], 0	; don't know what it is. But `dword ptr [eax+90]` is the pointer to the callback function; if it is 0, obviously `word ptr [eax+92]` will also be 0
;	je loc_TMenuItem_Click	; do nothing if there is no associated callback function for the OnClick event
;	mov ecx, eax	; TMenuItem handle (not used in TSW)
;	mov edx, eax	; TMenuItem handle (not used in TSW)
;	mov eax, [ecx+94]	; TMenuItem owner handle, in this case, TTSW10 ([48C510])
;	call dword ptr [ecx+90]	; OnClick callback function
;	loc_TMenuItem_Click:
;	ret

; changes made below:
; for TTSW10.N9, a menu separator without an OnClick callback function, its [TMenuItem+0x90] is NULL, and its [TMenuItem+0x94] (owner handle) is also NULL
; we can make use of this characteristic feature. For normal menu click events, we know there must be an associated OnClick callback function, and its [TMenuItem+0x94] is defined
; we will then go with the old treatment. On the contrary, for TTSW10.N9, its [TMenuItem+0x94] is NULL, then we will do the following:
; a) get its owner handle, which is available in [TMenuItem+4] (this holds true for any control: [TControl+4] is its owner's handle)
; b) call [TMenuItem+0x90], which was set previously by tswKai3
; c) resetting [TMenuItem+0x90] as NULL before calling. Although it's unlikely that a user can trigger such OnClick event for this menu separator, but just to be safe
; patched opcodes:
	lea ecx, [eax+90]	; ecx = offset TMenuItem+0x90
	cmp [ecx], 0
	je 41067F	; ret (do nothing if OnClick callback function [TMenuItem+0x90] is NULL)
	mov edx, [eax+4]	; edx = [TMenuItem+4] (owner's handle)
	mov eax, [ecx+4]	; eax = [TMenuItem+0x94]
	test eax, eax	; for normal menu items, eax is its owner's handle, then call the associated function directly
	je +2	; otherwise, eax is 0, then need to do some extra work
	jmp [ecx]	; normal menu item
	xchg eax, edx	; after this exchange, eax=[TMenuItem+4]=owner's handle=[TTSW10]; edx=0
	xchg edx, [ecx]	; after this exchange, edx=[TMenuItem+0x90]=callback function; the latter will be reset to NULL just to be safe
	jmp edx	; call callback function

; other findings:
; for any TControl, [TControl+8] is the pointer to its name
; for menu item, [TMenuItem+0x20] is the pointer to its caption; for menu items with submenu, [TMenuItem+0x24] is hMenu (NULL if without submenu)



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


;;;;;;;;;; Below, subroutines used by tswExt ;;;;;;;;;;


;;;;;;;;;; Preparations before saving a temp data after using the "convience shop" function ;;;;;;;;;;
; when saving a temp data, temporarily teleport the player to the altar location
; so when you load that temp data, you knows the temp data was saved before you used the "convience shop"
; 480944:
sub_savetemp_prep:
	mov ecx, 4B8698	; floorID
	mov edx, 48C74C	; a vacant DWORD (used as TSW event sequence array (see discussions in tswBGM.asm); but the index starts from 1 not 0, so the first 6 bytes are vacant)
	; a temporary variable for hero's current floor / x / y / facing direction
	push [edx]	; save the current value, set by module Ext::Altar or Ext::Merchant, whose LOWORD = floorID of altar and HIWORD = index (11*y+x) of altar
	mov eax, [ecx]	; [floorID]
	mov [edx], al	; save player's current [floorID] to the 1st byte of temp var
	mov eax, [ecx+08]	; [X]
	mov [edx+1], al	; save player's current [X] to the 2nd byte of temp var
	mov eax, [ecx+0C]	; [Y]
	mov [edx+2], al	; save player's current [Y] to the 3rd byte of temp var
	mov eax, [4B87E8]	; [facing_direction]
	mov [edx+3], al	; save player's current [facing_direction] to the 4th byte of temp var

	pop word ptr [ecx]	; LOWORD, floorID of altar, assign to [floorID]
	pop ax	; HIWORD, index (11*y+x) of altar
	mov dl, 0B
	div dl	; al = y of altar; ah = x of altar
	mov [ecx+08], ah	; assign to [X]
	mov [ecx+0C], al	; assign to [Y]
	mov byte ptr [4B87E8], 4	; player facing up
	ret
	nop


;;;;;;;;;; Post processing after using the "convience shop" function ;;;;;;;;;;
; afterwards, teleport the player back to the current location
; and update the player's status display
; 480980:
sub_postprocess_1:
	mov ecx, 4B8698	; floorID
	mov edx, [48C74C]	; saved in `sub_savetemp_prep`
	mov [ecx], dl	; floorID = LOBYTE(LOWORD)
	mov [ecx+08], dh	; X = HIBYTE(LOWORD)
	shr edx, 10
	mov [ecx+0C], dl	; Y = LOBYTE(HIWORD)
	mov [4B87E8], dh	; facing_direction = HIBYTE(HIWORD)
	mov byte ptr [48C58C], 0	; clear status bar text
	jmp 44CB34	; TTSW10.disp (update player's status display)


;;;;;;;;;; Post processing after using the "clear monster" function ;;;;;;;;;;
; update the player's status display
; 4809A8:
sub_postprocess_2:
	push eax	; store eax=[TTSW10_HANDLE]
	call 442C38	; TTSW10.mhyouji (update map display; erase monsters)
	mov eax, [esp]
	call sub_draw_hero	; update hero overlay immediately (or there will be a delay where no hero overlay is visible on map); this will also clear [48C58C]
	mov eax, [esp]
	call 44CB34	; TTSW10.disp (update player's status display)
	mov eax, [esp]
	call 4664E4	; TTSW10.moncheck (some monsters, after being defeated, will trigger special events; do this check)
	pop eax
	jmp 44BC0C	; TTSW10.timer2on (execute the special events, if present)


;;;;;;;;;; Load a specific temp data ;;;;;;;;;;
; pop up a input box, which allows input with format of "-N" or "+N"
; then load a temp data that is N snapshots before or after the current one
; 4809CC:
sub_loadtemp_any:
	push ebx
	mov ebx, eax	; [ebx]=TTSW10 handle, which is required for sub_loadtemp in tswSL.asm

	loc_loadtemp_any_noprolog:
	mov ecx, 489DE8	; 489DE8: a vacant DWORD (within the block for the polyline and highlight functions)
	; [IN,OUT] used to receive the pointer of user input text, also used to serve as the pointer of the initial text of the input box
	; initially, NULL, indicating null string
	push ecx	; store this value
	mov edx, 454748	; input box title; "Load Temp Data"; see below
	lea eax, [edx+10]	; input box label; "Load the prev/next N-th (0-9) snapshot:\n\n\nFormat: -N / +N / blank (N=0)"; see below
	call 42CF9C	; _Unit9.InputBox
	test al, al	; return value; if 0, it means the user cancelled the input
	pop ecx	; retrieve input text pointer; balance the stack
	je +3B	; loc_loadtemp_any_ret (when user cancelled)
	; if the user confirmed the input, continue processing below...
; Briefly, explain how Delphi implements "string":
; char array, starting from offset XXXXXX, will align to 4-byte boundary
; a DWORD integer, at offset XXXXXX-4, is the length of the text contents, excluding the trailing \0
; a DWORD integer, at offset XXXXXX-8, is the reference count of the string object; each time @LStrClr is called, the count is decreased by 1, and the memory space of the whole string object will be freed once it reaches 0; if the count is -1 (i.e., 0xFFFFFFFF), it means the string is a const string, and its reference count will never decrease, meaning it will never be freed
; in Delphi's built-in functions, if it receive a string pointer in its paramters and alters its pointing address to a different string (e.g., this InputBox function; other examples are @LStrCat, @LStrAsg etc.), the original string object will be properly freed when necessary (by calling @LStrClr), so we don't need to do extra processing (such as manually calling @LStrClr) on our own
; another advantage of leaving the string object alone is that the previous user's input will automatically serve as the initial text the next time the input box is shown
	mov edx, [ecx]	; actual char array address
	and ecx, edx	; since ecx is not 0, the result will be 0 only when edx is 0 (which triggers je below, and in this case ecx will also become 0)
	je +2F	; loc_loadtemp_any_ret_loadtemp; empty str; cl=0

	cmp [edx-4], 3	; string length
	jb +12	; should only be 0, 1, or 2; otherwise, invalid input; need to retry

	loc_loadtemp_any_retry:
	mov [edx], "-5"	; [2D 35 00 00]; change the example text in the next input box to be "-5"
	mov eax, 4547A0	; message text; "Invalid input!"
	call 42CF78	; _Unit9.ShowMessage
	jmp loc_loadtemp_any_noprolog	; start from the beginning

	mov al, [edx]	; first char
	mov cl, [edx+1]	; second char
	sub cl, 3A	; ascii of '0'-'9' is 0x30 to 0x39
	add cl, 0A	; on one hand, after these two operations, cl will become 0-9 if it was '0'-'9'
	jae loc_loadtemp_any_retry	; on the other hand, CF register will only be on when cl was '0'-'9'; otherwise, invalid input
	cmp al, "-"	; [2D] the first char should be either '-' or '+'
	je +6	; when '-', no need to do anything, because cl for sub_loadtemp in tswSL.asm means (current_tempdata_id - target_tempdata_id), so a positive value of cl means rewinding
	cmp al, "+"
	jne loc_loadtemp_any_retry; when neither '-' nor '+', invalid input
	neg cl	; when '+', need to change the sign of cl; a negative value of cl for sub_loadtemp in tswSL.asm means fastforwarding

	loc_loadtemp_any_ret_loadtemp:
	call [4547B0]	; pointer of `sub_loadtemp` in tswSL.asm

	loc_loadtemp_any_ret:
	pop ebx
	ret

454748:	; vacant space from 454748 to 4547B4, saved by rewriting TTSW10.kaidanwork (see tswMPExt_2.asm)
	; unlike other Delphi-built-in functions, which need to specify [XXXXXX-8] and [XXXXXX-4] for input string objects as reference count and text length respectively, since the input box title and label texts are const string objects (won't be freed), no such requirements are necessary
	; however, the caveat is that [XXXXXX-4] should not be 0, otherwise Delphi might misunderstand it as null string
	db 'Load Temp Data',0,0	; of course, for a Chinese version, the text here will be the corresponding Chinese text; same below
454758:
	db 'Load the prev/next N-th (0-9) snapshot:',0A,0A,0A
	; the width of the input box is limited, so the label text can't be too long in one line
	; there is still some space for a second line of label in the input box, which needs three line breaks to be placed at the correct position
	db 'Format: -N / +N / blank (N=0)',0
4547A0:
	db 'Invalid input!',0,0
4547B0:
	db 00000970	; the pointer of `loc_load_temp_2` in tswSL.asm, which is $lpNewAddr+0x970 (here shows an example, not an accurate value)
