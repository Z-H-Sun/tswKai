; Author: Z.Sun
; My special thanks to Bilibili User '竹林眠り猫', who pioneered the work of analyzing the assembly codes for TSW's battle events and came up with the idea of realizing 'OTK' in TSW (i.e., displaying only one-turn battle animation to save time)

BASE:00000	; Pre-defined functions and variables in TSW.exe

BASE:00000	TSW_tile_pos_diff	:= dword ptr BASE:08C568	; pos=11Y+X; this is the difference of position (pos) of a tile with respect to the hero position
		TSW_Zeno_HP	:= dword ptr BASE:089A00
		TSW_Zeno_ATK	:= dword ptr BASE:089A04
		TSW_Zeno_DEF	:= dword ptr BASE:089A08
		TSW_Zeno_GOLD	:= dword ptr BASE:089A0C
		TSW_win_size	:= byte ptr BASE:089BA4	; 0:640x400; 1:800x500
		TSW_hero_status	:= dword ptr BASE:0B8688	; DWORD array
		TSW_hero_HP	:= dword ptr BASE:0B8688	; this is the first element of array [TSW_hero_status] so their addresses are the same
		TSW_hero_floor	:= dword ptr BASE:0B8698
		TSW_hero_X	:= dword ptr BASE:0B86A0
		TSW_hero_Y	:= dword ptr BASE:0B86A4
		TSW_hero_BlueKey	:= dword ptr BASE:0B86B0
		TSW_hero_SupperMattock	:= dword ptr BASE:0B8700
		TSW_backside_tower	:= dword ptr BASE:0B8904	; if in backside tower, 43; otherwise 0. So the factor of properties is [TSW_backside_tower]+1, i.e., 44 or 1
		TSW_map_data	:= dword ptr BASE:0B8934
		TSW_i	:= dword ptr BASE:08C558	; this is just a temporary variable; in the context of battles, it is usually assigned to 'number of rounds' or 'damage per round'
		TSW_battle_total_damage	:= dword ptr BASE:08C568	; when using orb of hero, this value is a rough estimate, which does not take into consideration the effect of Cross/DragonSlayer/strike-first enemies
		; however, during battle, TSW will calculate an accurate damage value, taking everything above into consideration
		; oddly enough, this calculation is not fully used: Its value will only be compared with hero's HP (if larger, than the number of rounds, and by extension, the number of animation frames) needs adjusting accordingly. Otherwise, this value is not at all involved in the calculations during the battle
		TSW_battle_total_rounds	:= dword ptr BASE:08C56C
		TSW_battle_enemy_HP	:= dword ptr BASE:08C5BC


		; Entry 0: 49F Sorcerer show-up animation bug (this bug will always be patched)

BASE:62560	TTSW10.madoushi2	proc near	; (rōmaji of '魔導師2') 49F Sorcerer show-up animation
		; ...
		; the first animation event sequence is 9,0xF,0xA7
		; the current index (pointer) of the event sequence that will be executed is [BASE:8C5AC], i.e., [ebx] below
		; once a event sequence is executed, [ebx]-=1; once a new event sequence is pushed to the end of the event sequnce array [BASE:8C7AC], [ebx]+=1. They will be executed in the reversed order. This event sequence array works like stack, the data stored there will not be actively cleaned up; it will only be overwritten when necessary, and the pointer ([BASE:8C5AC]) changes constantly as described above
		; for more details on how the event sequences work in TSW, see tswBGM.asm
		; so what casued the bug here? the pointer was mistakenly added by 1 at the end of this subroutine. So if there is some garbage data from previous event sequences (because they will not be cleaned up), that specific sequence will then be executed mistakenly
