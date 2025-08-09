BASE:00000	; Pre-defined functions in TSW.exe

BASE:00000	TSW_BGM_setting	:= byte ptr BASE:089BA2
		TSW_WAV_setting	:= byte ptr BASE:089BA3
		TSW_hero_status	:= dword ptr BASE:0B8688
		; dword array[12]
		; [4] -> floor; [6] -> x_pos; [7] -> y_pos
		TSW_hero_floor	:= dword ptr BASE:0B8698
		TSW_WAV_OFF	:= dword ptr BASE:0B87EC
		TSW_BGM_ID	:= dword ptr BASE:0B87F0
		TSW_DataCheck1	:= dword ptr BASE:0B8918
		TSW_DataCheck2	:= dword ptr BASE:0B891C
		TSW_TempByte	:= dword ptr BASE:0BA13B	; technically, this byte indicates the location you will appear at when you go down to 50F, which is impossible because there is no "51F" in this tower. Therefore, this byte is used as a temp var here
		TControl.Parent	:= dword ptr 0004	; dword
		TTSW10.TTimer1	:= dword ptr 01B4
		TTSW10.TTimer4	:= dword ptr 041C
		TTimer.Enabled	:= dword ptr 0020	; byte
		TTimer.Interval	:= dword ptr 0024	; dword
		TTSW10.TMediaPlayer1	:= dword ptr 02D4	; for playing `open.wav` soundeffect
		TTSW10.TMediaPlayer2	:= dword ptr 0460	; for playing `get.wav` soundeffect
		TTSW10.TMediaPlayer3	:= dword ptr 0464	; for playing `taisen.wav` (battle) soundeffect
		TTSW10.TMediaPlayer3	:= dword ptr 0468	; for playing `zeno.wav` (magic attack) soundeffect
		TTSW10.TMediaPlayer5	:= dword ptr 02D8	; for playing BGM
		TTSW10.TMediaPlayer6	:= dword ptr 046C	; for playing all other sound effects
		TMediaPlayer.PlayState	:= dword ptr 01D5	; byte
		TMediaPlayer.DeviceID	:= dword ptr 01E6	; word
		TTSW10.TMenuBGMON1	:= dword ptr 0330

BASE:2F838	mciSendCommandA	proc near	; winmm
BASE:2F838	mciSendCommandA	endp

; For patches @BASE:30EF8, @BASE:5282A, @BASE:53463, @BASE:63E78, @BASE:63F71, @BASE:6F972, @BASE:76EAD, @BASE:6B640, @BASE:81F6F, and @BASE:8468E, which are comparably simple, please refer to the comments for `BGM_PATCH_BYTES` in `tswBGM.rbw` for more information