BASE:637B8		inc [ebx]	; pointer += 1
BASE:637BA		mov eax, [ebx]
BASE:637BC		lea eax, [eax+eax*2]
BASE:637BF		mov word ptr [esi+eax*2], 9	; first word is 9
BASE:637C5		mov eax, [ebx]
BASE:637C7		lea eax, [eax+eax*2]
BASE:637CA		mov word ptr [esi+eax*2+2], 0F	; second word is 0xF
BASE:637D1		mov eax, [ebx]
BASE:637D3		lea eax, [eax+eax*2]
BASE:637D6		mov word ptr [esi+eax*2+4], 00A7	; third word is 0xA7
		; original bytes:
;BASE:637DD		inc [ebx]	; this is wrong!
		; ...
		; patched bytes:
BASE:637DD		nop
BASE:637DE		nop
		; patch ends
BASE:637DF		add esp,10
BASE:637E2		pop edi
BASE:637E3		pop esi
BASE:637E4		pop ebx
BASE:637E5		ret
		TTSW10.madoushi2	endp


		; Entry 1: OTK (show only one-turn battle animation)
		; This will also solve the 2500-round limitation bug. The origin of this bug is explained below
		; As discussed above, the battle animation event is stored in the array [BASE:8C7AC], and its size is not infinite. Once there are too many events, which eventually overflows into other memory addresses (especially [BASE:B8688], i.e., TSW_hero_status) the routine timer events of TSW will fail as these important variables have been overwritten by garbage data
		; Of course, if there are not so many animation frames, this bug will not be triggered

BASE:4A480	TTSW10.taisen	proc near	; (rōmaji of '対戦') battle (not strike-first enemies)
		; ...
		; in case of insufficient HP (will cause game-over)
		; below is within the battle animation loop, each cycle being one battle round, containing 2 animations (enemy beating hero and hero beating enemy)
		; in order to realize OTK, we just need to jump out of the loop once the first animation is over
		; original bytes:
;BASE:4A95E		inc [ebx]	; the lines below encodes a 0,0,0 event sequence
;BASE:4A960		mov ecx, [ebx]	; for more details on how the event sequences work in TSW, see tswBGM.asm
;BASE:4A962		lea ecx, [ecx+ecx*2]
;BASE:4A965		mov word ptr [esi+ecx*2], 0
;BASE:4A96B		mov word ptr [esi+ecx*2+2], 0
		; ...
		; patched bytes:
BASE:4A95E		xor edx, edx
BASE:4A960		mov [TSW_hero_HP], edx	; set HP=0 and then break immediately
BASE:4A966		jmp loc_battle_loop_end	; BASE:4B6AA
		; ...

		; in case of defeatable enemies
		; below is the battle animation loop, but before that, TSW has already taken care of the last round (remember the event sequences are executed in the reversed order, see `tswBGM.asm`), which is hero beating enemy, so in order to realize OTK, we just need to skip the whole loop
		; original bytes:
;BASE:4B492		mov edx, [TSW_battle_total_rounds]
;BASE:4B498		dec edx
;BASE:4B499		test edx, edx	; if TSW_battle_total_rounds <= 1 (OTK)
;BASE:4B49B		jle loc_battle_loop_end	; BASE:4B6AA
;BASE:4B4A1		mov [ebp-08], 1
;BASE:4B4A8	loc_battle_loop_start1:
		; ...
		; patched bytes:
BASE:4B492		mov edx, [TSW_battle_total_damage]
BASE:4B498		sub [TSW_hero_HP], edx	; set HP-=damage and then break immediately
BASE:4B49E		jmp loc_battle_loop_end	; BASE:4B6AA
		; ...
		TTSW10.taisen	endp

BASE:7F7D4	TTSW10.taisen2	proc near	; (rōmaji of '対戦2') battle (strike-first enemies)
		; ...
		; in case of insufficient HP (will cause game-over)
		; below is the battle animation loop, where `eax` will decrease from [TSW_battle_total_rounds]-1 to 0; and `edx` will increase from 1 to [TSW_battle_total_rounds]
		; loop ends when `eax` reaches 0; `edx` will only be compared with 1 to see whether this is the last round (remember the event sequences are executed in the reversed order, see `tswBGM.asm`), but in our case here, with OTK, there will be only one round, so the value of `edx` does not matter
		; original bytes:
;BASE:7FA6F		mov edx, 1	; the last round: will only show animation of enemy beating hero; other rounds comprise of two frames of animation: enemy beating hero and hero beating enemy
;BASE:7FA74	loc_battle2_loop_start1:	; in our case here, with OTK, there will be only one round, so we don't care about the starting address of this loop
;			mov [TSW_i], edx ; this line is useless
;BASE:7FA7A		cmp [TSW_i], 1
;BASE:7FA81		je loc_last_round	; BASE:7FB7B
		; ...
		; patched bytes:
		; now we need to jump directly to the last round and show only one last battle animation frame (enemy beats hero, and hero dies)
BASE:7FA6F		xor eax,eax
BASE:7FA71		mov [TSW_hero_HP], eax	; set HP=0
BASE:7FA76		inc eax	; `eax` is now 1, and will be later 0 at the end of the loop, thus ending the loop (the condition is `eax==0`)
BASE:7FA77		jmp loc_any_round_common	; BASE:7FD37 (BASE:7FB7B, i.e., loc_last_round, just encodes several 0,0,0 event sequences, which is useless, so we can jump ahead a bit)
		; ...

		; in case of defeatable enemies
		; like the case above, `edx` is the round number, which will be compared with only 1, thus not important in our OTK case; `eax` is the number of remaining rounds, which will end the loop on reaching zero
		; original bytes:
;BASE:8002F		mov eax, [TSW_battle_total_rounds]
;BASE:80034		test eax, eax
;BASE:80036		jle loc_battle2_loop_end	; BASE:80241
;BASE:8003C		mov edx, 1
		; ...
		; patched bytes:
		; now we need to jump directly to the last round and show two battle animation frames (enemy beats hero, and hero beats enemy)
BASE:8002F		mov eax, [TSW_battle_total_damage]
BASE:80034		sub [TSW_hero_HP], eax	; HP -= damage
BASE:8003A		nop
BASE:8003B		nop
BASE:8003C		mov eax, 1	; `eax` is now 1, and will be later 0 at the end of the loop, thus ending the loop (the condition is `eax==0`)
		; ...
		TTSW10.taisen2	endp

BASE:526C0	TTSW10.stackwork	proc near	; decode event sequences
		; ...
		; for more details on how the event sequences work in TSW, see tswBGM.asm
		; 5,X,X (enemy HP update)
		; original bytes:
;BASE:52BF4		add [TSW_battle_enemy_HP], eax	; eax is damage to enemy in a round
;BASE:52BFA		cmp [TSW_battle_enemy_HP], 0
;BASE:52C01		jge loc_normal_HP_deduction1	; BASE:52C0A
;BASE:52C03		xor eax,eax	; if its HP<0, set its HP=0
;BASE:52C05		mov [TSW_battle_enemy_HP], eax
;BASE:52C0A	loc_normal_HP_deduction1:
		; ...
		; patched bytes:
BASE:52BF4		jmp BASE:52C03	; always set enemy's HP=0, because there is only one round
		; ...

		; 4,X,X (hero HP update)
		; original bytes:
;BASE:52C64		add [TSW_hero_HP], eax	; eax is damage to hero in a round
;BASE:52C6A		cmp [TSW_hero_HP], 0
;BASE:52C71		jge loc_normal_HP_deduction2	; BASE:52C0A
;BASE:52C73		xor eax,eax	; if its HP<0, set its HP=0
;BASE:52C75		mov [TSW_hero_HP], eax
;BASE:52C7A	loc_normal_HP_deduction2:
		; ...
		; patched bytes:
BASE:52C64		jmp BASE:52C6A	; do nothing; because hero's HP is already calculated in patched `taisen` or `taisen2` subroutine
		; ...
		TTSW10.stackwork	endp


		; Entry 2: 47F MagicianA bug

BASE:4C5C4	TTSW10.mazyutu1	proc near	; (rōmaji of '魔術1') magic attack
		; ...
		; below shows the conditions for MagicianA to retreat