BASE:2C454	TTimer.SetEnabled	proc near
		; TTSW10.TTimer4 was used to show the prolog animation; in tswBGM, instead, it is used to achieve the fading out effect of BGM. Therefore, when tswBGM is initiated, it is necessary to check whether TTimer4 is still enabled (meaning it's in prolog) and set `isInProlog`; if so, the initialization of tswBGM should be delayed. If TTimer4 is later set enabled or disabled, the state of `isInProlog` needs to be set false

		; original bytes:
;			cmp dl, [eax+20]	; dl is the new TTimer.Enabled state to be set
;BASE:2C457		je BASE:2C461
		; patched bytes:
BASE:2C454		call sub_resetTTimer4

BASE:2C459		mov [eax+TTimer.Enabled], dl
BASE:2C45C		call TTimer.UpdateTimer	; if TTimer.Enabled or TTimer.Interval is changed, this will be called; under the hood, user32.KillTimer is called, and then user32.SetTimer will be called if TTimer.Enabled
BASE:2C461		ret

BASE:2C461	TTimer.SetEnabled	endp

BASE:30F20	TMediaPlayer.Open	proc near
		; if is TMediaPlayer5, should set the correct flags and audio filename
		; ...
BASE:30F81		xor eax, eax
		; original bytes:
;BASE:30F83		mov [esi+01DC], eax	; dword [TMediaPlayer+1DC] is the flag to pass as `fdwCommand` to `mciSendCommand`
;BASE:30F89		cmp byte ptr [esi+01E2], 0	; byte [TMediaPlayer+01E2] indicates whether [TMediaPlayer+01E0] is assigned *for this time*; if not, set the flag to be the default value (for MCI_OPEN, the default is to set MCI_WAIT)
;BASE:30F90		je BASE:30FAE
;BASE:30F92		cmp byte ptr [esi+01E0], 0	; byte [TMediaPlayer+01E2] indicates whether to wait (MCI_WAIT)
;BASE:30F99		je BASE:30FA5
;BASE:30F9B		mov [esi+01DC], MCI_WAIT	; 2
;BASE:30FA5		mov byte ptr [esi+01E2], 0
;BASE:30FAC		jmp loc_next_0	; BASE:30FB8
		; ...
		; patched bytes:
BASE:30F83		mov al, MCI_WAIT	; no TMediaPlayer in TSW has other settings (should always wait for MCI_OPEN)
BASE:30F85		mov eax, [esi+TControl.Parent]
BASE:30F8E		cmp esi, [eax+TTSW10.TMediaPlayer5]
BASE:30F94		jne loc_next_0	; execute the following lines only if is TMediaPlayer5
BASE:30F94		mov [ebp-8], offset bgm_filename	; ebp-0x14 is MCI_OPEN_PARMS to pass as `dwParam` to `mciSendCommand`; ebp-8 is `lpstrElementName` (audio filename) in MCI_OPEN_PARMS structure
BASE:30F9D		or word ptr [esi+01DC], MCI_OPEN_ELEMENT	; 0x200 indicates `lpstrElementName` is in the MCI_OPEN_PARMS structure
		; the properties of TMediaPlayer5 are not necessary correctly set to be compatible with tswBGM, so these params should be manually assigned
BASE:30FA6		jmp loc_next_0	; BASE:30FB8
		; ...

		TMediaPlayer.Open	endp

BASE:31188	TMediaPlayer.Close	proc near
		; if is TMediaPlayer5, should use the fading out effect

		; original bytes:
;			push ebx
;BASE:31189		push esi
;BASE:3118A		push ecx
;BASE:3118B		mov ebx, eax
;BASE:3118D		cmp word ptr [eax+TMediaPlayer.DeviceID], 0
;BASE:31195		je BASE:31248	; return right away if the decide ID is not yet initialized
;BASE:3119B		xor eax, eax
;BASE:3119D		mov [esi+01DC], eax	; dword [TMediaPlayer+1DC] is the flag to pass as `fdwCommand` to `mciSendCommand`
;BASE:311A3		cmp byte ptr [esi+01E2], 0	; byte [TMediaPlayer+01E2] indicates whether [TMediaPlayer+01E0] is assigned *for this time*; if not, set the flag to be the default value (for MCI_CLOSE, the default is to set MCI_WAIT)
;BASE:311AA		je BASE:311C8
;BASE:311AC		cmp byte ptr [esi+01E0], 0	; byte [TMediaPlayer+01E2] indicates whether to wait (MCI_WAIT)
;BASE:311B3		je BASE:311BF
;BASE:311B5		mov [esi+01DC], MCI_WAIT	; 2
;BASE:311BF		mov byte ptr [esi+01E2], 0
;BASE:311C6		jmp BASE:311D2
		; patched bytes:
BASE:31188		mov edx, [eax+TControl.Parent]
BASE:3118B		cmp eax, [eax+TTSW10.TMediaPlayer5]
BASE:31191		jne BASE:311B5	; execute the following lines only if is TMediaPlayer5

BASE:31193		mov eax, [edx+TTSW10.TTimer4]
BASE:31199		mov dl, 06	; to differentiate this enabled state from TSW's intrinsic enabled state of TTimer4, set TTimer.Enabled to 6 rather than 1
BASE:3119B		mov byte ptr [TSW_BGM_ID], FF	; this means to stop the current BGM
BASE:311A2		cmp byte ptr [isInProlog], 0	; in normal cases (`!isInProlog`), just begin fading out BGM by calling TTimer4.SetEnabled(false)
BASE:311A9		je TTimer.SetEnabled
		; otherwise, if `isInProlog`, need to stop the prolog and begin game right away; if not, because TTimer4 will be used for fading out, prolog will be on halt forever
BASE:311AF		push ebx	; this is necessary for calling the snippet in `TTSW10.GameStart1Click`, because there will be a `pop ebx` before `ret`
BASE:311B0		jmp BASE:6382A	; this is a snippet in `TTSW10.GameStart1Click`, which will call both `TTimer.SetEnabled` and `TTSW10.gameover` (despite the confusing name, the latter procedure actually restarts a game)

BASE:311B5		cmp word ptr [eax+TMediaPlayer.DeviceID], 0
BASE:311BD		jne BASE:311C0	; return right away if the decide ID is not yet initialized
BASE:311BF		ret
BASE:311C0		push ebx
BASE:311C1		push esi
BASE:311C2		push ecx
BASE:311C3		mov ebx, eax
BASE:311C5		nop
BASE:311C6		nop
BASE:311C7		nop
BASE:311C8		mov byte ptr [ebx+01E2], MCI_WAIT	; no TMediaPlayer in TSW has other settings (should always wait for MCI_CLOSE)
		; ...

		TMediaPlayer.Close	endp

BASE:31250	TMediaPlayer.Play	proc near
		; bug fix: if the interval between two sound effects is too short, the second sound might not be played.
		; if is TMediaPlayer5, should set the correct flags (endless repeat: MCI_DGV_PLAY_REPEAT)
		; ...
		; original bytes:
;BASE:312CB		cmp byte ptr [esi+01E2], 0	; byte [TMediaPlayer+01E2] indicates whether [TMediaPlayer+01E0] is assigned *for this time*; if not, set the flag to be the default value (for MCI_PLAY, the default is to unset MCI_WAIT (i.e. 0))
;BASE:312D2		je BASE:312EB
;BASE:312D4		cmp byte ptr [esi+01E0], 0	; byte [TMediaPlayer+01E2] indicates whether to wait (MCI_WAIT)
;BASE:312DB		je BASE:312E4
;BASE:312DD		or [esi+01DC], MCI_WAIT	; 2
;BASE:312E4		mov byte ptr [esi+01E2], 0
;BASE:312EB		cmp byte ptr [esi+01E4], 0	; byte [TMediaPlayer+01E4] indicates whether to play the music from a specific time point (one-time)
;BASE:312F2		je BASE:3130C
;BASE:312F4		or [esi+01DC], MCI_FROM	; 4
;BASE:312FB		mov eax, [ebx+01F0]	; the starting time point
;BASE:31301		mov [esp+4], eax	; DWORD dwFrom (in MCI_PLAY_PARMS)
;BASE:31305		mov byte ptr [esi+01E4], 0

		; patched bytes:
BASE:312CB		mov eax, [ebx+TControl.Parent]
BASE:312CE		cmp ebx, [eax+TTSW10.TMediaPlayer5]
BASE:312D4		je BASE:31313	; jump if is TMediaPlayer5. If tswBGM is disabled, nothing will happen; otherwise, MCI_DGV_PLAY_REPEAT flag will be set (see below)
BASE:312D6		xor edx, edx
BASE:312D8		mov [esp+4], edx	; DWORD dwFrom (in MCI_PLAY_PARMS)
		; below, I will explain under what condition I will force the wave file to be played from the beginning to avoid missing sounds
		; taisen.wav (battle): always
		; get.wav, open.wav, zeno.wav (magic attack): in addition to their normal use, these sound effects will also be used in special events, such as 3F, 10F, 25F, and 50F. In these special events, I don't want to play the sound effects from the beginning every time; otherwise they will be way too quick and dense (like "da-da-da-da-da" without any pause); actually the original treatment is better, i.e. wait for the previous sound effect to finish before starting the next one.
		; so I will set a threshold value, once the event count in [BASE:8C5AC] (pointer to the current event sequence, see elsewhere for its explanation) is greater than this value, it will be viewed as a special event, and then the file will not be played from the beginning (i.e. TSW's original treatment)
BASE:312DC		add eax, offset TTSW10.TMediaPlayer3	; this one plays the "taisen" (battle) soundeffect
BASE:312E1		cmp ebx, [eax]	; if is TMediaPlayer3
BASE:312E3		je BASE:31304	; always play the soundeffect from the beginning; otherwise, there will be missing sounds if this sound has already been playing
BASE:312E5		cmp ebx, [eax-4]	; if is TMediaPlayer2 (TTSW10.TMediaPlayer2=0x460=TTSW10.TMediaPlayer3-4)
BASE:312E8		mov dl, 4	; here, `dl` will be the maximum event count mentioned above
BASE:312EA		je BASE:312EE	; for get.wav, it will be viewed as a special event if [BASE:8C5AC] > 4
BASE:312EA		mov dl, 0040	; otherwise, it will be viewed as a special event if [BASE:8C5AC] > 0x40
BASE:312EE		mov eax, offset TSW_TempByte	; this temp byte will be used to indicate whether [BASE:8C5AC] have been greater than the threshold value *before*; if so, it is now still in a special event
BASE:312F3		mov cl, [eax]
BASE:312F5		cmp [BASE:8C5AC], edx	; whether the *current* event count is greater than the threshold
BASE:312FB		setg byte ptr [eax]	; the current status will be stored in the temp var
BASE:312FE		jg BASE:3130C	; do nothing if the *current* event count is greater than the threshold
BASE:31300		test cl, cl
BASE:31302		jne BASE:3130C	; do nothing if the *past* event count is greater than the threshold
BASE:31304		or [ebx+01DC], MCI_FROM	; 4
BASE:3130B		nop

		; original bytes:
;BASE:3130C		cmp byte ptr [esi+01E5], 0	; byte [TMediaPlayer+01E5] indicates whether to play the music to a specific time point and stop (one-time) (this property is never used in TSW, so it can be replaced by our own codes without any risk)
;BASE:31313		je BASE:3130C	; if tswBGM is disabled, and the current media player is TMediaPlayer5, the EIP will jump to here from BASE:312D4; because ZF=1 which meets `je` condition, so here it will jump too
;BASE:31315		or [esi+01DC], MCI_TO	; 8
;BASE:3131C		mov eax, [ebx+01F0]	; the starting time point
;BASE:31322		mov [esp+8], eax	; DWORD dwTo (in MCI_PLAY_PARMS)
;BASE:31326		mov byte ptr [esi+01E5], 0
		; ...

		; patched bytes:
BASE:3130C		cmp byte ptr [esi+01E5], 1	; we need to change the condition a bit here: original bytes test whether `[esi+01E5]==0`; here we change it to `[esi+01E5]!=1` which is identical
BASE:31313		jne BASE:3132D	; if tswBGM is enabled, and the current media player is TMediaPlayer5, the EIP will jump to here from BASE:312D4; because ZF=1 which does not meet `jne` condition, so here it will not jump
		; as a result, the following line will only be executed when the current meida player is TMediaPlayer5 (note that no player in TSW uses the [TMediaPlayer+01E5] property)
BASE:31315	or [esi+01DC], MCI_DGV_PLAY_REPEAT	; 0x10000 indicates the audio will be replayed once it reached the end
		; this flag is not useful to WAV or MIDI, so TSW has to set MCI_NOTIFY and manually replay the MIDI on notification of end of play
		; fortunately for MP3, this flag can be set to make our lives much easier
BASE:3131F	jmp BASE:3132D
		; ...

		TMediaPlayer.Play	endp

BASE:44490	TTSW10.handan	proc near	; judges what tile the player meets and what corresponding event should be elicited
		; TSW will replay the BGM every time you go to a new floor; I think a better design is to play the BGM if it is a new one
		; therefore it is necessary to patch the treatment of up/downstairs tiles
		; ...
		; original bytes:
;BASE:44D0E		cmp [TSW_BGM_ID], 0	; 0 means BGM is turned off
;BASE:44D15		je loc_next_1
;BASE:44D17		xor edx, edx
;BASE:44D19		mov eax, [ebp-4]	; handle of TTSW10
;BASE:44D1C		mov eax, [eax+TTSW10.TTimer1]	; Timer1 controls the 2-frame animation of the tiles, so it should be disabled during going up/downstairs
;BASE:44D22		call TTimer.SetEnabled	; however, these lines are not necessary here because Timer1 has been disabled elsewhere
;BASE:44D27		mov eax, [ebp-4]
;BASE:44D2A		mov eax, [eax+TTSW10.TMediaPlayer5]
;BASE:44D30		call TMediaPlayer.Close	; should not stop here; let `soundplay` to judge whether to stop according to whether it is a new BGM
;BASE:44D35	loc_next_1:
			; ...

;BASE:45096		jmp loc_end_handan	; after the treatment of stair tiles is done, go to the end of function
		; patched bytes:
BASE:44D0E		jmp loc_next_1	; do not check BGM here because the floor number hasn't changed yet; don't do the following until all other treatments of stair tiles are completed
BASE:44D10	loc_checkBGM_stairs:
			cmp [TSW_BGM_ID], 0
BASE:44D17		je BASE:44D2E	; loc_end_handan
BASE:44D19		call TTSW10.soundcheck
BASE:44D1E		mov eax, [ebp-4]	; TTSW10 handle
BASE:44D21		mov eax, [eax+TTSW10.TTimer4]
BASE:44D27		mov dl, 06	; to differentiate this enabled state from TSW's intrinsic enabled state of TTimer4, set TTimer.Enabled to 6 rather than 1
BASE:44D29		call TTimer.SetEnabled
BASE:44D2E		jmp loc_end_handan
		; ...

BASE:45096		jmp loc_checkBGM_stairs	; after all other treatment of stair tiles is done, then check BGM
		; ...
		; I decide to play the ending theme when the epilogue captions show (the long battle has come to an end...)
		; this event is elicited when you meets the 1st-round Zeno on 50F
		; see how the "3-word event sequences" is implemented in `sub_instruct_playBGM`
		; some examples: 0,0,0=wait; 1, 1~4,0=play soundeffect; 1,5/6,0=play/stop BGM; 10,ID,0=show diaglog No.`ID`; etc.
		; Here, orginally, (0,4,0); | ;(0B,0C,0190); now I insert (1,5,0014) into the `|` position if BGM is on. Note the execution of these event sequences is in the reversed order

BASE:4656A		inc [ebx]
BASE:4656C		mov eax, [ebx]
BASE:4656E		lea eax, [eax+eax*2]	; eax *= 3
		; original bytes:
;BASE:46571		mov word ptr [esi+eax*2], 0
;BASE:46577		mov eax, [ebx]
;BASE:46579		lea eax, [eax+eax*2]	; these 2 lines are clearly redundant
;BASE:4657C		mov word ptr [esi+eax*2+2], 4
;BASE:46583		mov eax, [ebx]
;BASE:46585		lea eax, [eax+eax*2]	; likewise, redundant
;BASE:46588		mov word ptr [esi+eax*2+2], 0
;BASE:4658F		inc [ebx]
;BASE:46591		mov eax, [ebx]
;BASE:46593		lea eax, [eax+eax*2]
;BASE:46596		mov word ptr [esi+eax*2], 0B
;BASE:4659C		mov eax, [ebx]
;BASE:4659E		lea eax, [eax+eax*2]
;BASE:465A1		mov word ptr [esi+eax*2+2], 0C
;BASE:46583		mov eax, [ebx]
;BASE:46585		lea eax, [eax+eax*2]
		; ...
		; patched bytes:
BASE:46571		cmp [TSW_BGM_ID], 0
BASE:46578		je loc_noBGM_1
BASE:4657A		mov dword ptr [esi+eax*2], 00050001
BASE:46581		mov word ptr [esi+eax*2+4], 0014	; (1,5,20) BGM #20=ending theme
BASE:46588		inc [ebx]
BASE:4658A		add eax, 3
BASE:4658D	loc_noBGM_1:
			mov dword ptr [esi+eax*2], 00040000
BASE:46594		mov word ptr [esi+eax*2+4], 0000	; (0,4,0)
BASE:4659B		inc [ebx]
BASE:4659D		add eax, 3
BASE:465A0		mov word ptr [esi+eax*2], 000B
BASE:465A6		mov word ptr [esi+eax*2], 000C
		; ...

		TTSW10.handan	endp

BASE:664E4	TTSW10.moncheck	proc near	; Checks if there is any special events to process after a monster is defeated (such as boss battles; gatekeepers guarding a gate; etc.)
		; ...
		; see above for how this works
		; 10F SkeletonA: play Fairy's theme BGM after it is defeated and says its last words
		; Here, orginally, (0,0,0); | ;(0A,0F,0); now I insert (1,5,0C) into the `|` position if BGM is on. Note the execution of these event sequences is in the reversed order

		; original bytes:
;BASE:6754C		inc [ebx]
;BASE:6754E		mov eax, [ebx]
;BASE:67550		lea eax, [eax+eax*2]
;BASE:67553		mov word ptr [esi+eax*2], 0
;BASE:67559		mov eax, [ebx]
;BASE:6755B		lea eax, [eax+eax*2]
;BASE:6755E		mov word ptr [esi+eax*2+2], 0
;BASE:67565		mov eax,[ebx]
;BASE:67567		lea eax,[eax+eax*2]
;BASE:6756A		mov word ptr [esi+eax*2+4], 0
;BASE:67571		inc [ebx]
;BASE:67573		mov eax,[ebx]
;BASE:67575		lea eax,[eax+eax*2]
;BASE:67578		mov word ptr [esi+eax*2], 0A
;BASE:6757E		mov eax,[ebx]
;BASE:67580		lea eax,[eax+eax*2]
;BASE:67583		mov word ptr [esi+eax*2+2], 0F
		; ...
		; patched bytes:
BASE:6754C		xor edx, edx
BASE:6754E		cmp [TSW_BGM_ID], 0
BASE:67555		je loc_noBGM_2
BASE:67557		add [ebx], 2
BASE:6755A		add eax, 6
BASE:6755D		mov dword ptr [esi+eax*2-6], edx
BASE:67561		mov word ptr [esi+eax*2-2], dx
BASE:67566		mov dword ptr [esi+eax*2], 00050001
BASE:6756D		mov word ptr [esi+eax*2+4], 000C	; (1,5,12) BGM #12=fairy's theme
BASE:67574	loc_noBGM_2:
			add [ebx], 2
BASE:67577		add eax, 6
BASE:6757A		mov dword ptr [esi+eax*2-6], edx
BASE:6757E		mov word ptr [esi+eax*2-2], dx
BASE:67583		mov dword ptr [esi+eax*2], 000F000A	; (10,15,0) show 15th dialog
		; ...

		; 20F Vampire: stop the boss battle BGM and its soundeffect after it is defeated; play Fairy's theme BGM after it says its last words
		; Here, orginally, [(0,0,0);(1,6,0);](0,0,0);(0A,0015,0); now, [(0,0,0);(1,5,0C);](0,0,0);(0A,0015,0);[(0,0,0);(1,5,01FF);]. The sequences in [brackets] are processed only if BGM is on. Note the execution of these event sequences is in the reversed order
BASE:686A6		cmp [ebp+0168], 0	; [TSW_BGM_ID]
BASE:686AD		je loc_noBGM_3
BASE:686AF		inc [ebx]
BASE:686B1		mov eax, [ebx]
BASE:686B3		lea eax, [eax+eax*2]
BASE:686B6		mov word ptr [esi+eax*2], 0
BASE:686BC		mov eax, [ebx]
BASE:686BE		lea eax, [eax+eax*2]
BASE:686C1		mov word ptr [esi+eax*2+2], 0
BASE:686C8		mov eax, [ebx]
BASE:686CA		lea eax, [eax+eax*2]
BASE:686CD		mov word ptr [esi+eax*2+4], 0
BASE:686D4		inc [ebx]
BASE:686D6		mov eax, [ebx]
BASE:686D8		lea eax, [eax+eax*2]
BASE:686DB		mov word ptr [esi+eax*2], 1
BASE:686E1		mov eax, [ebx]
BASE:686E3		lea eax, [eax+eax*2]
BASE:686E6		mov word ptr [esi+eax*2+2], 6
		; original bytes:
;BASE:686ED		mov eax, [ebx]
;BASE:686EF		lea eax, [eax+eax*2]
;BASE:686F2		mov word ptr [esi+eax*2+4], 0
;BASE:686F9		inc [ebx]
;BASE:686FB		mov eax, [ebx]
;BASE:686FD		lea eax, [eax+eax*2]
;BASE:68700		mov word ptr [esi+eax*2], 0
;BASE:68706		mov eax, [ebx]
;BASE:68708		lea eax, [eax+eax*2]
;BASE:6870B		mov word ptr [esi+eax*2+2], 0
;BASE:68712		mov eax,[ebx]
;BASE:68714		lea eax,[eax+eax*2]
;BASE:68717		mov word ptr [esi+eax*2+4], 0
;BASE:6871E		inc [ebx]
;BASE:68720		mov eax, [ebx]
;BASE:68722		lea eax, [eax+eax*2]
;BASE:68725		mov word ptr [esi+eax*2], 000A
;BASE:6872B		mov eax, [ebx]
;BASE:6872D		lea eax, [eax+eax*2]
		; ...
		; patched bytes:
BASE:686ED		mov dword ptr [esi+eax*2+2], 000C0005	; this overwrites 6 with 5, so now the whole sequence is (1,5,12) BGM #12=fairy's theme
BASE:686F5		xor edx,edx
BASE:686F7		jmp loc_BGM_4	; note the `je` opcode @BASE:686AD, we have to bypass loc_noBGM_3

BASE:686F9	loc_noBGM_3:
			xor edx, edx	; edx needs to be 0 before assignment of other memory values
BASE:686FB		jmp loc_noBGM_4	; bypass loc_BGM_4

BASE:686FD	loc_BGM_4:
			add [ebx], 2	; with BGM on, there will be 2 more event sequences
BASE:68700		mov dword ptr [esi+eax*2+12], edx	; the 2 sequences, 0C bytes in total, will be written after (10,21,0), i.e. executed before (10,21,0) as the sequences are executed in the reversed order
BASE:68704		mov word ptr [esi+eax*2+16], dx
BASE:68709		mov dword ptr [esi+eax*2+18], 00050001
BASE:68711		mov word ptr [esi+eax*2+1C], 01FF	; (1,5,0x1FF) means stop both the BGM (the low byte FF) and the soundeffect (the high byte 01); see `sub_instruct_playBGM` for more details

BASE:68718	loc_noBGM_4:
			add [ebx], 2
BASE:6871B		add eax, 6
BASE:6871E		mov dword ptr [esi+eax*2-6], edx
BASE:68722		mov word ptr [esi+eax*2-2], dx
BASE:68727		mov dword ptr [esi+eax*2], 0015000A	; (10,21,0) show 21st dialog
BASE:6872E		jmp BASE:6873C
		; patch ends

BASE:68730		mov word ptr [esi+eax*2+2], 0015
BASE:68737		mov eax, [ebx]
BASE:68739		lea eax, [eax+eax*2]	; these 3 lines won't be executed after patching

BASE:6873C		mov word ptr [esi+eax*2+4], 0
		; ...

BASE:68BB6	; 25F Archsorcerer: play Fairy's theme BGM like on 10F; omitted
		; ...

		; 40F GoldenKnight: play Fairy's theme BGM after everything is done
		; Here, orginally, [(1,6,0)]; now, [(1,5,0C)]. The sequences in [brackets] are processed only if BGM is on.
		; ...
BASE:6AB14		mov word ptr [esi+eax*2], 1
BASE:6AB1A		mov eax, [ebx]
BASE:6AB1C		lea eax, [eax+eax*2]
BASE:6AB1F		mov word ptr [esi+eax*2+2], 6
		; original bytes:
;BASE:6AB26		mov eax, [ebx]
;BASE:6AB28		lea eax, [eax+eax*2]
;BASE:6AB2B		mov word ptr [esi+eax*2+4], 0
		; ...
		; patched bytes:
BASE:6AB26		mov dword ptr [esi+eax*2+2], 000C0005	; this overwrites 6 with 5, so now the whole sequence is (1,5,12) BGM #12=fairy's theme
BASE:6AB2E		nop
BASE:6AB2F		nop
BASE:6AB30		nop
BASE:6AB31		nop

BASE:6BF97	; 49F Zeno: play Fairy's theme BGM like on 40F; omitted
		; ...

		; 50F Zeno (>= 2nd round): stop Last-Battle BGM after it is defeated
		; Here, orginally, (0,0,0);(0A,3E,0063); now I insert (1,6,0) at the end if BGM is on. Note the execution of these event sequences is in the reversed order
BASE:6CABF		mov word ptr [esi+eax*2], 0
		; original bytes:
;BASE:6CAC5		mov eax, [ebx]
;BASE:6CAC7		lea eax, [eax+eax*2]
;BASE:6CACA		mov word ptr [esi+eax*2+2], 0
;BASE:6CAD1		mov eax, [ebx]
;BASE:6CAD3		lea eax, [eax+eax*2]
;BASE:6CAD6		mov word ptr [esi+eax*2+4], 0
;BASE:6CADD		inc [ebx]
;BASE:6CADF		mov eax, [ebx]
;BASE:6CAE1		lea eax, [eax+eax*2]
;BASE:6CAE4		mov word ptr [esi+eax*2], 000A
;BASE:6CAEA		mov eax, [ebx]
;BASE:6CAEC		lea eax, [eax+eax*2]
;BASE:6CAEF		mov word ptr [esi+eax*2+2], 003E
;BASE:6CAF6		mov eax, [ebx]
;BASE:6CAF8		lea eax, [eax+eax*2]
;BASE:6CAFB		mov word ptr [esi+eax*2+4], 0063
		; ...
		; patched bytes:
BASE:6CAC5		xor edx, edx
BASE:6CAC7		mov [esi+eax*2+2], edx
BASE:6CACB		inc [ebx]
BASE:6CACD		add eax, 3
BASE:6CAD0		mov [esi+eax*2], 003E000A
BASE:6CAD7		mov word ptr [esi+eax*2+4], 0063	; (10,62,99) show 62nd dialog
BASE:6CADE		cmp [TSW_BGM_ID], 0
BASE:6CAE5		je loc_noBGM_5
BASE:6CAE7		add [ebx], 2
BASE:6CAEA		add eax, 6
BASE:6CAED		mov dword ptr [esi+eax*2-6], edx
BASE:6CAF1		mov word ptr [esi+eax*2-2], dx	; (0,0,0)
BASE:6CAF6		mov dword ptr [esi+eax*2], 00060001
BASE:6CAFD		mov word ptr [esi+eax*2+4], dx	; (1,6,0) stop BGM
BASE:6CB02	loc_noBGM_5:
		; ...

		TTSW10.moncheck	endp

BASE:6CB1C	TTSW10.ichicheck	proc near	; Checks if there is any special events to process after the player moves into a new position (such as a trap)
		; ...
BASE:6F2E3	; 10F SkeletonA: play boss battle BGM (id=15) after it says its welcoming words
		; Here, orginally, (0,0,0); | ;(0A,0D,0); now I insert (1,5,0F) into the `|` position if BGM is on. Note the execution of these event sequences is in the reversed order
		; Likewise for 10F `moncheck`; omitted
		; ...
BASE:727DF	; 25F Archsorcerer: play boss battle BGM (id=7) after it says its welcoming words
		; Here, orginally, (0,0,0); | ;(0A,0017,0); now I insert (1,5,7) into the `|` position if BGM is on. Note the execution of these event sequences is in the reversed order
		; Likewise for 25F `moncheck`; omitted
		; ...
BASE:73FB4	; 40F GoldenKnight: stop boss battle BGM after everything is over
		; Here, orginally, (0,0,0); | ;(6,5,0B) (6,5,11 means turning the tile at X=5,Y=1 into the upstaris tile); now I insert (1,6,0) into the `|` position if BGM is on. Note the execution of these event sequences is in the reversed order
		; like above; omitted
		; ...
BASE:75EAA	; 40F GoldenKnight: play boss battle BGM (id=18) after it says its welcoming words
		; Here, orginally, (0,0,0); | ;(0A,0022,0); now I insert (1,5,0012) into the `|` position if BGM is on. Note the execution of these event sequences is in the reversed order
		; like above; omitted
		; ...
BASE:7600B	; 42F GoldenKnight meats Zeno: play Block5 BGM (id=9) and stop Zeno's soundeffect after it is killed by Zeno and Zeno disappears
		; Here, orginally, (0,0,0); | ;(1,2,0) (1,2,0 means playing the "get (or trap)" soundeffect); now I insert (1,5,0109) into the `|` position if BGM is on (the high-byte 01 means muting the soundeffect). Note the execution of these event sequences is in the reversed order
		; like above; omitted
		; ...

		; 42F GoldenKnight meats Zeno: stop playing Block5 BGM
		; Here, orginally, (0,0,0); now, [(1,6,0) if BGM is on]
		; original bytes:
;BASE:76853		mov word ptr [esi+eax*2], 0
;BASE:76859		mov eax, [ebx]
;BASE:7685B		lea eax, [eax+eax*2]
;BASE:7685E		mov word ptr [esi+eax*2+2], 0
;BASE:76865		mov eax, [ebx]
;BASE:76867		lea eax, [eax+eax*2]
		; ...
		; patched bytes:
BASE:76853		mov [esi+eax*2], 0
BASE:7685A		cmp [TSW_BGM_ID], 0
BASE:76861		je loc_noBGM_6
BASE:76863		mov [esi+eax*2], 00060001	; (1,6,0) stop BGM
		; patch ends

BASE:7686A	loc_noBGM_6:
			mov word ptr [esi+eax*2+4], 0
		; ...

		; After you enters the gate on 24F and meets Zeno on 50F: play Last-Battle BGM (id=10) and stop Zeno's soundeffect
		; Here, orginally, (0,0,0); now, add [(1,5,010A) at the end if BGM is on] (the high-byte 01 means muting the soundeffect)
		; original bytes:
BASE:70E27		cmp [TSW_BGM_ID], 0
BASE:70E2E		je loc_noBGM_7
BASE:70E30		inc [ebx]
		; original bytes:
;BASE:70E32		mov eax, [ebx]
;BASE:70E34		lea eax, [eax+eax*2]
;BASE:70E37		mov word ptr [esi+eax*2], 0F
;BASE:70E3D		mov eax, [ebx]
;BASE:70E3F		lea eax, [eax+eax*2]
;BASE:70E42		mov word ptr [esi+eax*2+0], 0
		; ...
		; patched bytes:
BASE:70E32		mov edx, [esi+eax*2]
BASE:70E35		mov dword ptr [esi+eax*2], 00050001
BASE:70E3C		mov word ptr [esi+eax*2+4], 010A
BASE:70E43		add eax, 3
BASE:70E46		mov dword ptr [esi+eax*2], edx
		; patch ends

BASE:70E49		mov eax, [ebx]
BASE:70E4B		lea eax, [eax+eax*2]
BASE:70E4E		mov word ptr [esi+eax*2+4], 0
BASE:70E55	loc_noBGM_7:
		; ...

		TTSW10.ichicheck	endp

BASE:44DA10	TTSW10.Button1Click	proc near	; This is the "OK" button when showing the dialog with oldmen; bosses; etc.
		; ...
		; After you meets Zeno on 3F and are put into prison, originally, the Block1 BGM starts when you start a dialog with Thief. Now, I think it is better to turn on the BGM once Thief tries to wake you up

BASE:4DC71		xor eax,eax
BASE:4DC73		mov [BASE:B86B8], eax
		; original bytes:
;BASE:4DC78		xor eax, eax	; this is not necessary because eax is already 0
;BASE:4DC7A		mov [BASE:8C5AC], eax	; pointer to the current event sequence
;BASE:4DC7F		mov eax, ebx	; TTSW10 handle
;BASE:4DC81		call BASE:42C38	; TTSW10.mhyouji: displays or refreshes the player on the map
;BASE:4DC86		xor edx, edx
;BASE:4DC88		mov eax, [ebx+01CC]	; TRichEdit1
;BASE:4DC8E		call BASE:13500	; TControl.SetVisible: this sets the dialog box invisible
;BASE:4DC93		xor edx, edx
;BASE:4DC95		mov eax,[ebx+01CC]
;BASE:4DC9B		call BASE:135D4	; TControl.SetText: this clears the content of the dialog box, but it is not necessary because its text will be changed everytime it is shown
;BASE:4DCA0		mov eax, ebx
;BASE:4DCA2		call TTSW10.itemlive
		; ...
		; patched bytes:
BASE:4DC78		mov [BASE:8C5AC], eax	; pointer to the current event sequence
BASE:4DC7D		mov eax, ebx	; TTSW10 handle
BASE:4DC7F		call BASE:42C38	; TTSW10.mhyouji: displays or refreshes the player on the map
BASE:4DC84		mov edx, [TSW_BGM_ID]
BASE:4DC8A		test edx, edx
BASE:4DC8C		je loc_noBGM_8
BASE:4DC8E		mov dl, 05
BASE:4DC90		call sub_instruct_playBGM_direct	; at the end of this subroutine, edx will be set as 0, used in the next call below
BASE:4DC95		mov eax, [ebx+01CC]
BASE:4DC9B		call BASE:13500	; TControl.SetVisible: this sets the dialog box invisible when edx=0
BASE:4DCA0		mov eax,ebx
BASE:4DCA2		call itemlive
BASE:4DCA2	loc_noBGM_8:
		;...

		TTSW10.Button1Click	endp

BASE:4ED94	TTSW10.Button8Click	proc near	; This is the "UP" button when using Orb of Flight
		; in TSW, the BGM stops immediately you use Orb of Flight, but I think a better design is to stop the BGM only when you fly to a floor with a different BGM. So the judgement should be added here
		; likewise for BASE:618A1 in TTSW10.timer3ontimer, because Timer3 will be working in replacement of Button8Click when holding down mouse on Button8 (UP)
		; ...
BASE:4EDB2		cmp [TSW_hero_floor], 2B	; if on 43F, go up to 45F
		; original bytes:
;BASE:4EDB9		je BASE:4EDC3
;BASE:4EDBB		inc [TSW_hero_floor]
;BASE:4EDC1		jmp BASE:4EDCA
;BASE:4EDC3		add [TSW_hero_floor], 2
		; patched bytes:
BASE:4EDB9		mov eax, offset TSW_hero_floor
BASE:4EDBE		jne loc_not44F_1
BASE:4EDC0		inc [eax]
BASE:4EDC2	loc_not44F_1:
			inc [eax]
BASE:4EDC4		call sub_checkOrbFlight	; this is also called in BASE:81F6E in `TTSW10.img4work`, which is called when Orb of Flight is used
BASE:4EDC9		nop
		; ...

		TTSW10.Button8Click	endp

BASE:4ED1C	TTSW10.Button9Click	proc near	; This is the "DOWN" button when using Orb of Flight
		; likewise for BASE:618D9 in TTSW10.timer3ontimer when holding down mouse on Button9
		; ...
BASE:4ED32		cmp [TSW_hero_floor], 2D	; if on 45F, go up to 43F
		; original bytes:
;BASE:4ED39		je BASE:4ED43
;BASE:4ED3B		dec [TSW_hero_floor]
;BASE:4ED41		jmp BASE:4EDCA
;BASE:4ED43		sub [TSW_hero_floor], 2
		; patched bytes:
BASE:4ED39		mov eax, offset TSW_hero_floor
BASE:4ED3E		jne loc_not44F_2
BASE:4ED40		dec [eax]
BASE:4ED42	loc_not44F_2:
			dec [eax]
BASE:4ED44		call sub_checkOrbFlight
BASE:4ED49		nop
		; ...

		TTSW10.Button9Click	endp

BASE:50880	TTSW10.itemlive	proc near	; if during an event, some menu items and buttons will be disabled; after the event is done, they are turned back "alive" by calling `TTSW10.itemlive`
		; ...
		; TTSW10.TTimer4 was used to show the prolog animation; in tswBGM, instead, it is used to achieve the fading out effect of BGM. Therefore, it is necessary to patch the places where the enablity of Timer4 was checked (to judge whether is in the middle of the prolog)
		; likewise for BASE:556BE, BASE:556D2, BASE:558D9, BASE:55AF1, and BASE:55B40 in TTSW10.syokidata2; BASE:637F5 in TTSW10.GameStart1Click; BASE:7C2A3 in TTSW10.BGMOn1Click; and BASE:80EFB in TTSW10.MouseControl1Click

BASE:5089F		mov eax, [ebx+TTSW10.TTimer4]
BASE:508A5		cmp byte ptr [eax+TTimer.Enabled], 0	; if TTimer4.Enabled is 0
		; original bytes:
;BASE:508A9		jne BASE:50913	; if TTimer4.Enabled != 0, then do not execute the following opcodes
		; patched bytes:
BASE:508A9		jnp BASE:50913	; if TTimer4.Enabled has an odd parity, such as 1, then do not execute the following opcodes
		; in tswBGM, when the TTimer4 is enabled, the TTimer4.Enabled byte is set to 6, which is an even number and has an even parity, just like 0 (disabled), so the old opcodes that would have been elicited by TTimer4.Enabled == 1 are not elicited now
		; ...

		TTSW10.itemlive	endp

BASE:64048	TTSW10.opening2	proc near	; animation after you meets Zeno on 3F
		; originally, the opening BGM (id=11) starts to early; now, I think it is better to delay it until the captions show (Now is the time...)
		; Here, orginally, (0,0,0);(0,0,0); now, add [(1,5,010B) at the beginning if BGM is on] (the high-byte 01 means muting Zeno's soundeffect)
		; ...
BASE:6431B		inc [ebx]
		; original bytes:
;BASE:6431D		mov eax, [ebx]
;BASE:6431F		lea eax, [eax+eax*2]
;BASE:64322		mov word ptr [esi+eax*2], 0
;BASE:64328		mov word ptr [esi+eax*2+2], 0
;BASE:6432F		mov word ptr [esi+eax*2+4], 0
;BASE:64336		inc [ebx]
;BASE:64338		mov eax, [ebx]
;BASE:6433A		lea eax, [eax+eax*2]
;BASE:6433D		mov word ptr [esi+eax*2], 0
;BASE:64343		mov word ptr [esi+eax*2+2], 0
		; patched bytes:
BASE:6431D		add eax, 3
BASE:64320		cmp [TSW_BGM_ID], 0
BASE:64327		je loc_noBGM_9
BASE:64329		mov dword ptr [esi+eax*2], 00050001
BASE:64330		mov word ptr [esi+eax*2+4], 010B	; (1,5,0x010B) BGM #11=opening theme; mute soundeffect
BASE:64337		add [ebx], 2
BASE:6433A		add eax, 3
BASE:6433D		xor edx, edx
BASE:6433F		mov dword ptr [esi+eax*2], edx
BASE:64342		mov dword ptr [esi+eax*2+4], edx
BASE:64346		mov dword ptr [esi+eax*2+8], edx
		; patch ends

BASE:6434A		mov word ptr [esi+eax*2+04], 0	; this line is actually useless after patching
BASE:64351	loc_noBGM_9:
		; ...

		TTSW10.opening2	endp

BASE:7C2BC	TTSW10.soundplay	proc near	; play the BGM
		; no need to care the original commands; the whole function will be replaced by `sub_soundplay_real`
		; patched bytes:
BASE:7C2BC		mov eax, [eax+TTSW10.TTimer4]
BASE:7C2C2		mov dl, 06	; to differentiate this enabled state from TSW's intrinsic enabled state of TTimer4, set TTimer.Enabled to 6 rather than 1
BASE:7C2C4		jmp TTimer.SetEnabled

		TTSW10.soundplay	endp

BASE:7C8F9	TTSW10.soundcheck	proc near	; judge the BGM id to play according to the floor number
		; original bytes:
;BASE:7C8F9		mov eax, [TSW_hero_floor]
		; patched bytes:
BASE:7C8F9		call sub_checkBGM_ext	; judge the BGM id more accurately, such as whether the game is over and whether in the middle of a boss battle

		; ...
		; original bytes:
;BASE:7C960	loc_40to49F:
;			mov [TSW_BGM_ID], 09
;BASE:7C96A		ret
;BASE:7C96B	loc_50F:
;			mov [TSW_BGM_ID], 0A
		; patched bytes:
BASE:7C960	loc_40to49F:
			add eax, 06	; 44F: F-50+6=0
BASE:7C963		je loc_44F
BASE:7C965		mov al, -0D	; 41-49F, not 44F: -13 + 12 + 10 = 9
BASE:7C967		nop
BASE:7C968	loc_44F:
			add eax, 0C	; 44F: 0 + 12 + 10 = 22
BASE:7C96A		nop
BASE:7C96B	loc_50F:
			add al, 0A	; 50F: 0 + 10 = 10
BASE:7C96D		movzx eax, al
BASE:7C970		mov [TSW_BGM_ID], eax

BASE:7C975	loc_ret01:
			ret

BASE:7C975	TTSW10.soundcheck	endp

BASE:82A98	TTSW10.timer4ontimer	proc near	; This was the timer used for the prolog animation in TSW; will be used to fade out BGM in tswBGM
		; need to judge whether is the former or the latter case
		; ...
BASE:82AB6		mov eax, [BASE:8C56C]	; 0 to 20 which marks the animation progress
		; original bytes:
;BASE:82ABB		sub eax, 8
;BASE:82ABE		jb loc_350ms
;BASE:82AC0		sub eax, 7
;BASE:82AC3		jb loc_250ms
;BASE:82AC5		sub eax, 6	; this is not necessary
;BASE:82AC8		jb loc_150ms	; as eax here won't exceed 20
;BASE:82ACA		jmp loc_next_2
;BASE:82ACC	loc_350ms:
;			mov edx, 015E
;BASE:82AD1		mov eax, [ebx+TTSW10.TTimer4]
;BASE:82AD7		call TTimer.SetInterval
;BASE:82ADC		jmp loc_next_2
;BASE:82ADE	loc_250ms:
;			mov edx, 0FA
;		; ...
		; patched bytes:
BASE:82ABB		cmp byte ptr [isInProlog], 0	; if `isInProlog` is 0, then go to the treatment of tswBGM
BASE:82AC2		jne loc_orig_timer4	; otherwise, original treatment
BASE:82AC4		push offset loc_end_timer4ontimer	; this is where this function finalizes (pop registers and return)
BASE:82AC9		jmp sub_timer4ontimer_real	; instead of `call xxx`, `push`+`jmp` is used to explicitly assign where to return
BASE:82ACE	loc_orig_timer4:
			mov edx, 015E
BASE:82AD3		sub eax, 8
BASE:82AD6		jb loc_350ms
BASE:82AD8		sub eax, 7
BASE:82ADB		jb loc_250ms
BASE:82ADD		jmp loc_150ms
BASE:82ADF	loc_250ms:
			sub edx, 0064
BASE:82AE2	loc_350ms:
			nop

BASE:82AE3		mov eax, [ebx+TTSW10.TTimer4]
BASE:82AE9		call TTimer.SetInterval
BASE:82AEE		jmp loc_next_2
BASE:82AF0	loc_150ms:
		; ...
BASE:82B00	loc_next_2:
		; ...

		TTSW10.timer4ontimer	endp


BASE:7EADC	TTSW10.savework	proc near	; called when saving data
		; Changes made: do not save [TSW_BGM_ID] into data
		; This might worth a bit explanation here. I think this is likely a bug of TSW not a feature:
		; If you save a data while BGM is on, then [TSW_BGM_ID] goes into this data. When you load this data, even if you set BGM off in the options, BGM will still be turned on. This is because a non-zero [TSW_BGM_ID] value is loaded into the memory. On the other hand, however, if you save a data while BGM is off, then when you load this data, BGM state will not change (i.e., if BGM is on, it will remain on)
		; This is definitely a design flaw. Each other option has its own variable to determine its state, and they will be loaded by your saved *options* not saved *data*. On the contrary, there are multiple things that can determine whether BGM is on: sometimes the checked state of the menu item, sometimes a boolean byte variable [TSW_BGM_setting], and sometimes whether [TSW_BGM_ID] is zero. These can be at odds with others and can be quite chaotic
		; So my decision is to exclude [TSW_BGM_ID] in the saved data, so when you load a data, only the current options will be taken into consideration, i.e., if BGM is on, it remains on; and if BGM is off, it remains off, just like all other options

		; ...
		; original bytes:
;BASE:7EBAD		push 0
;BASE:7EBAF		mov edx, offset BASE:B8934	; map data starting from BASE:B8934
;BASE:7EBB4		mov ecx, 00001881	; with a length of 0x1881 bytes
;BASE:7EBB9		mov eax, offset BASE:8C600	; TSW_file_handle
;BASE:7EBBE		call BASE:04254	; @BlockWrite
;BASE:7EBC3		call BASE:02710	; @_IOTest
;BASE:7EBC8		push 0
;BASE:7EBCA		mov edx, offset BASE:B8688	; player data starting from BASE:B8688 (TSW_hero_status)
;BASE:7EBCF		mov ecx, 000002AC	; with a length of 0x02AC bytes
;BASE:7EBD4		mov eax, offset BASE:8C600	; TSW_file_handle
;BASE:7EBD9		call BASE:04254	; @BlockWrite
;BASE:7EBDE		call BASE:02710	; @_IOTest
;BASE:7EBE3		mov eax, offset BASE:8C600	; TSW_file_handle
;BASE:7EBE8		call BASE:042B8	; @Close
;BASE:7EBED		call BASE:02710	; @_IOTest
;BASE:7EBF2		mov dword ptr [BASE:8C58C], 0086	; TSW_tedit8_msg_id = 0x86 ("Saved the game.")
		; ...
		; patched bytes:
BASE:7EBAD		xor edi,edi	; edi will be restored at the end of `savework`
BASE:7EBAF		mov eax, [BASE:8C600]	; [TSW_file_handle]
BASE:7EBB4		push eax	; hObject
		; up to here we have pushed the parameter for the `CloseHandle` call
BASE:7EBB5		lea ecx, [ebp-08]	; see `savework`: vacant space on stack; suitable to be the pointer of `lpNumberOfBytesWritten`
BASE:7EBB8		push edi	; lpOverlapped (0)
BASE:7EBB9		push ecx	; lpNumberOfBytesWritten
BASE:7EBBA		push 02AC	; nNumberOfBytesToWrite
BASE:7EBBF		push offset BASE:B8688	; lpBuffer
BASE:7EBC4		push eax	; hFile
		; up to here we have pushed all parameters for the second `WriteFile` call
BASE:7EBC5		push edi	; lpOverlapped (0)
BASE:7EBC6		push ecx	; lpNumberOfBytesWritten
BASE:7EBC7		push 1881	; nNumberOfBytesToWrite
BASE:7EBCC		mov edx, offset BASE:B8934
BASE:7EBD1		push edx	; lpBuffer
BASE:7EBD2		push eax	; hFile
		; up to here we have pushed all parameters for the first `WriteFile` call
BASE:7EBD3		mov esi, offset TSW_BGM_ID	; esi will be restored at the end of `savework`
BASE:7EBD8		xchg [esi], edi	; [TSW_BGM_ID] -> 0; edi -> old [TSW_BGM_ID]
		; Another important thing about data saving is the checksum. TSW will refuse to load a data if the checksum is wrong, which indicates the data is corrupted. (In practice, before you load a data, TSW will save the current status to `save0.dat`, and then it loads the data: If the data is not alright, TSW will pop up a messagebox saying "Do not use this data," and then load back `save0.dat`)
		; [TSW_DataCheck1] is the sum of 0xA4 dword variables starting from offset TSW_hero_status; [TSW_DataCheck2] adds up all odd-numbered variables in the range above, and then minuses all even-numbered variables
		; TSW_BGM_ID is odd-numbered, so if we set it as 0, both [TSW_DataCheck1] and [TSW_DataCheck2] should be subtracted by its original value to ensure data integrity
BASE:7EBDA		sub [edx-1C], edi	; [TSW_DataCheck1]; subtract this value from this checksum (sum of all variables)
BASE:7EBDD		sub [edx-18], edi	; [TSW_DataCheck2]; subtract this value from this checksum (sum of all odd-numbered variables minus all even-numbered variables)
BASE:7EBE0		call kernel32.WriteFile
BASE:7EBE5		call kernel32.WriteFile
BASE:7EBEA		call kernel32.CloseHandle
BASE:7EBEF		mov [esi], edi	; restore [TSW_BGM_ID]
BASE:7EBF1		nop
		; ...
		; Above, the treatments are for the case where a data file already exists, and new data will overwrite the old file
		; Below, the treatments are for the case where no such data file was existent previously, so a new file will be created
		; The codes are exactly the same
		; original bytes:
;BASE:7EC3A		push 0
			; ... (same as above)
		; ...
		; patched bytes:
BASE:7EC3A		xor edi, edi
			; ... (same as above)
		; ...

		TTSW10.savework	endp

BASE:54DE8	TTSW10.syokidata2	proc near	; called upon game status refreshing, such as restarting a game / loading a game / changing game window size / initialize all options / etc.
		; Changes made:
		; * do not change BGM or WAV options when loading data
		; * when loading data, stop the previous sound effect
		; Like above, the treatments of WAV (soundeffect) are also chaotic. There are multiple things that can determine whether WAV is on: sometimes the checked state of the menu item, sometimes a boolean byte variable [TSW_WAV_setting(BASE:89BA3)] (like [TSW_BGM_setting(BASE:89BA2)]), and sometimes DWORD variable [TSW_WAV_OFF(BASE:B87EC)] (like [TSW_BGM_ID(BASE:B87F0)]). For the latter two, a value of 0 means WAV on, and a value of 1 means WAV off
		; If the current WAV is off, loading a data where WAV is on will turn WAV on, and the corresponding menu item will be ticked. If the current WAV is on, loading a data where WAV is off will turn WAV off, but the corresponding menu item will NOT be unticked. I think this is likely a bug of TSW not a feature.
		; So my decision is to retain old BGM / WAV options after loading a data, i.e., if BGM is on, it remains on; and if BGM is off, it remains off, just like all other options. This is achieved by referring to the byte variables [TSW_WAV_setting] and [TSW_BGM_setting] as discussed above
		; ...
		; original bytes:
;BASE:55AAB		cmp dword ptr [esi+0164], 0	; [TSW_WAV_OFF]
;BASE:55AB2		jne BASE:55AC1
;BASE:55AB4		mov dl, 01
;BASE:55AB6		mov eax, [ebx+032C]	; TTSW10.wavon1:TMenuItem
;BASE:55ABC		call TMenuItem.SetChecked

;BASE:55AC1		cmp dword ptr [esi+0168], 0	; [TSW_BGM_ID]
;BASE:55AC8		je BASE:55ADE
;BASE:55ACA		mov dl, 01
;BASE:55ACC		mov eax, [ebx+0330]	; TTSW10.BGMON1:TMenuItem
;BASE:55AD2		call TMenuItem.SetChecked
;BASE:55AD7		mov byte ptr [TSW_BGM_setting], 1
;BASE:55ADE		cmp dword ptr [esi+0168],00	; [TSW_BGM_ID]
;BASE:55AE5		je loc_syokidata2_next
;BASE:55AE7	loc_syokidata2_BGM_on:
;			mov eax,[ebx+041C]	; TTSW10.Timer4
;BASE:55AED		cmp byte ptr [eax+20], 0	; TTimer.FEnabled:Boolean
;BASE:55AF1		jne loc_syokidata2_next
;BASE:55AF3		mov eax, ebx
;BASE:55AF5		call TTSW10.soundplay
;BASE:55AFA	loc_syokidata2_next:
		; ...
		; patched bytes:
BASE:55AAB		mov edi, offset TSW_WAV_setting	; edi is vacant in this subroutine; will be restored at the end
BASE:55AB0		cmp byte ptr [edi], 0
BASE:55AB3		jne BASE:55AC0	; !=0: WAV is off; otherwise, stop the previous sound effect
BASE:55AB5		mov eax, [ebx+TTSW10.TMediaPlayer6]
BASE:55ABB		call TMediaPlayer.Close

BASE:55AC0		mov edx, offset TSW_WAV_OFF
BASE:55AC5		mov al, [edi]
BASE:55AC7		mov [edx], al	; read [TSW_WAV_OFF] from [TSW_WAV_setting]
BASE:55AC9		mov al, [edi-01]	; [TSW_BGM_setting]
BASE:55ACC		test al, al
BASE:55ACE		jne loc_syokidata2_BGM_on
BASE:55AD0		mov [edx+04], al	; read [TSW_BGM_ID] from [TSW_BGM_setting]=0
BASE:55AD3		jmp loc_syokidata2_next
		; it is found that there is no need to set the enabled states for the menu items, as they will be set elsewhere
		; ...


; ==========


EXTRA:0000	; Injected buffer by tswSL

EXTRA:0000	bgm_basename_addr	:= dword ptr EXTRA:0A0E	; the index where to replace 'A_027XGW' with the actual BGM filename to play
			; this is just an example; if `bgm_filename` changes, the index will of course change accordingly

		; char bgm_filename[0x104]
EXTRA:0A00	bgm_filename	db 'C:\tswBGM\BGM\A_027XGW.mp3',0
			; this is just an example; if the path of tswBGM is different, this string will of course change accordingly
EXTRA:0A1A		align 0104	; len = MAX_PATH

EXTRA:0B04	bgm_phantomfloor_str	dd 'b_09', '5xgw'	; "b_095xgw.mp3" (new BGM for 44F added in TSW3D v1.8)

EXTRA:0B0C	isInProlog	db 1	; the time when tswBGM is started, if TTimer4 is still enabled (meaning still in prolog), then initialization will be delayed because we can't use TTimer4 now
EXTRA:0B0D		align 04
EXTRA:0B10	last_bgmid	db 0	; if TSW_BGM_ID == last_bgmid, then do nothing
EXTRA:0B11		align 04

EXTRA:0B14	mci_params: 
			istruc MCI_GENERIC_PARMS
			at MCI_GENERIC_PARMS.dwCallback,	dd 0
			at MCI_DGV_SETAUDIO_PARMS.dwItem,	dd MCI_DGV_SETAUDIO_VOLUME
EXTRA:0B1C		at MCI_DGV_SETAUDIO_PARMS.dwValue,	dd 03E8	; range is [0, 1000]
			iend
EXTRA:0B1C	mci_audio_volume	db 03E8	; this is included in the struct mci_params

		;===== SUBROUTINE =====
EXTRA:0B20	sub_soundplay_real	proc near	; set BGM filename in replacement of TTSW10.soundplay

			push ebp
EXTRA:0B21		mov ebp, esp
EXTRA:0B23		push 0
EXTRA:0B25		push ebx
EXTRA:0B26		push esi
EXTRA:0B27		push edi
EXTRA:0B28		mov ebx, eax
EXTRA:0B2A		xor eax, eax
EXTRA:0B2C		push ebp
EXTRA:0B2D		push BASE:7C70C	; handle finally
EXTRA:0B32		push fs:[eax]
EXTRA:0B35		mov fs:[eax], esp	; so far: error handling for TTSW10.soundplay
EXTRA:0B38		mov eax, [TSW_BGM_ID]
EXTRA:0B3D		add eax, -05
EXTRA:0B40		cmp eax, 0011	; bgm id from [5, 22]
EXTRA:0B43		ja loc_final	; ignore if bgm id > 22
EXTRA:0B45		mov edi, offset bgm_basename_addr
EXTRA:0B4A		mov esi, offset bgm_phantomfloor	; bgm id == 22 (new BGM added for 44F in TSW3D v1.8)
EXTRA:0B4F		je loc_assignFname
EXTRA:0B51		imul esi, eax, 001C	; bgm id != 22, then
EXTRA:0B54		add esi, offset TSW_BGM_basename	; starting address is TSW_BGM_basename + 0x1c*(TSW_BGM_ID-5)

EXTRA:0B5A	loc_assignFname:
			cld
EXTRA:0B5B		movsd
EXTRA:0B5C		movsd	; move 8 bytes data because the basename is 8 bytes long excluding the extname

EXTRA:0B5D	loc_final:
			jmp BASE:7C6D3	; continue in TTSW10.soundplay (filename already specified; still need to open and play the file)

		sub_soundplay_real	endp
EXTRA:0B62	align 04


		;===== SUBROUTINE =====
EXTRA:0B64	sub_timer4ontimer_real	proc near	; in replacement of TTSW10.timer4ontimer, use TTimer4 to achieve the effect of fading out BGM; in addition, ignore the change of BGM ID within the first 150 ms (i.e. `TTSW10.TTimer4.Interval`) because sometimes different BGM IDs may be assigned in a short time, and only the latest one is used

			mov eax, offset mci_params
EXTRA:0B69		cmp [eax+MCI_DGV_SETAUDIO_PARMS.dwValue], 03E8	; if the audio volume is 1000 (volume ranges from 0 to 1000)
EXTRA:0B70		jne loc_fadeout
EXTRA:0B72		mov edx, [TSW_BGM_ID]
EXTRA:0B78		cmp dl, byte ptr [last_bgmid]
EXTRA:0B7E		jne loc_fadeout

EXTRA:0B80		mov eax, [ebx+TTSW10.TTimer4]	; if fading out has not started and the BGM id is the same as the last time, then do not do anything (disable this timer)
EXTRA:0B86		xor edx, edx
EXTRA:0B88		jmp TTimer.SetEnabled

EXTRA:0B8D	loc_final:
			sub [eax+08], $BGMfadeStrength	; if the fading out takes 10 steps (by default), then the volume (max=1000) is decreased by 100 every time
EXTRA:0B94		push eax	; DWORD_PTR dwParam
EXTRA:0B95		jae loc_setaudio	; if volume >= 0, then set audio volume
			; if volume < 0, meaning fading out is complete, then close the current BGM file
EXTRA:0B97		push 0	; DWORD fdwCommand
EXTRA:0B99		push MCI_CLOSE	; UINT uMsg
EXTRA:0B9E		jmp loc_call_MCI_API

EXTRA:0BA0	loc_setaudio:
			push MCI_DGV_SETAUDIO_ITEM_VALUE	; 0x1800000 DWORD fdwCommand
EXTRA:0BA5		push MCI_SETAUDIO	; UINT uMsg

EXTRA:0BAA	loc_call_MCI_API:
			mov eax, [ebx+TTSW10.TMediaPlayer5]
EXTRA:0BB0		movzx eax, word ptr [eax+TMediaPlayer.DeviceID]
EXTRA:0BB7		push eax	; DWORD IDDevice
EXTRA:0BB8		call mciSendCommandA

EXTRA:0BBD		test eax,eax	; eax = MCIERROR return value
EXTRA:0BBF		mov eax, offset mci_audio_volume	; i.e. mci_params+MCI_DGV_SETAUDIO_PARMS.dwValue
EXTRA:0BC4		jnz loc_reset	; API fails (if return value is non-zero)

EXTRA:0BC6		cmp [eax], 0
EXTRA:0BC9		jns loc_ret11	; volume >= 0, still fading, then return

EXTRA:0BCB	loc_reset:	; either mciSendCommandA API fails or volume reaches zero (and the BGM file is closed)
			mov [eax], 03E8	; volume back to 1000
EXTRA:0BD1		mov eax, [ebx+TTSW10.TMediaPlayer5]
EXTRA:0BD7		xor edx, edx
EXTRA:0BD9		mov byte ptr [eax+TMediaPlayer.PlayState], dl	; not playing (stopped)
EXTRA:0BDF		mov eax, [ebx+TTSW10.TTimer4]
EXTRA:0BE5		call TTimer.SetEnabled
EXTRA:0BEA		mov eax, [TSW_BGM_ID]
EXTRA:0BEF		mov byte ptr [last_bgmid], al
EXTRA:0BF4		cmp al, 1
EXTRA:0BF6		js loc_ret11	; do nothing if BGM id is 0 or FF (< 1)

EXTRA:0BF8		mov eax, ebx
EXTRA:0BFA		jmp sub_soundplay_real	; play new BGM after fading out ends

EXTRA:0BFF	loc_ret11:
			ret 

		sub_timer4ontimer_real	endp


		;===== SUBROUTINE =====
EXTRA:0C00	sub_instruct_playBGM	proc near	; in replacement of the treatment of the (1,5,0) sequence in `TTSW10.stackwork`

			mov edx, [ecx*2+BASE:8C750]	; starting from BASE:8C74C, it's an array of arrays of 3 words
			; each array of 3 words is a sequence of event to be executed. The execution direction is in the reversed order like in a stack
			; the current event stack pointer is stored in a DWORD BASE:48C5AC (which, multiplied by 3, is `ecx` here), once an event is executed, it is decreased by 1
			; so, dx = [ecx*2+BASE:8C750] (*2 is because each word is 2 bytes) is the third word of the current event sequence (the high 16 bits of `edx` is not useful here)
EXTRA:0C07		test dl,dl	; ignore the (1,5,0) sequence predefined by TSW; now, in tswBGM, the bgm id should be specifically written in the sequence, i.e. (1,5,id)
			; the reason why specifying id is necessary for tswBGM is that the check of bgm id is delayed by 150 ms (the first interval of TTimer4), so setting a (1,6,0) event would have overwrite the previously defined BGM id by FF
EXTRA:0C09		jz loc_ret12	; otherwise, will continue to execute `sub_instruct_playBGM_direct`
		sub_instruct_playBGM	endp
		;===== SUBROUTINE =====
EXTRA:0C0B	sub_instruct_playBGM_direct	proc near	; the BGM id is already defined in `edx`

EXTRA:0C0B		mov byte ptr [TSW_BGM_ID], dl
EXTRA:0C11		test dh, dh	; if the high 8 bits of the third word of the event sequence (1,5,id) is non-zero, it means that tswBGM wants to stop playing the sound effect in TMediaPlayer6
EXTRA:0C13		jz loc_bgm	; otherwise, do not stop TMediaPlayer6

EXTRA:0C15		mov eax, [ebx+TTSW10.TMediaPlayer6]
EXTRA:0C1B		call TMediaPlayer.Close

EXTRA:0C20	loc_bgm:
			mov eax, [ebx+TTSW10.TTimer4]
EXTRA:0C26		mov dl, 06	; to differentiate this enabled state from TSW's intrinsic enabled state of TTimer4, set TTimer.Enabled to 6 rather than 1
EXTRA:0C28		call TTimer.SetEnabled
EXTRA:0C2D		mov eax, ebx
EXTRA:0C2F		call TTSW10.timer4ontimer	; no need to wait for the first interval of TTimer4 (150 ms); start bgm process immediately
EXTRA:0C34		xor edx, edx	; this is not useful in most cases, but when called in BASE:4DC90, which is followed by calling TRichEdit1.SetVisible, it needs a zero `edx`. I run out of space there, so I moved the assignment of `edx` here.

EXTRA:0C36	loc_ret12:
			ret

		sub_instruct_playBGM	endp
EXTRA:0C37	align 04


		;===== SUBROUTINE =====
EXTRA:0C38	sub_checkOrbFlight	proc near	; in TSW, the BGM stops immediately you use Orb of Flight, but I think a better design is to stop the BGM only when you fly to a floor with a different BGM

			mov ecx, offset TSW_BGM_ID
EXTRA:0C3D		mov edx, offset last_bgmid
EXTRA:0C42		cmp byte ptr [ecx], 1
EXTRA:0C45		js loc_ret13	; do nothing if BGM id is 0 or FF (< 1) 
EXTRA:0C47		call TTSW10.soundcheck
EXTRA:0C4C		mov al, byte ptr [edx]
EXTRA:0C4E		cmp al, byte ptr [ecx]
EXTRA:0C50		je loc_ret13	; do nothing if the new floor has the same BGM
EXTRA:0C52		mov byte ptr [ecx], FF
EXTRA:0C55		mov dl, 06	; to differentiate this enabled state from TSW's intrinsic enabled state of TTimer4, set TTimer.Enabled to 6 rather than 1
EXTRA:0C57		mov eax, [ebx+TTSW10.TTimer4]
EXTRA:0C5D		jmp TTimer.SetEnabled

EXTRA:0C62	loc_ret13:
			ret

		sub_checkOrbFlight	endp
EXTRA:0C63	align 04


		;===== SUBROUTINE =====
EXTRA:0C64	sub_checkBGM_ext	proc near	; judge the BGM id more accurately, such as whether the game is over and whether in the middle of a boss battle

			mov eax, offset TSW_hero_status
EXTRA:0C69		cmp [eax], 0	; HP
EXTRA:0C6C		jne loc_floor

EXTRA:0C6E		mov byte ptr [TSW_BGM_ID], 0E	; HP = 0; game over

EXTRA:0C75	loc_ret14:
			add esp, 4	; pop the return address; do not execute the remaining commands in `TTSW10.soundcheck` and return BGM id immediately
EXTRA:0C78		ret

EXTRA:0C79	loc_floor:
			mov eax, [eax+10]	; floor
EXTRA:0C7C		push eax	; floor number should be recorded and assigned to `eax` before executing the remaining commands in `TTSW10.soundcheck`
EXTRA:0C7D		cmp eax, 000A
EXTRA:0C80		jne loc_20F

EXTRA:0C82		mov eax, 0F040000	; boss battle BGM id = 15, tile type to check = 4 (gate)
EXTRA:0C87		mov al, [BASE:B8E1F]	; F=10, Y=2, X=5 (BASE:B8934+123*F+11*Y+X+2)
EXTRA:0C8C		mov ah, [BASE:B8E4B]	; F=10, Y=6, X=5
EXTRA:0C92		jmp loc_boss_battle_stat

EXTRA:0C94	loc_20F:
			cmp eax, 0014
EXTRA:0C97		jne loc_25F
EXTRA:0C99		mov eax, 10040000	; boss battle BGM id = 16, tile type to check = 4 (gate)
EXTRA:0C9E		mov al, [BASE:B9303]	; F=20, Y=4, X=5
EXTRA:0CA3		mov ah, [BASE:B932F]	; F=20, Y=8, X=5
EXTRA:0CA9		jmp loc_boss_battle_stat

EXTRA:0CAB	loc_25F:
			cmp eax, 0019
EXTRA:0CAE		jne loc_40F
EXTRA:0CB0		mov eax, 07040000	; boss battle BGM id = 7, tile type to check = 4 (gate)
EXTRA:0CB5		mov al, [BASE:B9580]	; F=25, Y=6, X=5
EXTRA:0CBA		mov ah, [BASE:B95A1]	; F=25, Y=9, X=5
EXTRA:0CC0		jmp loc_boss_battle_stat

EXTRA:0CC2	loc_40F:
			cmp eax, 0028
EXTRA:0CC5		jne loc_49F
EXTRA:0CC7		mov eax, 12040000	; boss battle BGM id = 18, tile type to check = 4 (gate)
EXTRA:0CCC		mov al, [BASE:B9CAA]	; F=40, Y=5, X=5
EXTRA:0CD1		mov ah, [BASE:B9CC0]	; F=40, Y=7, X=5
EXTRA:0CD7		jmp loc_boss_battle_stat

EXTRA:0CD9	loc_49F:
			cmp eax, 0031
EXTRA:0CDC		jne loc_ret14	; not in a floor with a boss battle, then pop the floor number and return to `TTSW10.soundcheck`
EXTRA:0CDE		mov eax, 135B0000	; boss battle BGM id = 19, tile type to check = 91 (Zeno)
EXTRA:0CE3		mov al, [BASE:BA0D1]	; F=49, Y=1, X=5
EXTRA:0CE8		mov ah, [BASE:BA0DC]	; F=49, Y=2, X=5

EXTRA:0CEE	loc_boss_battle_stat:
			cmp al, 17	; check if tile id stored in `al` is 23 (fairy)
EXTRA:0CF0		jne loc_boss_battle

EXTRA:0CF2		mov al, 0C	; theme of fairy
EXTRA:0CF4		jmp loc_set_bgm

EXTRA:0CF6	loc_boss_battle:
			shr eax, 0008	; discard the low 8 bits
EXTRA:0CF9		cmp al, ah	; if the tile id matches, meaning in a boss battle
EXTRA:0CFB		je loc_boss_battle_bgm

EXTRA:0CFD		pop eax	; neither in or after a boss battle, return to `TTSW10.soundcheck`
EXTRA:0CFE		ret

EXTRA:0CFF	loc_boss_battle_bgm:
			shr eax, 0010	; the high 8 bit will be the bgm id

EXTRA:0D02	loc_set_bgm:
			mov byte ptr [TSW_BGM_ID], al
EXTRA:0D07		add esp, 8	; pop the floor number; then pop the return address; do not execute the remaining commands in `TTSW10.soundcheck` and return BGM id immediately
EXTRA:0D0A		ret

		sub_checkBGM_ext	endp
EXTRA:0D0B	align 04


		;===== SUBROUTINE =====
EXTRA:0D0C	sub_resetTTimer4	proc near	; if `isInProlog`, the properties of TTimer4 can't be changed right away, but if TTimer4 is later set enabled or disabled, the state of `isInProlog` needs to be set false, and the new TTimer4.interval will be set

			mov ecx, [eax+TControl.Parent]
EXTRA:0D0F		cmp eax, [ecx+TTSW10.TTimer4]	; if the current TTimer is TTSW10.TTimer4
EXTRA:0D15		jne loc_normal_TTimer

EXTRA:0D17		mov byte ptr [isInProlog], 0
EXTRA:0D1E		mov ecx, $BGM_FADE_INTERVAL	; by default 150 (ms)
EXTRA:0D23		cmp ecx, [eax+TTimer.Interval]
EXTRA:0D26		je loc_normal_TTimer

EXTRA:0D28		mov [eax+24],ecx	; if TTimer4.Interval is not the desired value, then change it; then return to `TTimer.SetEnabled`, where `TTimer.UpdateTimer` will be called
EXTRA:0D2B		ret

EXTRA:0D2C	loc_normal_TTimer:
			cmp dl, byte ptr [eax+TTimer.Enabled]
EXTRA:0D2F		jne loc_ret15	; if TTimer4.Enabled is not the desired value, then return to `TTimer.SetEnabled`, where `TTimer.UpdateTimer` will be called

EXTRA:0D31		add esp, 4	; otherwise, pop the return address; do not execute the remaining commands in `TTimer.SetEnabled`, i.e., do not call `TTimer.UpdateTimer`

EXTRA:0D34	loc_ret15:
			ret

		sub_resetTTimer4	endp
EXTRA:0D35	align 04


		;===== SUBROUTINE =====
EXTRA:0D38	sub_initBGM	proc near	; on initialization of tswBGM, stop the intrinsic MIDI BGM of TSW; check if is in prolog

			mov ebx, eax
EXTRA:0D3A		mov eax, [ebx+TTSW10.TTimer4]
EXTRA:0D40		mov al, byte ptr [eax+TTimer.Enabled]
EXTRA:0D43		and al, 01	; if TTimer4.Enabled is 1, then `isInProlog` is true; otherwise, if it is 6, it means tswBGM is using TTimer4, not in prolog; if 0, not in prolog
EXTRA:0D45		mov [isInProlog], al
EXTRA:0D4A		mov edx, offset TSW_BGM_ID
EXTRA:0D4F		jz loc_set_bgmid

EXTRA:0D51		mov byte ptr [edx], 15	; if in prolog, then the bgm id is 21 (theme of lucky gold), though I think this is a bug not a feature (TTSW.optionl1 will call TTSW10.soundplay unexpectedly at the beginning of prolog; TSW3D v1.8 fixes this bug, and there is no BGM during the prolog)

EXTRA:0D54	loc_set_bgmid:
			mov al, byte ptr [edx]
EXTRA:0D56		cmp al, 1
EXTRA:0D58		jns loc_set_last_bgmid	; if bgm id is 0 or FF (< 1), then need to call `soundcheck`; otherwise, use the original bgm id before the MIDI bgm is stopped

EXTRA:0D5A		call TTSW10.soundcheck
EXTRA:0D5F		mov al, byte ptr [edx]

EXTRA:0D61	loc_set_last_bgmid:
			mov byte ptr [last_bgmid], al

EXTRA:0D66		mov eax, [ebx+TTSW10.TMediaPlayer5]	; close TSW's own MIDI BGM
EXTRA:0D6C		mov byte ptr [eax+TMediaPlayer.PlayState], 0
EXTRA:0D73		movzx eax,word ptr [eax+TMediaPlayer.DeviceID]
EXTRA:0D7A		push offset mci_params	; dwParam
EXTRA:0D7F		push 0	; fdwCommand
EXTRA:0D81		push MCI_CLOSE	; uMsg
EXTRA:0D86		push eax	; IDDevice
EXTRA:0D87		call mciSendCommandA
EXTRA:0D8C		mov dl, 01
EXTRA:0D8E		jmp loc_set_bgm_options

		sub_initBGM	endp


		;===== SUBROUTINE =====
EXTRA:0D90	sub_finalizeBGM	proc near	; this function is called in 2 scenarios: when tswBGM quits, then disable BGM; when tswBGM initializes, set the BGM options correctly and start BGM

			xor edx,edx
EXTRA:0D92		mov ebx,eax

EXTRA:0D94	loc_set_bgm_options:
			mov byte ptr [TSW_BGM_setting], dl
EXTRA:0D9A		mov eax, [ebx+TTSW10.TMenuBGMON1]
EXTRA:0DA0		call TMenuItem.SetChecked

EXTRA:0DA5		xor edx, edx
EXTRA:0DA7		cmp byte ptr [TSW_BGM_setting], dl
EXTRA:0DAD		je loc_quit_tswBGM	; when tswBGM quits, stop BGM

EXTRA:0DAF		mov eax, ebx	; when tswBGM initializes, start BGM
EXTRA:0DB1		jmp sub_soundplay_real

EXTRA:0DB6	loc_quit_tswBGM:
			mov [TSW_BGM_ID], edx
EXTRA:0DBC		mov eax, [ebx+TTSW10.TMediaPlayer5]
EXTRA:0DC2		call TMediaPlayer.Close
EXTRA:0DC7		mov dl, [isInProlog]
EXTRA:0DCD		mov eax, [ebx+TTimer4]
EXTRA:0DD3		jmp TTimer.SetEnabled

		sub_finalizeBGM	endp