BASE:4C5E9		mov ebx, [TSW_hero_floor]
BASE:4C5EF		mov esi, ebx
BASE:4C5F1		sub esi, 2F	; Must be on Floor 47
BASE:4C5F4		jne loc_MagicianA_end	; BASE:4C6DB
BASE:4C5FA		mov esi, [TSW_hero_Y]
		; original bytes:
;BASE:4C600		mov edi, esi
;BASE:4C602		dec edi
;BASE:4C603		sub edi, 9	; value sub A then sub B then jnb means jump if value < N or >= N+M
;BASE:4C606		jnb loc_MagicianA_end	; so it means hero's Y must >= 1 and < (9+1), i.e., excluding the first and last row
			; this is not reasonable! It should be MagicianA's Y rather than hero's Y that should be considered here. This bug here makes MagicianA:
			;		unable to move downwards on the second row or move upwards on the last but one row
			;		unable to move horizontally on the first or last row
;BASE:4C60C		imul esi, esi, 0B	; esi=Y*11
;BASE:4C60F		add esi, [TSW_hero_X]	; pos=Y*11+X
;BASE:4C615		add esi, [TSW_tile_pos_diff]	; pos will:
			;		+=2 if MagicianA is 1 cell right w.r.t you
			;		+=22 if MagicianA is 1 cell up w.r.t. you
			;		-=2 if MagicianA is 1 cell left w.r.t. you
			;		-=22 if MagicianA is 1 down up w.r.t. you
			; the value on the R.H.S. is TSW_tile_pos_diff
;BASE:4C61B		sub esi, 7A	; -=122
;BASE:4C61E		jnb loc_MagicianA_end	; this means the destination pos must >= 0 and < (122+0)
			; this is not sufficient nor necessary! It means MagicianA should not move out of the map of the current floor, but
			;		it does not detect whether MagicianA will move out of current row! so if MagicianA is on the first column and forced to move left, it will move to the last column of the previous row; if MagicianA is on the last column and forced to move right, it will move to the first column of the next row! What a stupid bug!
			;		so actually, we just need to make sure MagicianA is not on the first/last row or first/last. But if this condition is met, natually it won't be moved out of the current map, so this whole statement is even not necessary!
;BASE:4C624		imul esi, [TSW_hero_Y], 0B	; esi=Y*11
;BASE:4C62B		add esi, [TSW_hero_X]
;BASE:4C631		add esi, [TSW_tile_pos_diff]	; pos=Y*11+X+diff
;BASE:4C637		imul ebx, ebx, 7B	; Floor*=123 (this is because each map has 123 bytes, first 2 being the up/downstairs position, and the next 121 bytes being tile IDs of the map)
;BASE:4C63A		add ebx, offset TSW_map_data
;BASE:4C640		cmp byte ptr [ebx+esi+2], 06	; +2 is because the first 2 bytes are the up/downstairs position not tile ID; 6 is plain road
;BASE:4C645		jne loc_MagicianA_end	; do not move MagicianA if the destination is not plain road
		; ...
		; patched bytes:
		; as discussed above, we just want to check:
		; if MagicianA's (not hero's!) X and Y is between 1 and 9 (not 0 or 10, meaning the first or last row/column)
BASE:4C600		mov edi, [TSW_tile_pos_diff] ; as discussed above, according to the relative pos of MagicianA w.r.t. you, it can take one of the following values: +2, +22, -2, and -22
BASE:4C606		add esi, edi
BASE:4C608		sub esi, -0014	; -20
BASE:4C60B		sub esi, 0033	; 51
BASE:4C60E		jnb loc_MagicianA_end	; so it means (Y+diff) should >= -20 and < (-20+51)
			; this is worth a bit explaining here. The only situations that is no-go is:
			;		Y=1,diff=-22 (you are on the second row, and trying to push the first-row MagicianA upwards)
			;		Y=9,diff=22 (you are on the last but one row, and trying to push the last-row MagicianA downwards)
			;		all other conditions meet the criteria for MagicianA to move, so (Y+diff) must be between -20 and 30 (excluding -21 and 31)
BASE:4C614		add edi, [TSW_hero_X]	; edi=(diff+X)
BASE:4C61A		cmp edi, -01
BASE:4C61D		je loc_MagicianA_end
BASE:4C623		cmp edi, 0B
BASE:4C626		je loc_MagicianA_end ; so it means (X+diff) should not be -1 or 11. The reason is similar with above: The only two no-go conditions:
			;		X=1,diff=-2 (you are on the second column, and trying to push the first-column MagicianA left)
			;		X=9,diff=2 (you are on the last but one column, and trying to push the last-column MagicianA right)
BASE:4C62C		imul esi, [TSW_hero_Y], 0B
BASE:4C633		add esi, edi
BASE:4C635		nop
BASE:4C636		nop
BASE:4C637		imul ebx, ebx, 7B
BASE:4C63A		add ebx, offset TSW_map_data	; similar to original bytes
BASE:4C640		cmp byte ptr [ebx+esi+2], 6	; [TSW_map_data+2+diff+X+11*Y+123*Floor] should be plain road (6)
BASE:4C645		jne loc_MagicianA_end
		; ...
		TTSW10.mazyutu1	endp


		; Entry 3-1: 45F backside tower Merchant bug		change HP value from 2000 to 88000

BASE:4E1CC	TTSW10.Button2Click	proc near	; OK button
		; ...
		; TSW_hero_status[BASE:BC598] indicates whether you have purchased from a specific Merchant
		; TSW_hero_status[BASE:BC59C] indicates whether you have obtained information from a specific Merchant after you made a deal with him
		; jump table for switch statement of [BASE:BC598]-42
BASE:4E342		dd loc_2F_Merchant1	; BASE:4E372
BASE:4E346		dd loc_6F_Merchant1	; BASE:4E37E
BASE:4E34A		dd loc_7F_Merchant1	; BASE:4E386
BASE:4E34E		dd loc_12F_MerchantL1	; BASE:4E38F
BASE:4E352		dd loc_12F_MerchantR1	; BASE:4E397
		; original bytes:
;BASE:4E356		dd loc_15F_Merchant_old1	; BASE:4E39F
		; patched bytes:
BASE:4E356		dd loc_6F_Merchant1	; both 15F Merchant and 6F Merchant sells 1 blue key, so they can share the same codes, and the space saved can be utilized in our patch
		; patch ends
BASE:4E35A		dd loc_28F_Merchant1	; BASE:4E3A7
BASE:4E35E		dd loc_31F_Merchant1	; BASE:4E3B6
BASE:4E362		dd loc_38F_Merchant1	; BASE:4E3C5
BASE:4E366		dd loc_39F_Merchant1	; BASE:4E3CE
		; original bytes:
;BASE:4E36A		dd loc_45F_Merchant_old1	; BASE:4E3D7
;BASE:4E36E		dd loc_47F_Merchant_old1	; BASE:4E3E3
		; patched bytes:
BASE:4E36A		dd loc_15F_Merchant_old1	; now we can use the space saved from 15F Merchant
BASE:4E36E		dd loc_47F_Merchant_new1	; BASE:4E3E6
		; ...
		; original bytes:
BASE:4E39F	loc_15F_Merchant_old1:
;			inc [TSW_hero_blueKey]
;BASE:4E3A5		jmp loc_Merchant_end1	; BASE:4E3ED
		; patched bytes:
BASE:4E39F		mov eax, [TSW_backside_tower]	; 43 in backside tower or otherwise 0
BASE:4E3A4		inc eax	; 44 or 1
BASE:4E3A5		jmp loc_45F_Merchant_old1	; run out of space; the remainder will be processed in loc_45F_Merchant_old1
		; ...

		; original bytes:
;BASE:4E3D7	loc_45F_Merchant_old1:
;			add [TSW_hero_HP], 07D0	; HP+=2000
;BASE:4E3E1		jmp loc_Merchant_end1	; BASE:4E3ED
;BASE:4E3E3	loc_47F_Merchant_old1:
;			mov [TSW_hero_SupperMattock], 1
;BASE:4E3ED	loc_Merchant_end1:
		; ...
		; patched bytes:
BASE:4E3D7	loc_45F_Merchant_old1:
			mov edx, 07D0	; 2000
BASE:4E3DC		mul edx	; eax is either 44 or 1; edx*=eax
BASE:4E3DE		add [TSW_hero_HP], edx
BASE:4E3E4		jmp loc_Merchant_end1
BASE:4E3E7	loc_47F_Merchant_new1:
			mov byte ptr [TSW_hero_SupperMattock], 1	; the value of this variable will never exceed 255, so we assign it as a BYTE rather than as a DWORD, which saves 3 bytes space
BASE:4E3ED	loc_Merchant_end1:
		; ...
		TTSW10.Button2Click	endp


		; Entry 3-2: 45F backside tower Merchant bug		change the string in the dialog from 2000 to 88000 too
		; This requires adding a new text entry in TListBox2, which stores all text entries (which is kind of weird: Doesn't Delphi have its own implementation of string array?)
		;		statically, this has been done by adding the RCData of the Delphi window of TTSW10
		;		dynamically, this can be done by sending the LB_ADDSTRING or LB_INSERTSTRING message to TListBox2

BASE:49014	TTSW10.syounin	proc near	; (rōmaji of '商人') Merchants
		; ...
		; TSW_hero_status[BASE:BC598] indicates whether you have purchased from a specific Merchant
BASE:494E4	loc_45F_Merchant2:
			mov [BASE:8C5A0], 0014
		; original bytes:
;BASE:494EE		mov [TSW_i], 000A	; this temporary variable is used as the relative index of the dialog ID; see below for more details
;BASE:494F8		mov [BASE:8C598], 0034	; TSW_hero_status[BASE:BC598] indicates whether you have purchased from a specific Merchant
;BASE:49502		mov [BASE:8C59C], 0040	; TSW_hero_status[BASE:BC59C] indicates whether you have obtained information from a specific Merchant after you made a deal with him
		; ...
		; patched bytes:
BASE:494EE		mov eax, [TSW_backside_tower]	; 43 in backside tower or otherwise 0
BASE:494F3		inc eax	; 44 or 1
BASE:494F4		shr eax, 2	; 11 or 0
BASE:494F7		add al, 0A	; 21 or 10
BASE:494F9		mov [TSW_i], eax
BASE:494FE		mov byte ptr [BASE:8C598], 0034
BASE:49505		mov byte ptr [BASE:8C59C], 0040	; these values will never exceed 255, so we assign each of them as a BYTE rather than as a DWORD, which saves 3 bytes space
		; ...
BASE:49583		mov eax, [TSW_i]
BASE:49588		sub eax, 0C	; there are only 12 Merchants, so if the dialog ID is < 0 or >= 12, no dialog window will be shown
		; original bytes:
BASE:4958B		jnb loc_Merchant_end2	; BASE:495BB
BASE:4958D		lea ecx, [ebp-04]
BASE:49590		mov edx, [TSW_i]
BASE:49596		add edx, 00F6	; +246 -> the actual index of text entry in TListBox2
		; ...
		; patched bytes:
BASE:4958B		jb loc_Merchant_normal	; BASE:49592 the normal dialogs for the 12 Merchants; ignore the lines below
BASE:4958D		cmp al, 9	; i.e., if the ID is 21 (12+9)
BASE:4958F		jne loc_Merchant_end2	; otherwise, there must be some error because there is no such Merchant dialog ID
BASE:49591		inc eax	; if ID is 21, then change it to 22, because the new text entry index is 258 (=246+22)
BASE:49592		lea ecx, [ebp-04]
BASE:49595		add eax, 0102	; +258 (the actual index of text entry in TListBox2; need to take into consideration the previously subtracted number (12; 246+12=258))
BASE:4959A		mov edx, eax
		; ...
		TTSW10.syounin	endp


		; Entry 4: 50F backside tower Zeno bug
		; This bug happens when you save/load after you seal the magic power of 49F Zeno in the backside tower (>= 3rd round), then the properties of 50F Zeno will be mistakenly multiplied by 44
		; That is because there is a bug in `TTSW10.syokidata2` (see below). The 44 factor is already taken care of during battle subroutines, so this factor should not be multiplied here

BASE:54DE8	TTSW10.syokidata2	proc near	; (rōmaji of '初期data2') initialization of game data
		; ...
		; original bytes:
;BASE:55B78		mov eax, [esi+027C]	; i.e., [BASE:B8904] (TSW_backside_tower)
;BASE:55B7E		inc eax	; 44 or 1. This factor should not be multiplied here
		; patched bytes:
BASE:55B78		xor eax, eax	; always 0
BASE:55B7A		jmp BASE:55B7E
		; patch ends
		; ...
BASE:55B7E		inc eax	; should be just 1
BASE:55B7F		imul edx, eax, 0320	; 800
BASE:55B85		mov [TSW_Zeno_HP], edx
BASE:55B8B		imul edx, eax, 01F4	; 500
BASE:55B91		mov [TSW_Zeno_ATK], edx
BASE:55B97		imul eax, eax, 0064	; 100
BASE:55B9A		mov [TSW_Zeno_DEF], eax
		; ...
		TTSW10.syokidata2	endp


		; Entry 5: increase the dialog window text margins (otherwise too busy)
		; For this low version RichEdit control, there is no Margins or BorderWidth properties, so the best we can try is sending the `EM_SETRECT` message to TRichEdit1
		; Depending on the window size (640x400 or 800x500), we will set different margins ([9,5,w-11,h-7] or [12,8,w-14,h-10] respectively)

BASE:84F48	TTSW10.syokidata0	proc near	; (rōmaji of '初期data0') initialization of GUI
		; ...
		; original bytes:
;BASE:84F66		mov eax, [BASE:8A6FC]
;BASE:84F6B		call TScreen.GetWidth	; BASE:23BA8
;BASE:84F70		cmp eax, 0320	; 800
;BASE:84F75		jge BASE:84F87	; screen width must be >= 800; however, this test is really unnecessary for modern computers
;BASE:84F77		cmp byte ptr [TSW_win_size], 1	; 0:640x400; 1:800x500
;BASE:84F7E		jne BASE:84F87
;BASE:84F80		mov byte ptr [TSW_win_size], 0	; up to now, it means do not change to larger window size if the screen is not large enough (unnecessary)
;BASE:84F87		mov al, [TSW_win_size]
;BASE:84F8C		sub al, 1
;BASE:84F8E		jb BASE:84F94	; =0
;BASE:84F90		je BASE:84FD7	; =1
;BASE:84F92		jmp BASE:84FFA	; this is not likely
;BASE:84F94		mov eax, [BASE:8A6FC]
;BASE:84F99		call TScreen.GetWidth
;BASE:84F9E		cmp eax, 0320	; 800
;BASE:84FA3		jge BASE:84FB2	; checks screen size; again, unnecessary
;BASE:84FA5		xor edx,edx
;BASE:84FA7		mov eax, [ebx+0474]	; TMenuItem:k1 ('Size')
;BASE:84FAD		call TMenuItem.SetEnabled	; BASE:10378
;BASE:84FB2		mov eax, BASE:8C5FC	; AnsiString
;BASE:84FB7		mov edx, BASE:88858	; '\data' (this is folder of image files for the smaller-sized window)
;BASE:84FBC		call @LStrAsg	; BASE:0352C
;BASE:84FC1		mov [BASE:8C578], 0090	; game_map.left = 144
;BASE:84FCB		mov [BASE:8C57C], 0018	; game_map.top = 24
;BASE:84FD5		jmp BASE:84FFA
;BASE:84FD7		mov eax, BASE:8C5FC	; AnsiString
;BASE:84FDC		mov edx, BASE:88868	; '\data3' (this is folder of image files for the larger-sized window)
;BASE:84FE1		call @LStrAsg	; BASE:0352C
;BASE:84FE6		mov [BASE:8C578], 00B4	; game_map.left = 180
;BASE:84FF0		mov [BASE:8C57C], 001E	; game_map.top = 30
		; ...
		; patched bytes:
BASE:84F66		mov dl, [TSW_win_size]	; 0:640x400; 1:800x500
BASE:84F6C		imul edx, edx, 3	; dl = 0 or 3
BASE:84F6F		mov al, 9
BASE:84F71		add al, dl	; al = 9 or 12
BASE:84F73		mov [TSW_Zeno_HP], eax	; 9 or 12; we use it as a temp var here; it will be reassigned in `TTSW10.syokidata2`
BASE:84F78		sub al, 4	; 5 or 8
BASE:84F7A		mov [TSW_Zeno_ATK], eax	; 5 or 8; we use it as a temp var here; it will be reassigned in `TTSW10.syokidata2`
BASE:84F7F		mov edx, [ebx+01CC]	; TRichEdit1
BASE:84F85		mov ecx, [edx+2C]	; .width
BASE:84F88		add al, 6	; 11 or 14
BASE:84F8A		sub cl, al	; w-11 or w-14
BASE:84F8C		mov [TSW_Zeno_DEF], ecx	; w-11 or w-14; we use it as a temp var here; it will be reassigned in `TTSW10.syokidata2`
BASE:84F92		mov ecx, [edx+30]	; .height
BASE:84F95		sub al, 4	; 7 or 10
BASE:84F97		sub cl, al	; h-7 or h-10
BASE:84F99		mov [TSW_Zeno_GOLD], ecx	; h-7 or h-10; we use it as a temp var here; it will be reassigned to 500 later
BASE:84F9F		mov ecx, [edx+C0]	; .hWnd
BASE:84FA5		push eax	; 7 or 10
BASE:84FA6		xor eax, eax
BASE:84FA8		push offset TSW_Zeno_HP	; lParam; RECT structure
BASE:84FAD		push eax	; wParam; 0
BASE:84FAE		mov al, 0xB3	; EM_SETRECT
BASE:84FB0		push eax	; Msg
BASE:84FB1		push ecx	; hWnd
BASE:84FB2		call SendMessageA
BASE:84FB7		mov word ptr [TSW_Zeno_GOLD], 01F4	; reset temp var to TSW_Zeno_GOLD, 500
BASE:84FC0		pop eax	; 7 or 10, indicating small or large game window respectively
BASE:84FC1		cmp al, 07
BASE:84FC3		mov eax, BASE:8C5FC	; AnsiString
BASE:84FC8		mov edx,BASE:88858	; '\data' (this is folder of image files for the smaller-sized window)
BASE:84FCD		jne BASE:84FE4
BASE:84FCF		call @LStrAsg	; BASE:0352C
BASE:84FD4		mov byte ptr [BASE:8C578], 90	; game_map.left = 144
BASE:84FDB		mov byte ptr [BASE:8C57C], 18	; game_map.top = 24; these values will never exceed 255, so we assign each of them as a BYTE rather than as a DWORD, which saves 3 bytes space
BASE:84FE2		jmp BASE:84FFA
BASE:84FE4		add edx, 0010	; BASE:88868='\data3' (this is folder of image files for the larger-sized window)
BASE:84FE7		call @LStrAsg	; BASE:0352C
BASE:84FEC		mov byte ptr [BASE:8C578], 00B4	; game_map.left = 180
BASE:84FF3		mov byte ptr [BASE:8C57C], 001E	; game_map.top = 30; these values will never exceed 255, so we assign each of them as a BYTE rather than as a DWORD, which saves 3 bytes space
		; ...
		TTSW10.syokidata0	endp
