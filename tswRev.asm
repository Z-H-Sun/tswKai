; Other revisions:
; - Solve 49F sorcerer show-up animation bug: addressed in tswMod.asm
; - Allow data loading during events: addressed in tswSL.asm
; - Properly process consecutive sound effects: addressed in tswBGM.asm

BASE:41BFC	dw 000F	; total length of the structure
BASE:41BFE	;dd offset BASE:7F544	; original bytes
		dd offset BASE:7F4D8	; patched bytes
BASE:41C02	db 08	; length of the subsequent string
BASE:41C03	;db 'speedlow'	; original bytes
		db 'speedsup'	; patched bytes
		; 'speedlow' method name --> 'Low1Click' <= referenced by TMenuItem: Low1.OnClick
		; NULL --> 'speedsup' <= referenced by TMenuItem: N7.OnClick ('N7' was a separator but is now menu item 'SuperFast')
; ...
BASE:41C1D	dw 0010	; total length of the structure
BASE:41C1F	;dd offset BASE:7F47C	; original bytes
		dd offset BASE:7F464	; patched bytes
BASE:41C23	db 09	; length of the subsequent string
BASE:41C24	;db 'speedhigh'	; original bytes
		db 'DisTEdit8'	; patched bytes
		; 'speedhigh' method name --> 'High1Click' <= referenced by TMenuItem: High1.OnClick
		; NULL --> 'DisTEdit8' <= referenced by TEdit: Edit8.OnChange
; ...
BASE:425ED	dw 0011	; total length of the structure
BASE:425EF	;dd offset BASE:7F464	; original bytes
		dd offset BASE:7F47C	; patched bytes
BASE:425F3	db 0A	; length of the subsequent string
BASE:425F4	db 'High1Click'	; => TTSW10.speedhigh
; ...
BASE:42611	dw 0010	; total length of the structure
BASE:42613	;dd offset BASE:7F474	; original bytes
		dd offset BASE:7F544	; patched bytes
BASE:42617	db 09	; length of the subsequent string
BASE:42618	db 'Low1Click'	; => TTSW10.speedlow

;============================================================
		; Rev0: Better compatibility with tswMP
		; In RCData resource with ID TTSW10, the following is added:
		; 	in object Edit8: TEdit:	OnChange = DisTEdit8
BASE:7F464	TTSW10.DisTEdit8	proc near	; <-- TTSW10.High1Click
		; this extension is used by tswMP
		; when mouse hovers on a monster, TEdit8 will show monster's properties, but sometimes the text length exceeds the boundary of the textbox which is inconvenient
		; so my workaround is to temporarily enable TEdit8 to allow users to select and drag the texts there
		; but it needs to be disabled again later on to lose keyboard focus
		; therefore, this DisTEdit8 method will be elicited upon TEdit8.OnChange to do this job, which is triggered when the text content changes, e.g., when player moves
		; original bytes:
;			call BASE:7F47C	; => TTSW10.speedhigh
				; this just jumps to another address which is unnecessary, we can directly redirect High1.OnClick to that final address without this relay
				; and then we can use the spare space here to replace with our own codes
;BASE:7F469		ret
;BASE:7F46A		mov eax, eax	; 2-byte nop
		; patched bytes:
			mov eax, [eax+01C8]	; TTSW10.Edit8
BASE:7F46A		jmp loc_DisTEdit8_2	; BASE:7F474	; need more space; we can do the same thing with Low1Click too
		TTSW10.DisTEdit8	endp

BASE:7F46C	TTSW10.Middle1Click	proc near
			call BASE:7F4E0	; => TTSW10.speedmiddle
				; this space will be used by tswKai3 `callFunc` method
				; so do not change these codes here
BASE:7F471		ret
		TTSW10.Middle1Click	endp
BASE:7F472	align 04

BASE:7F474	loc_DisTEdit8_2:	; <-- TTSW10.Low1Click	proc near
		; original bytes:
;			call BASE:7F544	; => TTSW10.speedlow
				; likewise, no need for this relay
		; patched bytes:
			call BASE:13544	; code snippet in TControl.SetEnabled
				; because enabling TEdit8 in tswMP is done by Win32 API `EnableWindow` not in Delphi, TEdit8.Enabled ([eax+0x38]) is not changed and always False, so no need to reassign it
BASE:7F479		ret
;		TTSW10.Low1Click	endp
BASE:7F47A	align 04


;============================================================
		; Rev1: SuperFast Speed mode
		; In RCData resource with ID TTSW10, the following is added/changed:
		; 	in object N7: TMenuItem:	Caption = "&Super High"; OnClick = speedsup
BASE:7F47C	TTSW10.High1Click	proc near	; <-- TTSW10.speedhigh
			push ebx
BASE:7F47D		mov ebx, eax
		; original bytes:
;BASE:7F47F		mov edx, 0096	; 150 ms
;BASE:7F484		mov eax, [ebx+01B4]	; TTSW10.Timer1: TTimer
;BASE:7F48A		call TTimer.SetInterval	; BASE:2C464
;BASE:7F48F		mov edx, 0096	; 150 ms
;BASE:7F494		mov eax, [ebx+02EC]	; TTSW10.Timer2: TTimer
;BASE:7F49A		call TTimer.SetInterval	; BASE:2C464
;BASE:7F49F		mov edx, 0096	; 150 ms
;BASE:7F4A4		mov eax, [ebx+030C]	; TTSW10.Timer3: TTimer
;BASE:7F4AA		call TTimer.SetInterval	; BASE:2C464
;BASE:7F4AF		mov dl, 1	; check
;BASE:7F4B1		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7F4B7		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7F4BC		xor edx, edx	; uncheck
;BASE:7F4BE		mov eax, [ebx+03AC]	; TTSW10.Middle1: TMenuItem
;BASE:7F4C4		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7F4C9		xor edx, edx	; uncheck
;BASE:7F4CB		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
;BASE:7F4D1		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7F4D6		mov byte ptr [BASE:89B9F], 1	; this stores the speed mode: 1=High; 2=Middle; 3=Low
;BASE:7F4DD		pop ebx
;BASE:7F4DE		ret
;BASE:7F4DF		nop	; align 04
;		TTSW10.speedhigh	endp
		; patched bytes:
BASE:7F47F		push 1	; push arg0 (speed mode = 1 = High) to stack

BASE:7F481	loc_set_speed:	; For SuperFast/High/Middle speed modes (Low will be treated elsewhere); arg0 (DWORD on stack) = speed mode
			mov eax, [esp]
BASE:7F484		mov byte ptr [BASE:89B9F], al	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:7F489		mov ecx, 000A	; Timer2.Interval will be `ecx`; SuperFast: 10 ms (This is the shortest possible interval in Win32 API `SetTimer`; see MSDN)
BASE:7F48E		mov edx, 007D	; Timer1/3.Interval will be `edx`; SuperFast: 125 ms
BASE:7F493		dec eax	; 1=High
BASE:7F494		jnz loc_not_speed_high
BASE:7F496		mov cl, 32	; High: Timer2.Interval = 50 ms; Timer1/3.Interval will remain 125 ms
BASE:7F498	loc_not_speed_high:
			dec eax	; 2=Middle
BASE:7F499		jnz loc_not_speed_middle
BASE:7F49B		mov cl, 64	; Middle: Timer2.Interval = 100 ms
BASE:7F49D		mov dl, C8	; Middle: Timer1/3.Interval = 200 ms
BASE:7F49F	loc_not_speed_middle:
			push edx	; will be used by Timer3.SetInterval
BASE:7F4A0		push ecx	; will be used by Timer2.SetInterval
BASE:7F4A1		push edx	; will be used by Timer1.SetInterval
BASE:7F4A2		test al, al	; 2=Middle
BASE:7F4A4		sete dl	; check/uncheck
BASE:7F4A7		mov eax, [ebx+03AC]	; TTSW10.Middle1: TMenuItem
BASE:7F4AD		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F4B2		pop edx
BASE:7F4B3		mov eax, [ebx+01B4]	; TTSW10.Timer1: TTimer
BASE:7F4B9		call TTimer.SetInterval	; BASE:2C464
BASE:7F4BE		pop edx
BASE:7F4BF		mov eax, [ebx+02EC]	; TTSW10.Timer2: TTimer
BASE:7F4C5		call TTimer.SetInterval	; BASE:2C464
BASE:7F4CA		pop edx
BASE:7F4CB		mov eax, [ebx+030C]	; TTSW10.Timer3: TTimer
BASE:7F4D1		call TTimer.SetInterval	; BASE:2C464
BASE:7F4D6		jmp loc_set_speed_next	; run out of space here; will finish the procedure later
		TTSW10.High1Click	endp

BASE:7F4D8	TTSW10.speedsup	proc near	; <= TTSW10.N7.OnClick
			push ebx
BASE:7F4D9		mov ebx, eax
BASE:7F4DB		push 0	; push arg0 (speed mode = 0 = SuperFast) to stack
BASE:7F4DD		jmp loc_set_speed
		TTSW10.speedsup	endp
BASE:7F4DF	align 04

BASE:7F4E0	TTSW10.speedmiddle	proc near
			push ebx
BASE:7F4E1		mov ebx, eax
		; original bytes:
;BASE:7F4E3		mov edx, 00FA	; 250 ms
;BASE:7F4E8		mov eax, [ebx+01B4]	; TTSW10.Timer1: TTimer
;BASE:7F4EE		call TTimer.SetInterval	; BASE:2C464
;BASE:7F4F3		mov edx, 00FA	; 250 ms
;BASE:7F4F8		mov eax, [ebx+02EC]	; TTSW10.Timer2: TTimer
;BASE:7F4FE		call TTimer.SetInterval	; BASE:2C464
;BASE:7F503		mov edx, 00FA	; 250 ms
;BASE:7F508		mov eax, [ebx+030C]	; TTSW10.Timer3: TTimer
;BASE:7F50E		call TTimer.SetInterval	; BASE:2C464
;BASE:7F513		xor edx, edx	; uncheck
;BASE:7F515		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7F51B		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7F520		mov dl, 1	; check
;BASE:7F522		mov eax, [ebx+03AC]	; TTSW10.Middle1: TMenuItem
;BASE:7F528		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7F52D		xor edx, edx	; uncheck
;BASE:7F52F		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
;BASE:7F535		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7F53A		mov byte ptr [BASE:89B9F], 2	; this stores the speed mode: 1=High; 2=Middle; 3=Low
;BASE:7F541		pop ebx
;BASE:7F542		ret
;BASE:7F543		nop	; align 04
;		TTSW10.speedmiddle	endp
		; patched bytes:
BASE:7F4E3		push 2	; push arg0 (speed mode = 2 = Middle) to stack
BASE:7F4E5		jmp loc_set_speed
BASE:7F4E7		nop	; align 04
		TTSW10.speedmiddle	endp

BASE:7F4E8	loc_set_speed_next:
			cmp [esp], 1	; [esp] is arg0 (speed mode) on stack
BASE:7F4EC		sete dl	; check/uncheck
BASE:7F4EF		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
BASE:7F4F5		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F4FA		xor edx, edx	; uncheck
BASE:7F4FC		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
BASE:7F502		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F507		pop eax
BASE:7F508		test al, al	; 0=SuperFast
BASE:7F50A		sete dl	; check/uncheck
BASE:7F50D		jmp loc_set_speedsup_checked
		; ...
BASE:7F534	loc_set_speedsup_unchecked:	; this will be used in Low1Click below
			xor edx, edx	; uncheck
BASE:7F536	loc_set_speedsup_checked:
			mov eax, [ebx+0358]	; TTSW10.N7: TMenuItem
BASE:7F53C		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F541		pop ebx
BASE:7F542		ret
BASE:7F543		nop	; align 04
;		TTSW10.speedmiddle	endp

BASE:7F544	TTSW10.Low1Click	proc near	; <-- TTSW10.speedlow
			push ebx
BASE:7F545		mov ebx, eax
BASE:7F547		;mov edx, 015E	; original bytes: 350 ms
			mov edx, 0113	; patched bytes: 275 ms
BASE:7F54C		mov eax, [ebx+01B4]	; TTSW10.Timer1: TTimer
BASE:7F552		call TTimer.SetInterval	; BASE:2C464
BASE:7F557		;mov edx, 015E	; original bytes: 350 ms
			mov edx, 0096	; patched bytes: 150 ms
BASE:7F55C		mov eax, [ebx+02EC]	; TTSW10.Timer2: TTimer
BASE:7F562		call TTimer.SetInterval	; BASE:2C464
BASE:7F567		;mov edx, 015E	; original bytes: 350 ms
			mov edx, 0113	; patched bytes: 275 ms
BASE:7F56C		mov eax, [ebx+030C]	; TTSW10.Timer3: TTimer
BASE:7F572		call TTimer.SetInterval	; BASE:2C464
BASE:7F577		xor edx, edx	; uncheck
BASE:7F579		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
BASE:7F57F		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F584		xor edx, edx	; uncheck
BASE:7F586		mov eax, [ebx+03AC]	; TTSW10.Middle1: TMenuItem
BASE:7F58C		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F591		mov dl, 1	; check
BASE:7F593		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
BASE:7F599		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F59E		mov byte ptr [BASE:89B9F], 3	; this stores the speed mode: 1=High; 2=Middle; 3=Low
		; original bytes:
;BASE:7F5A5		pop ebx
;BASE:7F5A6		ret
		; patched bytes:
BASE:7F5A5		jmp loc_set_speedsup_unchecked
		TTSW10.Low1Click	endp
BASE:7F5A7	align 04


BASE:7D324	TTSW10.OptionSave1Click	proc near	; save speed mode and other settings
		; ...
		; original bytes:
;BASE:7D387		mov byte ptr [BASE:89B9F], 2	; this stores the speed mode: 1=High; 2=Middle; 3=Low
;BASE:7D38E		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7D394		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked: Boolean
;BASE:7D398		jne loc_speed_not_high
;BASE:7D39A		mov byte ptr [BASE:89B9F], 1	; High
;BASE:7D3A1	loc_speed_not_high:
;			mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
;BASE:7D3A7		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked: Boolean
;BASE:7D3AB		jne loc_speed_not_low
;BASE:7D3AD		mov byte ptr [BASE:89B9F], 3	; Low
;BASE:7D3B4	loc_speed_not_low:
			; ...
		; patched bytes:
BASE:7D387		xor edx, edx	; `dl` will be assigned to [BASE:89B8F] later; now 0=SuperFast
BASE:7D389		lea ecx, [ebx+03A8]	; offset TTSW10.High1
BASE:7D38F		mov eax, [ecx]	; TTSW10.High1
BASE:7D391		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked
BASE:7D395		jne loc_speed_not_high
BASE:7D397		inc edx	; 1=High
BASE:7D398	loc_speed_not_high:
			mov eax, [ecx+4]	; offset TTSW10.Middle1
BASE:7D39B		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked
BASE:7D39F		jne loc_speed_not_middle
BASE:7D3A1		mov dl, 2	; 2=High
BASE:7D3A3	loc_speed_not_middle:
			mov eax, [ecx+8]	; offset TTSW10.Low1
BASE:7D3A6		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked
BASE:7D3AA		jne loc_speed_not_low
BASE:7D3AC		mov dl, 3	; 3=Low
BASE:7D3AE	loc_speed_not_low:
			mov byte ptr [BASE:89B9F], dl	; this stores the speed mode
BASE:7D3B4	; ...
		; ...
		TTSW10.OptionSave1Click	endp


BASE:7D4A4	TTSW10.option1	proc near	; load speed mode and other settings
		; ...
		; original bytes:
;BASE:7D7FA		xor edx, edx	; uncheck
;BASE:7D7FC		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7D802		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7D807		xor edx, edx	; uncheck
;BASE:7D80F		mov eax, [ebx+03AC]	; TTSW10.Middle1: TMenuItem
;BASE:7D802		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7D814		xor edx, edx	; uncheck
;BASE:7D816		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
;BASE:7D81C		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7D821		mov al, byte ptr [esi+3]	; esi=BASE:89B9C; BASE:89B9F stores the speed mode
;BASE:7D824		dec al	; 1=High
;BASE:7D826		je loc_speed_high
;BASE:7D828		dec al	; 2=Middle
;BASE:7D82A		je loc_speed_middle
;BASE:7D82C		dec al	; 3=Low
;BASE:7D82E		je loc_speed_low
;BASE:7D830		jmp loc_speed_default
;BASE:7D832	loc_speed_high:
;			mov dl, 1	; check
;BASE:7D834		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7D83A		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7D83F		jmp loc_speed_default
;BASE:7D841	loc_speed_middle:
;			mov dl, 1	; check
;BASE:7D843		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7D849		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7D84E		jmp loc_speed_default
;BASE:7D850	loc_speed_low:
;			mov dl, 1	; check
;BASE:7D852		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7D858		call TMenuItem.SetChecked	; BASE:102F0
;BASE:7D85D	loc_speed_default:
			; ...
		; patched bytes:
BASE:7D7FA		mov al, byte ptr [esi+3]	; esi=BASE:89B9C; BASE:89B9F stores the speed mode
BASE:7D7FD		push eax
BASE:7D7FE		cmp al, 3	; Low
BASE:7D800		sete dl	; check/uncheck
BASE:7D803		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
BASE:7D809		call TMenuItem.SetChecked	; BASE:102F0
BASE:7D80E		cmp byte ptr [esp], 2	; Middle
BASE:7D812		sete dl	; check/uncheck
BASE:7D815		mov eax, [ebx+03AC]	; TTSW10.Middle1: TMenuItem
BASE:7D81B		call TMenuItem.SetChecked	; BASE:102F0
BASE:7D820		cmp byte ptr [esp], 1	; High
BASE:7D824		sete dl	; check/uncheck
BASE:7D827		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
BASE:7D82D		call TMenuItem.SetChecked	; BASE:102F0
BASE:7D832		pop eax
BASE:7D833		test al, al	; SuperFast
BASE:7D835		sete dl	; check/uncheck
BASE:7D838		mov eax, [ebx+0358]	; TTSW10.N7: TMenuItem (SuperFast)
BASE:7D83E		jmp BASE:7D858
		; ...
BASE:7D858		call TMenuItem.SetChecked	; BASE:102F0
			; ...
		TTSW10.option1	endp


		; In addition to the Timer2.Interval settings above (recall that Timer2 controls game event processing), sometimes its interval will be separately changed in certain events like door opening (see TTSW10.dooropen at BASE:7717A as an example) / scrolling caption / stair animation / etc.
		; However, the change will only happen when the High / Middle / Low speed menu itme is ticked; therefore, in cases where SuperHigh speed mode is selected, these interval-changing codes will not be executed, and Timer2.Interval will remain to be 10 msec, the shortest possible interval. So nothing is required to be done in these scenarios.
		; The only exception is TTSW10.opening9 (epilog) below
BASE:42E60	TTSW10.opening9	proc near	; epilog ("The tower has fallen down")
		; ...
		; Task 4: Show animation of fallen tower zooming out
BASE:839D0		mov edx, 0064	; 100 ms
BASE:839D5		mov eax, [ebx+02EC]	; TTSW10.Timer2
BASE:839DB	; original bytes:
			; call TTimer.SetInterval
		; patched bytes:
			call loc_opening9_timer_setinterval	; BASE:7F5C0 (see below)
		; briefly, the intervals here were too long. I think it's better to shorten the interval according to the game speed mode settings
		; ...

		; Task 5: Show scrolling caption
BASE:83C8A		mov edx, 003C	; 60 ms
BASE:83C8F		mov eax, [ebx+02EC]	; TTSW10.Timer2
BASE:83C95	; original bytes:
			; call TTimer.SetInterval
		; patched bytes:
			call loc_opening9_timer_setinterval	; BASE:7F5C0 (see below)
		; ...

		; Task 6: Show animation of tower falling down
BASE:83E58		mov edx, 01C2	; 450 ms
BASE:83E5D		mov eax, [ebx+02EC]	; TTSW10.Timer2
BASE:83E63	; original bytes:
			; call TTimer.SetInterval
		; patched bytes:
			call loc_opening9_timer_setinterval	; BASE:7F5C0 (see below)
		; ...

		; Task 8: End animation and show "See You Again" screen
BASE:846F6		mov dl, 01	; True
		; orignal bytes:
;BASE:846F8		mov eax, [ebx+0480]	; TTSW10.Panel2 (frame for "See you again" button)
;BASE:846FE		call TControl.SetVisible
;BASE:84703		mov dl,01	; True
;BASE:84705		mov eax, [ebx+0484]	; TTSW10.Image34 ("See you again" button)
;BASE:8470B		call TControl.SetVisible
;BASE:84710		mov eax, [BASE:8C510]	; TTSW10 handle; can be replaced by ebx
;BASE:84715		mov byte ptr [eax+0118], 01	; don't know what this is
;BASE:8471C		xor edx, edx	; False
;BASE:8471E		mov eax, [ebx+02EC]	; TTSW10.Timer2
;BASE:84724		call TTimer.SetEnabled
		; patched bytes:
BASE:846F8		lea esi, [ebx+0480]	; this can overall save 1 byte
BASE:846FE		mov eax, [esi]
BASE:84700		mov edi, offset TControl.SetVisible	; this can overall save 1 byte
BASE:84705		call edi
BASE:84707		mov dl, 01
BASE:84709		mov eax, [esi+04]	; [ebx+0484]
BASE:8470C		call edi
BASE:8470E		mov byte ptr [ebx+0118], 01	; this can overall save 5 bytes
BASE:84715		lea esi, [ebx+02EC]	; offset TTSW10.Timer2 (esi will be used to save space for [ebx+0334]: by replacing it with [esi+48], 3 bytes can be saved; see below)
BASE:8471B		mov eax, [esi]	; this overall adds 2 more bytes
BASE:8471D		xor edx, edx	; False
BASE:8471F		call TTimer.SetEnabled
		; Codes above save 5 bytes in total, which is enough to insert a `call` below
BASE:84724		call loc_opening9_timer_postprocess	; BASE:7F5D8 (see below)
		; briefly, two more functions will be called:
		; the first one, TTimer.timerin resets the Timer2 interval. Originally, there was no this line, so this can be a small bug when you start the next round game, though the interval will be set back normal when you open a door (because TTSW10.timerin will be called in TTSW10.dooropen). The bug can be solved by explicitly calling TTimer.timerin here
		; the other one: in tswSL.asm I cancelled disabling loading in TTSW10.itemdel, so you could load data during an event. However, it's not a good idea here because the "See you again" button won't be properly eliminated, so need to re-disable loading here
		; (although this can't prevent user from loading arbitrary data or temp data in tswSL... Please don't do that)
		; ...

		TTSW10.opening9	endp


BASE:7F5A8	TTSW10.timerin	proc near	; reset timer intervals (because sometimes, the interval of some timer, especially Timer2, will be changed in an event, so need to change back afterwards)
BASE:7F5A8		push ebx
BASE:7F5A9		mov ebx, eax	; prolog
		; now need to take into account the SuperFast mode
		; and space can be saved here to insert our codes
		; original bytes:
;BASE:7F5AB		mov eax, [ebx+03AC]	; TTSW10.Middle1: TMenuItem
;BASE:7F5B1		cmp byte ptr [eax+28], 01	; TMenuItem.FChecked: Boolean
;BASE:7F5B5		jne BASE:7F5BE
;BASE:7F5B7		mov eax, ebx
;BASE:7F5B9		call TTSW10.speedmiddle	; BASE:7F4E0
;BASE:7F5BE		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:7F5C4		cmp byte ptr [eax+28], 01	; TMenuItem.FChecked: Boolean
;BASE:7F5C8		jne BASE:7F5D1
;BASE:7F5CA		mov eax, ebx
;BASE:7F5CC		call TTSW10.speedhigh	; BASE:7F47C
;BASE:7F5D1		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
;BASE:7F5D7		cmp byte ptr [eax+28], 01	; TMenuItem.FChecked: Boolean
;BASE:7F5DB		jne BASE:7F5E4
;BASE:7F5DD		mov eax, ebx
;BASE:7F5DF		call TTSW10.speedlow	; BASE:7F544
;BASE:7F5E4		pop ebx
;BASE:7F5E5		ret
;		TTSW10.timerin	endp

		; patched bytes:
BASE:7F5AB		movzx ecx, byte ptr [BASE:89B9F]	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:7F5B2		cmp ecx, 03	; Low (this one is processed separately from other speed modes)
BASE:7F5B5		je BASE:7F547	; snippet in TTSW10.Low1Click
BASE:7F5B7		push ecx	; otherwise, push speed mode onto stack
BASE:7F5B8		jmp loc_set_speed	; BASE:7F481
BASE:7F5BD	loc_opening9_timer_setinterval_ret:
			ret	; this is actually not necessary, but is used in BASE:7F5C9 below
BASE:7F5BE		xchg ax, ax	; 2-byte nop
		TTSW10.timerin	endp


BASE:7F5C0	loc_opening9_timer_setinterval:	; see above; eax (Timer2), edx (Interval) already set
			movzx ecx, byte ptr [BASE:89B9F]	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:7F5C7		test ecx, ecx
BASE:7F5C9		je loc_opening9_timer_setinterval_ret	; for SuperFast mode, don't change interval (which remains 10 ms)
BASE:7F5CB		inc ecx
BASE:7F5CC		imul edx, ecx
BASE:7F5CF		shr edx, 02	; High: *1/2; Middle: *3/4; Low: *1
BASE:7F5D2		jmp TTimer.SetInterval
BASE:7F5D7		nop

BASE:7F5D8	loc_opening9_timer_postprocess:	; see above; TTSW10.GameLoad1.SetEnabled(False) and TTSW10.timerin will be called
			mov eax, [esi+48]	; TTSW10.GameLoad1: TMenuItem (=[ebx+0334] because esi=ebx+02EC; this can save 3 bytes space)
BASE:7F5DB		xor edx, edx	; False
BASE:7F5DD		call TMenuItem.SetEnabled	; BASE:10378
BASE:7F5E2		mov eax, ebx
BASE:7F5E4		jmp TTSW10.timerin


;============================================================
		; Rev2: Fix prolog bug
BASE:4280C	TTSW10.formactivate	proc near	; <= TTSW10.OnActivate
		; this will be called when the main form is initialized and shown
		; ...
		; original bytes:
;BASE:42B23		mov eax, [ebp-4]	; TTSW10
;BASE:42B26		mov eax, [eax+0420]	; TTSW10.K5: TMenuItem
;BASE:42B2C		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked: Boolean
				; this will always be true because although the settings have been loaded to memory, the checked states of the menu items are not set yet according to these settings, and the default checked state of K5 (Prologue) is True
		; patched bytes:
BASE:42B23		cmp byte ptr BASE:89BA1, 1	; this is the actual settings in memory
BASE:42B2A		jmp BASE:42B30
BASE:42B2C	; ...
BASE:42B30	; ...
		; ...
		TTSW10.formactivate	endp


;============================================================
		; Rev3: Default window title and font
BASE:23FFC	TApplication.Create	proc near
		; ...
		; The default app title, before main form initialization (for example, the "Sorry, cannot execute plural TSW" msgbox is shown before TSW main form creation), is determined by the TApplication.Create procedure in the following rule:
		; * The executable name of the app is read;
		; * The basename of the file is found;
		; * The string is split with . and all chars after the first occurrence of . is discarded (which is weird; this is not even the extension name).
		; * All alphabets but the first one is converted to lower case (Why bother? Two things: 1. Whether the first char is upper or lower case is not considered; 2. non-Latin alphabets are not considered and will cause mojibake).
BASE:24114		;lea edx, [ebp-0101]	; original bytes: from filename
			mov edx, offset BASE:88E74	; patched bytes: from app title
			nop
		; ...
		TApplication.Create	endp


BASE:172C0	; first byte=length; followed by string
		; Referenced by THintWindow.Create @ BASE:17284
		;0F, 'ＭＳ Ｐゴシック'	; original bytes: Code Page 932 (Shift-JIS)
		07, 'Verdana'	; patched bytes: English Ver, or
		08, '微软雅黑'	; Code Page 936 (GBK): Chinese Ver
	; ...
BASE:894A6	; first byte=length; followed by string
		; likely part of the structure @ BASE:8949C, referenced by TFont.Create and TFont.SetHandle
		;0F, 'ＭＳ Ｐゴシック'	; original bytes: Code Page 932 (Shift-JIS)
		07, 'Verdana'	; patched bytes: English Ver, or
		08, '微软雅黑'	; Code Page 936 (GBK): Chinese Ver


;============================================================
		; Rev4: Improve tweened animation for hero and enemy movement
		; Under common cases, the refreshing rate of the game map is < 10 FPS. However, this can cause an unnatural visual feeling during an animated event, e.g., moving the player position. Therefore, TSW will insert interpolation frames while you are moving, written in the TTSW10.idou procedure. The number of interpolated frames is `x` in low-speed mode, `x/2` in middle-speed mode, and `x/4` in high-speed mode, where `x` is the width of each tile (32 or 40 depending on the game window size you choose). And for the movement of monsters, the number of interpolation frames is always `x`, written in the TTSW10.monidou procedure. However, the original codes were flawed in the following two aspects:
		; * Each frame is drawn consecutively without pausing. Modern CPU/GPUs can process GDI drawing (especially for memory DCs) quite quickly, typically < ms. Therefore, the 40 frames were drawn within several milliseconds, so it is really difficult to notice this tweened animation (in contrast, the routine map refreshing interval is greater than 100 milliseconds). As a result, CPU usage would become high without noticeable improvement of gaming experience
		; * What's worse, only when the hero / monster moves to `x/4`, `x/2`, or `3x/4` pixels away from the original position would the app update the monster's actual position. In all other frames, the screen would just be exactly same as previous screens, yet the bitmap will still be drawn onto the display, which is a sheer waste of your PC's computation resource
		; Therefore, I will do the following two changes here:
		; * Sleep several milliseconds before drawing the next frame to make the transition animation appear more natural without noticeable lag (which also requires less CPU usage)
		; * Cut down the number of interpolation frames to 4, because as discussed above, only 4 of them are useful (i.e., different from other bitmaps)
		
BASE:4C04C	TTSW10.idou	proc near	; rōmaji of 移動; movement; of hero
		; ...
BASE:4C0CD		mov eax, [ebx+0254]	; TTSW10.Image6: TImage (icon for OrbOfHero)
BASE:4C0D3		mov esi, [eax+2C]	; esi = TImage.Width (32 or 40)
		; original bytes:
;BASE:4C0D6		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:4C0DC		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked
		; ... (briefly: for high-speed mode, esi /= 4; for middle-speed mode, esi /= 2)
;BASE:4C0FF		mov ebp, esi	; ebp = esi = width or width/2 or width/4
;BASE:4C101		test ebp, ebp
;BASE:4C103		jle loc_idou_loop_end
		; patched bytes:
BASE:4C0D6		shr esi, 2	; esi = width/4 (everytime, draw hero at this offset)
BASE:4C0D9		mov ebp, 4	; ebp = 4 (draw 4 frames in total)
BASE:4C0DE		jmp BASE:4C109	; ebp = 4 (draw 4 frames in total)

BASE:4C0E0	loc_duration1:
			db 0A, 0E, 1C, 2A	; 10, 14, 28, 42 ms sleep during movement tweens (for SuperFast, High, Middle, Low speed modes, respectively)
		; ...
		; ----------
BASE:4C109		mov edi, 1	; edi = 1, 2, ..., ebp
BASE:4C10E	loc_idou_loop_begin:
			mov [BASE:8C56C], edi
		; original bytes:
;BASE:4C114		mov [BASE:8C55C], edi	; distance w.r.t original position
		; ... (briefly, test if esi is width/2 or width/4, and if so, multiply [BASE:8C55C] with 2 or 4)
		; patched bytes:
BASE:4C114		mov eax, edi	; eax = 1, 2, 3, or 4
BASE:4C116		mul esi	; eax *= width/4
BASE:4C118		mov [BASE:8C55C], eax	; distance w.r.t original position
BASE:4C11D		push offset BASE:4C15E	; will call loc_idou_sleep next; then should goto this address after `ret`
BASE:4C122		xchg ax, ax	; 2-byte nop

BASE:4C124	loc_idou_sleep:
			movzx eax, byte ptr [BASE:89B9F]	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:4C12B		mov al, [eax+loc_duration1]	; 10/14/28/42 (the high-24-bits are 0 anyway; only need to set the low byte)
BASE:4C131		push eax	; dwMilliseconds: SuperFast: 10 ms; Fast: 14 ms; Middle: 28 ms; Low: 42 ms
BASE:4C132		mov eax, [BASE:89BFC]	; vacant dword pointer; used to store [KERNEL32.Sleep]
BASE:4C137		test eax, eax	; if KERNEL32.Sleep is already loaded...
BASE:4C139		jne loc_idou_sleep_call	; ...then no need to reload; call directly
BASE:4C13B		push offset BASE:BB5FC	; 'kernel32.dll'
BASE:4C140		call BASE:04BFC	; kernel32.LoadLibraryA
BASE:4C145		push offset BASE:4C158	; ('Sleep' see below)
BASE:4C14A		push eax
BASE:4C14B		call BASE:04B84	; kernel32.GetProcAddress
BASE:4C150		mov [BASE:89BFC], eax	; store address
BASE:4C155	loc_idou_sleep_call:
			call eax
BASE:4C157		ret
BASE:4C158	db 'Sleep', 0
		; ----------

BASE:4C15E		mov eax, ebx
BASE:4C160		call TTSW10.yusyaidou	; rōmaji of 勇者移動; movement of hero
BASE:4C165		mov eax, [BASE:8C514]	; TBitmap (the first of the two "oscillating" game map bitmaps)
BASE:4C16A		push eax	; arg3
BASE:4C16B		mov eax, [BASE:8C510]	; TTSW10
BASE:4C170		call TForm.GetCanvas	; eax = arg0: TCanvas
BASE:4C175		mov ecx, [BASE:8C57C]	; arg2 = Y (game map rect's Left)
BASE:4C17B		mov edx, [BASE:8C578]	; arg1 = X (game map rect's Top)
BASE:4C181		call TCanvas.Draw	; the codes from BASE:45165 till here draws a memory bitmap onto game window's screen DC
BASE:4C186		inc edi	; edi = 1, 2, 3, or 4
BASE:4C187		dec ebp	; ebp = 3, 2, 1, or 0
BASE:4C188		jne loc_idou_loop_begin
BASE:4C18A	loc_idou_loop_end:
		; ...
		TTSW10.idou	endp

BASE:80384	TTSW10.monidou	proc near	; movement of monsters
		; ...
BASE:803DD		mov eax, [ebx+0254]	; TTSW10.Image6: TImage (icon for OrbOfHero)
BASE:803E3		mov ebp, [eax+2C]	; ebp = TImage.Width (32 or 40)
		; original bytes:
;BASE:803E6		test ebp, ebp
;BASE:803E8		jle loc_monidou_loop_end
;BASE:803EE		mov [esp], 1	; [esp] = 1, 2, ..., width
;BASE:803F5	loc_monidou_loop_begin:
		; patched bytes:
BASE:803E6		shr ebp, 2	; distance w.r.t original position = width/4
BASE:803E9		mov [esp], ebp	; [esp] = width/4 (then width/2, 3width/4, width)
BASE:803EC		nop [eax+0]	; 3-byte nop
BASE:803F0	loc_monidou_loop_begin_new:
			call loc_idou_sleep
		; ----------

BASE:803F5		mov eax, [esp]
			; ...

		; original bytes:
;BASE:807B2		inc [esp]
;BASE:807B5		dec ebp
;BASE:807B6		jne loc_monidou_loop_begin
;BASE:807BC	loc_monidou_loop_end:
;			mov eax, [ebx+0254]	; TTSW10.Image6: TImage (icon for OrbOfHero)
;BASE:807C2		mov eax, [eax+2C]	; TImage.Width (32 or 40)
		; patched bytes:
BASE:807B2		add [esp], ebp	; [esp] = width/2 (then 3width/4, width, 5width/4)
BASE:807B5		mov eax, ebp
BASE:807B7		shr eax, 2	; eax = width
BASE:807BA		cmp [esp], eax
BASE:807BD		jbe loc_monidou_loop_begin_new
BASE:807C3		xchg ax, ax	; 2-byte nop
BASE:807C5	; ...
		TTSW10.monidou	endp


;============================================================
		; Rev5: Improve battle animation: There should be a non-zero interval for showing "hit" animations between battle rounds
		; - How it used to work: The interval of Timer1 (routine animation) matched with that of Timer2 (event animation). So if the triggered timing of Timer2 is "out-of-phase" with Timer1, then Timer2 and Timer1 will work alternately, showing hit animation and no hit animation in a loop. However, if the starting time of Timer2 is "in-phase" with Timer1, then there will also be no interval between hit animations
		; - Why it no longer works: In the Rev version, the intervals of Timer1 and Timer2 are different, so these timers will be "incommensurate"
		; - A better design: is to not rely on the hope that two different timers will happen to be "out-of-phase," but rather, temporarily disable Timer1 and handle all drawing within Timer2
BASE:526C0	TTSW10.stackwork	proc near
		; ...
		; In TSW, event interpreter deals with multiple 3-word event sequences, starting from address BASE:8C74C. The current event sequence index is stored in [BASE:8C5AC]. The first word in the 3-word sequence is the major type of the event (e.g. 0001 is related to BGM and sound playing, 0002 is related to showing messages in the status bar, etc.). For more details on how the event sequences work in TSW, see tswBGM.asm

		; 5,A,B (enemy HP update)
BASE:52C25	; original bytes:
;			jmp loc_stackwork_end	; BASE:547E8; end of treatment
		; patched bytes:
			jmp loc_stackwork_draw_bitmap2	; see below
		; this will draw the tile without the "hit" animation, i.e. serving as a pause for showing "hit" animations between battle rounds
		; ...

		; 4,A,B (hero HP update)
BASE:52C95	; original bytes:
;			jmp loc_stackwork_end	; BASE:547E8; end of treatment
		; patched bytes:
			jmp loc_stackwork_draw_bitmap2	; see below
		; this will draw the tile without the "hit" animation, i.e. serving as a pause for showing "hit" animations between battle rounds
		; ...

		; 9,A,B (overlay some bitmap on top of a tile)
		; For example, during battle, the "hit" animation will be overlaid on top of the monster tile
		; Starting from BASE:52F30, TSW would draw "hit" animation to memory bitmap #0 (the first of the two "oscillating" game map bitmaps), which will eventually drawn onto the physical screen (starting from BASE:53166)
		; ...
		; Starting from BASE:53029, TSW would draw "hit" animation to memory bitmap #1 (the second of the two "oscillating" game map bitmaps), and we will change some codes here to hide the "hit" animation (thus serving as a pause for showing "hit" animations between battle rounds)

		; original bytes:
;BASE:53029		push 0	; arg3: Y
;BASE:5302B		mov eax, [BASE:8C5AC]
;BASE:53030		lea eax, [eax+eax*2]
;BASE:53033		movsx eax,word ptr [eax*2+BASE:8C750]	; `B` parameter in the current (9,A,B) event sequence; this is the tile index of the monochromic mask of the "hit" animation
;BASE:5303B		dec eax	; 0-based
;BASE:5303C		push eax	; arg4: Index
;BASE:5303D		mov eax, [BASE:8C524]	; TBitmap: memory bitmap which is of one-tile-width and -height
;BASE:53042		call TBitmap.GetCanvas	; TCanvas
;BASE:53047		mov edx,eax	; arg1: Canvas
;BASE:53049		xor ecx,ecx	; arg2: X
;BASE:5304B		mov eax, [ebx+01B0]	; arg0: TTSW10.ImageList1: TImageList
;BASE:53051		call TCustomImageList.Draw

;BASE:53056		mov eax, [BASE:8C5AC]
;BASE:5305B		lea eax, [eax+eax*2]
;BASE:5305E		movsx eax, word ptr [eax*2+BASE:8C748]	; `A` parameter in the current (0,A,B) event sequence; this is the tile index of the monster
;BASE:53066		mov [BASE:8C5A8], eax	; this is the input for TTSW10.imagework: the tile index in the first frame
;BASE:5306B		mov eax,ebx	; this line is not necessary
;BASE:5306D		call TTSW10.imagework	; this calculates the tile index of the second frame given that of the first frame, with offset given in BASE:8C554 (e.g., normal monsters: +1; Dragon: +9)
;BASE:53072		push 0	; arg3: Y
;BASE:53074		mov eax, [BASE:8C5AC]
;BASE:53079		lea eax, [eax+eax*2]
;BASE:5307C		movsx eax,word ptr [eax*2+BASE:8C748]	; same as above
;BASE:53084		dec eax	; 0-based
;BASE:53085		add eax,[BASE:8C554]	; this is the output of TTSW10.imagework
;BASE:5308B		push eax	; arg4: Index
;BASE:5308C		mov eax, [BASE:8C51C]	; TBitmap: memory bitmap which is of one-tile-width and -height
;BASE:53091		call TBitmap.GetCanvas	; TCanvas
;BASE:53096		mov edx,eax	; arg1: Canvas
;BASE:53098		xor ecx,ecx	; arg2: X
;BASE:5309A		mov eax, [ebx+01B0]	; arg0: TTSW10.ImageList1: TImageList
;BASE:530A0		call TCustomImageList.Draw

;BASE:530A5		mov eax, [BASE:8C5AC]
;BASE:530AA		lea eax, [eax+eax*2]
;BASE:530AD		movsx eax,word ptr [eax*2+BASE:8C74A]	; `B` parameter in the last (0,A,B) event sequence; this is the tile index of the (unmasked) "hit" animation
;BASE:530B5		mov [BASE:8C5A8], eax	; this is the input for TTSW10.imagework: the tile index in the first frame
;BASE:530BA		mov eax, ebx	; this line is not necessary
;BASE:530BC		call TTSW10.imagework	; BASE:54C10
;BASE:530C1		push 0	; arg3: Y
;BASE:530C3		mov eax, [BASE:8C5AC]
;BASE:530C8		lea eax, [eax+eax*2]
;BASE:530CB		movsx eax, [eax*2+BASE:8C74A]	; same as above
;BASE:530D3		dec eax	; 0-based
;BASE:530D4		add eax, [BASE:8C554]	; this is the output of TTSW10.imagework
;BASE:530DA		push eax	; arg4: Index
;BASE:530DB		mov eax, [BASE:8C520]	; TBitmap: memory bitmap which is of one-tile-width and -height
;BASE:530E0		call TBitmap.GetCanvas	; TCanvas
;BASE:530E5		mov edx, eax	; arg1: Canvas
;BASE:530E7		xor ecx, ecx	; arg2: X
;BASE:530E9		mov eax, [ebx+01B0]	; arg0: TTSW10.ImageList1: TImageList
;BASE:530EF		call TCustomImageList.Draw

;BASE:530F4		mov eax, ebx	; this line is not necessary
;BASE:530F6		call TTSW10.kasanegaki	; rōmaji of 重ね書き; overlay
		; at the end, [BASE:8C520] will be masked by [BASE:8C524], and finally drawn onto [BASE:8C51C]

;BASE:530FB		mov eax, [BASE:8C5AC]
;BASE:53100		lea eax, [eax+eax*2]
;BASE:53103		movsx ecx, word ptr [eax*2+BASE:8C74E]	; `A` parameter in the current (9,A,B) event sequence; map index
;BASE:5310B		mov eax, ecx	; eax = map index = 11*y+x
;BASE:5310D		mov esi, 0B
;BASE:53112		cdq
;BASE:53113		idiv esi	; edx = x (remainder)
;BASE:53115		mov eax, [ebx+0254]	; TTSW10.Image6: TImage (icon for OrbOfHero)
;BASE:5311B		imul edx, [eax+2C]	; TImage.Width (32 or 40)
;BASE:5311F		mov [BASE:8C54C], edx	; X
;BASE:53125		mov eax, [BASE:8C5AC]
;BASE:5312A		lea eax, [eax+eax*2]
;BASE:5312D		mov eax, ecx
;BASE:5312F		mov ecx, 0B
;BASE:53134		cdq
;BASE:53135		idiv ecx	; eax = y (quotient)
;BASE:53137		mov edx, [ebx+0254]	; this recalculation here can be optimized
;BASE:5313D		imul [edx+30]	; TImage.Height (32 or 40)
;BASE:53140		mov [BASE:8C550], eax	; Y
;BASE:53145		mov eax, [BASE:8C51C]	; TBitmap: memory bitmap which is of one-tile-width and -height
;BASE:5314A		push eax	; arg3: Graphic (source)
;BASE:5314B		mov eax, [BASE:8C518]	; TBitmap: the second of the two "oscillating" game map bitmaps
;BASE:53150		call TBitmap.GetCanvas	; arg0: Canvas (destination)
;BASE:53155		mov ecx, [BASE:8C550]	; arg2: Y
;BASE:5315B		mov edx, [BASE:8C54C]	; arg1: X
;BASE:53161		call TCanvas.Draw

		; patched bytes:
BASE:53029		imul eax, [BASE:8C5AC], 06
BASE:53030		add eax, offset BASE:8C74C	; current event sequence pointer
BASE:53035		push eax	; store this pointer
BASE:53036		xor edx,edx	; dl = 0 <- TTimer.Enabled (False)
BASE:53038		xor ecx,ecx	; clear all bytes
BASE:5303A		mov cl, [eax-0C]	; the major type of event; two sequences before
BASE:5303D		sub cl, 04	; make sure is 4 or 5 (update hero or enemy HP), i.e., within a battle event (because 9,A,B can be used in other events as well, which should be excluded)
BASE:53040		cmp cl, 01
BASE:53043		ja loc_stackwork_update_bitmap2	; not 4 or 5, then follow the TSW's old treatment
		; note: now, edx=0, so the offset of the overlay tile index is also 0, i.e., no additional treatment
BASE:53045		jne loc_stackwork_offset_m2	; i.e., cl == 4 (meaning updating hero HP); in this case, the overlay tile was hero+hit, and now we want just hero (in proper direction without hit), so simply an offset of -2 will do the job (see BMP file `Data/Chtable.oz`)
		; otherwise, cl == 5 (meaning updating enemy HP); this will be a more complex case, where the overlay tile was just hit, but now we want hero in proper direction without hit
		; the hit mask has an index that is 1 smaller than that of hit; but the hero+hit mask has an index that is 1 larger than that of hero+hit (see BMP file `Data/Chtable.oz`), so we must mark a flag (`ch`) here and remember to deal with it later
BASE:53047		imul ecx, [BASE:B87E8], 08	; BASE:B87E8 is the facing direction of hero; 1=down; 2=left; 3=right; 4=up; each one has 8 tiles, so the offset will be +8*this value
BASE:5304E		mov ch, 01	; mark a flag to account for the scrambled offset

BASE:53050	loc_stackwork_offset_m2:
			sub cl, 02

BASE:53053		cmp byte ptr [eax-24], 09 ; the major type of event four sequences before
BASE:53057		je loc_stackwork_offset_0	; make sure still within a battle event, then do somthing to TBitmap2; otherwise, for the last battle animation (whose [eax-24] != 9), should follw the old TSW's treatment (this is to give the last hit animation a longer duration to show; otherwise in the SuperFast mode, sometimes you can't even see the hit animation (too fast for Windows GUI to have time to update?))

BASE:53059		mov [BASE:8C5D2], dl	; this controls which of the two "oscillating" game map bitmaps to be shown next (0 or 1)
			; this is necessary (must show one of the two bitmaps first) because the other bitmap is not updated yet, so if that one is shown, there will be two separated "hit" animations within the last one round; and sometimes in the SuperFast mode, you can't even see the hit animation
BASE:5305F		mov ecx, edx	; = 0
BASE:53061		inc edx	; dl = 1 <- TTimer.Enabled (True)

BASE:53062	loc_stackwork_offset_0:
			push ecx
BASE:53063		mov eax, [ebx+01B4]	; TTSW10.Timer1: TTimer
BASE:53069		call TTimer.SetEnabled	; disable Timer1 during battle event and use Timer2 only (dl = 0); or reenable Timer1 after the battle event finishes (dl = 1)

BASE:5306E		pop edx	; tile offset
BASE:5306F	loc_stackwork_update_bitmap2:
			pop ecx	; current event sequence pointer
BASE:53070		movsx eax, word ptr [ecx+02]	; `A` parameter in the current (9,A,B) event sequence; map index
BASE:53074		push eax	; store

BASE:53075		movsx eax, word ptr [ecx-02]	; `B` parameter in the last (0,A,B) event sequence; this is the tile index of the (unmasked) "hit" animation
BASE:53079		add al, dl	; account for the offset
BASE:5307B		sub al, dh	; account for the scrambled offset
BASE:5307D		push eax	; store
BASE:5307E		push eax	; store twice (the first is for TTSW10.imagework and the second for TCustomImageList.Draw)

BASE:5307F		movsx eax, word ptr [ecx-04]	; `A` parameter in the current (0,A,B) event sequence; this is the tile index of the monster
BASE:53083		push eax	; store
BASE:53084		mov [BASE:8C5A8], eax	; input for TTSW10.imagework later

BASE:53089		movsx eax, word ptr [ecx+04]	; `B` parameter in the current (9,A,B) event sequence; this is the tile index of the monochromic mask of the "hit" animation
BASE:5308D		add al, dl	; account for the offset
BASE:5308F		add al ,dh	; account for the scrambled offset
BASE:53091		dec eax
BASE:53092		mov edx, offset BASE:8C524	; TBitmap
BASE:53097		call loc_stackwork_draw_tile	; see below

BASE:5309C		call imagework
BASE:530A1		pop eax		; `A` parameter in the current (0,A,B) event sequence; this is the tile index of the monster
BASE:530A2		dec eax
BASE:530A3		add eax, [BASE:8C554]	; output of TTSW10.imagework
BASE:530A9		mov edx, offset BASE:8C51C	; TBitmap
BASE:530AE		call loc_stackwork_draw_tile	; see below

BASE:530B3		pop [BASE:8C5A8]	; input for TTSW10.imagework
BASE:530B9		call TTSW10.imagework
BASE:530BE		pop eax	; `B` parameter in the last (0,A,B) event sequence; this is the tile index of the (unmasked) "hit" animation
BASE:530BF		dec eax
BASE:530C0		add eax, [BASE:8C554]	; output of TTSW10.imagework
BASE:530C6		mov edx, offset BASE:8C520	; TBitmap
BASE:530CB		call loc_stackwork_draw_tile	; see below

BASE:530D0		call TTSW10.kasanegaki	; rōmaji of 重ね書き; overlay
		; at the end, [BASE:8C520] will be masked by [BASE:8C524], and finally drawn onto [BASE:8C51C]

BASE:530D5		mov eax, [BASE:8C518]	; TBitmap2
BASE:530DA		call TBitmap.GetCanvas
BASE:530DF		mov edi,eax	; store TCanvas
BASE:530E1		pop eax	; `A` parameter in the current (9,A,B) event sequence; map index
BASE:530E2		mov cl, 0B
BASE:530E4		div cl	; al = y (quotient); ah = x (remainder)
BASE:530E6		mov dl, ah	; store x
BASE:530E8		mov esi, [ebx+0254]
BASE:530EE		mul byte ptr [esi+2C]
BASE:530F1		mov ecx, eax	; Y
BASE:530F3		mov al, dl
BASE:530F5		mul byte ptr [esi+2C]
BASE:530F8		mov edx,eax	; X
BASE:530FA		mov eax,edi	; Canvas
BASE:530FC		push [BASE:8C51C]	; Graphic
BASE:53102		call TCanvas.Draw

BASE:53107		mov eax, [BASE:8C514]	; TBitmap: the first of the two "oscillating" game map bitmaps with the "hit" animation
BASE:5310C		jmp loc_stackwork_draw_bitmap
BASE:5310E		nop

BASE:53110	loc_stackwork_draw_tile: ; a routine for TCustomImageList.Draw with common parameters (argv: eax=index; edx=TBitmap pointer)
			push 00	; arg3: Y
BASE:53112		push eax	; arg4: Index
BASE:53113		mov eax, [edx]
BASE:53115		call TBitmap.GetCanvas
BASE:5311A		mov edx,eax	; arg1: Canvas
BASE:5311C		xor ecx,ecx	; arg2: X
BASE:5311E		mov eax, [ebx+01B0]	; arg0: TTSW10.ImageList1: TImageList
BASE:53124		call TCustomImageList.Draw
BASE:53129		ret
BASE:5312A		nop
		; ...

BASE:53166	; original bytes:
;			mov eax, [BASE:8C514]	; TBitmap: the first of the two "oscillating" game map bitmaps
		; patched bytes:
		loc_stackwork_draw_bitmap2:
			mov eax, [BASE:8C518]	; this was jumped from BASE:52C25 or BASE:52C95, where the "hit" animation is paused between rounds
BASE:5316B	loc_stackwork_draw_bitmap:	; this can be jumped from BASE:5315F, in which case the "hit" animation will be drawn
			push eax
BASE:5316C		mov eax, [BASE:8C510]	; TTSW10
BASE:53171		call TForm.GetCanvas	; eax = arg0: TCanvas
BASE:53176		mov ecx, [BASE:8C57C]	; arg2 = Y (game map rect's Left)
BASE:5317C		mov edx, [BASE:8C578]	; arg1 = X (game map rect's Top)
BASE:53182		call TCanvas.Draw	; the codes from BASE:45165 till here draws a memory bitmap onto game window's screen DC
BASE:53187		jmp loc_stackwork_end	; BASE:547E8; end of treatment
			; ...


;============================================================
		; Rev6: Speed up stair animation
		; Originally, TSW drew two "sword and staff" tile at a time, so showing and hiding 121 tiles in the map each took 61 Timer cycles. Timer interval is, at minimum, 10 ms on windows, so the whole up/downstairs animation took at least 1.21 s. This waiting time had better be shortened in the fast or superfast speed mode.
		; 21,A,B (stair animation)
		; A = 0/1 show/hide "sword and staff" tile; B = 0,1,...,121
		; original bytes:
;BASE:5433B		movsx eax, word ptr [ecx*2+BASE:8C750]	; `B` parameter in the current (21,A,B) event sequence (ecx = 3*[BASE:8C5AC])
;BASE:54343		mov [BASE:8C570], eax
;BASE:54348		mov eax, [BASE:8C570]	; redundant
;BASE:5434D		movzx edi, byte ptr [eax+BASE:89B1F]	; this is the predefined sequence specifying the tile showing order (which forms a counterclockwise spiral chronologically)
;BASE:54354		mov eax, edi
;BASE:54356		mov edx, [ebx+0254]	; TTSW10.Image6: TImage (icon for OrbOfHero)
;BASE:5435C		mov esi, [edx+2C]	; TImage.Width (32 or 40)
;BASE:5435F		imul esi
;BASE:54361		imul edx, esi, 0B
;BASE:54364		mov esi, edx
;BASE:54366		cdq
;BASE:54367		idiv esi
;BASE:54369		mov [BASE:8C54C], edx	; Y
;BASE:5436F		mov eax, [BASE:8C570]
;BASE:54374		mov eax, edi
;BASE:54376		mov edx, [ebx+0254]
;BASE:5437C		mov esi, [edx+30]	; TImage.Height (32 or 40)
;BASE:5437F		imul esi
;BASE:54381		imul edx, esi, 0B
;BASE:54384		mov edi, edx
;BASE:54386		cdq
;BASE:54387		idiv edi
;BASE:54389		imul esi	; this recalculation here can be optimized
;BASE:5438B		mov [BASE:8C550], eax	; X
;BASE:54390		mov ax, [ecx*2+BASE:8C74E]	; `A` parameter in the current (21,A,B) event sequence
;BASE:54398		sub ax, 01
;BASE:5439C		jb loc_stackwork_stair_ani_show	; `A` == 0; BASE:543A9
;BASE:5439E		je loc_stackwork_stair_ani_hide	; `A` == 1; BASE:544D9
;BASE:543A4		jmp loc_stackwork_end	; this is not likely
;BASE:543A9	loc_stackwork_stair_ani_show:
;			cmp [BASE:B87EC], 0	; this byte stores the "whether-to-enable-soundeffect" setting
;BASE:543B0		jne loc_stackwork_stair_ani_show_2
;BASE:543B2		cmp [BASE:8C570], 1	; play this sound effect only at the very beginning (i.e., `B` == 1)
;BASE:543B9		jne loc_stackwork_stair_ani_show_2
;BASE:543BB		mov eax, [ebx+02D4]	; TTSW10.MediaPlayer1: TMediaPlayer ('open.wav')
;BASE:543C1		call TMediaPlayer.Play	; BASE:31250
;BASE:543C6	loc_stackwork_stair_ani_show_2:
			; this treatment will process two (21,A,B) event sequences at a time, i.e., will draw two tiles at a time

		; patched bytes:
BASE:5433B		xor edi, edi	; edi = repetition times
BASE:5433D		inc edi	; edi = 1
BASE:5433E		cmp byte ptr [BASE:89B9F], 01	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:54345		ja BASE:54368	; Middle or Low mode: show 2*1 tiles at a time
BASE:54347		inc edi	; edi = 2
BASE:54348		jae BASE:54368	; High mode: show 2*2 tiles at a time
BASE:5434A		shl edi,1	; SuperFast mode: show 2*4 tiles at a time
BASE:5434C		jmp BASE:54368

BASE:5434E	loc_stackwork_stair_ani_hide_loop:
			cmp [BASE:8C570], 0079	; 121
BASE:54355		je loc_stackwork_stair_ani_hide_end

BASE:5435B	loc_stackwork_stair_ani_show_loop:
			dec edi
BASE:5435C		je loc_stackwork_end

BASE:54362		dec [BASE:8C5AC]

BASE:54368		imul esi, [BASE:8C5AC], 06
BASE:5436F		add esi, BASE:8C74E
BASE:54375		movzx eax, word ptr [esi+02]	; `B`
BASE:54379		mov [BASE:8C570], eax
BASE:5437E		movzx eax, byte ptr [eax+BASE:89B1F]
BASE:54385		mov cl, 0B
BASE:54387		div cl	; ah = x; al = y
BASE:54389		mov dl, ah	; store remainder (x)
BASE:5438B		mov ecx, [ebx+0254]
BASE:54391		mul byte ptr [ecx+2C]
BASE:54394		mov [BASE:8C550], eax	; Y
BASE:54399		mov al, dl
BASE:5439B		mul byte ptr [ecx+2C]
BASE:5439E		mov [BASE:8C54C], eax	; X
BASE:543A3		cmp byte ptr [esi], 00	; `A`
BASE:543A6		je loc_stackwork_stair_ani_show_2	; BASE:543C6
		; here, I ran out of space to insert codes for playing the soundeffect; will be handled later
BASE:543A8		jmp loc_stackwork_stair_ani_hide	; BASE:544D9
		; ...

BASE:5448C	; original bytes:
;			cmp [BASE:8C570], 1	; `B`
		; ...
		; as I mentioned above, each Timer2 cycle draws 2 tiles, and here is just the second one. The codes here are similar to those starting from BASE:543B2
		; however, it is impossible to have `B` == 1 here: Even at the very beginning, `B` will be 2, so this code block was never executed
		; patched bytes:
			cmp [BASE:8C570], 2
		; as I mentioned above, I ran out of space and was unable to insert codes for playing the soundeffect. But here is a perfect place to handle this issue. So `B` == 2 just means it is the very beginning, and the soundeffect will be played in such cases.
		; ...

BASE:544D4	; original bytes:
;			jmp loc_stackwork_end
		; patched bytes:
			jmp loc_stackwork_stair_ani_show_loop	; check if more drawing needed in this cycle

BASE:547B4	; original bytes:
;			cmp [BASE:8C570], 0079	; 121
;			jne loc_stackwork_end

		; patched bytes:
			jmp loc_stackwork_stair_ani_hide_loop	; check if more drawing needed in this cycle
			xchg ax, ax	; 2-byte nop
BASE:547BD	loc_stackwork_stair_ani_hide_end:
		; ...

BASE:547E8	loc_stackwork_end:
		; ...

		TTSW10.stackwork	endp


BASE:42DC8	TTSW10.kaidanwork	proc near	; kaidan = rōmaji of 階段; stair
		; ...
BASE:42E6D		cmp dword ptr [BASE:B87F0], 0	; this stores BGM id; and if ==0, it means the BGM is turned off by user
BASE:42E74		je BASE:42E96
BASE:42E76	; original bytes:
;			cmp eax, 0014	; eax = 1 to 121; this line means that only when there are 20 "sword and staff" tiles remaining, the following codes (replay BGM) will be run
;		However, in our modified SuperFast and High speed modes, several tile-drawing procedures are drawn at a time, and this eax==20 condition will be skipped
;		In order to make this condition always be met, I will change the number from 20 to 1 now
		; patched bytes:
			cmp eax, 1	; eax = 1 to 121; this line means that only when there is 1 "sword and staff" tiles remaining, the following codes (replay BGM) will be run
BASE:42E79		jne BASE:42E96
		; ...
		; briefly, a (15,0,0) event sequence (replay BGM according to the current floor number) will be added here
BASE:42E96	; ...

		; because the stair animation time will be different in different modes, so the duration of the soundeffect should also be adjusted accordingly
		; original bytes:
;BASE:42EEE		mov word ptr [esi+eax*2], 0000
;BASE:42EF4		mov word ptr [esi+eax*2+02], 0000
;BASE:42EFB		mov word ptr [esi+eax*2+04], 0000
;BASE:42F02		inc [ebx]
;BASE:42F04		mov eax, [ebx]
;BASE:42F06		lea eax, [eax+eax*2]
;BASE:42F09		mov word ptr [esi+eax*2], 0001
;BASE:42F0F		mov word ptr [esi+eax*2+02], 0009
;BASE:42F16		mov word ptr [esi+eax*2+04], 0000	; (1,9,0) = play MediaPlayer5 with file "kai.wav" (two consecutive "dadadadada" sounds)

		; patched bytes:
BASE:42EEE		xor edx,edx	; edx = 0
BASE:42EF0		mov [esi+eax*2], edx
BASE:42EF3		mov [esi+eax*2+04], dx
BASE:42EF8		inc [ebx]
BASE:42EFA		add eax, 03
BASE:42EFD		mov [esi+eax*2+02], edx
BASE:42F01		cmp byte ptr [BASE:89B9F], 01	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:42F08		setae dl	; SuperFast: 0; otherwise: 1
BASE:42F0B		mov [esi+eax*2], dx
BASE:42F0F		setbe dl
BASE:42F12		add dl, 09	; Fast: 10; Middle or Low: 9
BASE:42F15		mov [esi+eax*2+02], dl
		; at the end of the day,
		; - SuperFast = (0, 10, 0) = do nothing (but will still play "open.wav" (one "pa" sound) in TTSW10.stackwork; see above)
		; - Fast = (1, 10, 0) = play "kai2.wav" (one "dadadadada" sound)
		; - Middle or Low = (1, 9, 0) = play "kai.wav" (two consecutive "dadadadada" sounds)
BASE:42F19		jmp BASE:42F1D
		; ...
BASE:42F1D	; ...
		; ...

		TTSW10.kaidanwork	endp


;============================================================
		; Rev7: Speed up door-opening animation
		; Originally, TSW drew 16 frames for door-opening (as well as gate-closing/wall-collapsing/wall-rising etc.) animations. Timer interval is, at minimum, 10 ms on windows, so the whole animation took at least 0.2 s. This waiting time had better be shortened in the fast or superfast speed mode.
BASE:660D0	TTSW10.doorstackin	proc near
		; The original codes are too lengthy and redundant, so I will just briefly explain what the basic logics of the codes are:
		; At the beginning, there is only one event sequence ([BASE:8C5AC]=n+1):
		; - (13,A,B), where `A` is the map index = 11*y+x, and `B` is the door type (1=open yellow door; 2=open blue door; 3=open red door; 4=open gate; 5=close gate; 6=open prison; 7=collapse wall; 8=rise wall; 9-12=freeze lava in 4 directions)
		; At the end, there will be 16*2 event sequences ([BASE:8C5AC]=n+32):
		; - (0,0,16), (13,A,B); (0,0,15), (13,A,B); (0,0,14), (13,A,B); ...; (0,0,1), (13,A,B); where each pair is one frame animation (16 frames in total)
		; patched bytes: (rewritten codes with saved space, so our codes can be inserted at the end)
BASE:660D0		push eax	; save eax=TTSW10
BASE:660D1		call TTSW10.Timer1Timer	; BASE:43120
BASE:660D6		pop eax	; retrieve eax=TTSW10
BASE:660D7		call TTSW10.Timer1Timer	; BASE:43120
			; update game map drawing twice here is necessary for 3 reasons:
			; - otherwise, there will be a frame where the hero unnaturally changes the facing direction
			; - otherwise, when fighting Octopus and Dragon, their tiles couldn't be eliminated properly, because there will be a lag before the two memory bitmaps (updated by TTSW10.takowork and takowork2 (tako = rōmaji of 蛸; octopus)) get drawn, which will interfere with the appearance of other item tiles
			; - otherwise, there will be a lag before the hero turns his facing direction

BASE:660DC		mov edx, offset BASE:8C5AC
BASE:660E1		imul eax, [edx], 06
BASE:660E4		add eax, offset BASE:8C74C	; eax is now pointer of the current event sequence
BASE:660E9		dec [edx]	; eliminate the initial (13,A,B) sequence
BASE:660EB		mov edx, [eax+02]	; word `A` and word `B` together as a dword
BASE:660EE		mov ecx, 00000010	; 16 frames

BASE:660F3	loc_doorstackin_loop_begin:
			mov [eax], 00000000	; (0, 0, ...)
BASE:660F9		mov [eax+04], ecx	; (0, 0, ecx), (0, ..., ...) (ecx = 16, 15, ..., 1)
BASE:660FC		mov byte ptr [eax+06], 0D	; (13, ..., ...)
BASE:66100		mov [eax+08],edx	; (13, A, B)
BASE:66103		add eax, 0C
BASE:66106		add [BASE:8C5AC], 2
BASE:6610D		loop loc_doorstackin_loop_begin	; ecx--; ecx>0
BASE:6610F		ret

		; The effect of our new codes here are the same with the original codes (except for calling Timer1Timer); furthur treatments will be processed below. The reason why I don't intervene right here is because I want to keep the number of the event sequences, which matters in terms of judging the soundeffect mode (see tswBGM.asm; Line 146-164)
		TTSW10.doorstackin	endp	; originally ended at BASE:664E2, now ends at BASE:6611A, which leaves us enough space for inserting our own codes here

BASE:66110	loc_dooropen_new:	; will be called at BASE:53A2F below; in replacement of TTSW10.dooropen
		; briefly, only one out of X frame will be processed whereas others will be discarded; X = 1, 1, 2, 4 when in Low/Middle/High/SuperFast speed mode, respectively
		; originally, I tried X=8 for SuperFast mode, but there will be ~50% chance that no animation will be seen (too fast for Windows GUI to have time to update?)
			mov al, [BASE:89B9F]	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:66115		dec al	; -1/0/1/2
BASE:66117		cmp al, 1
BASE:66119		setbe dl	; 0/1/1/0
BASE:6611C		add al, dl	; -1/1/2/2
BASE:6611E		mov cl, 2
BASE:66120		sub cl, al	; s = 3/1/0/0
BASE:66122		mov edx, offset BASE:8C5AC
BASE:66127		imul eax, [edx], 06
BASE:6612A		add eax, offset BASE:8C74A	; which frame f = (16, 15, ..., 1)

BASE:6612F	loc_dooropen_new_next:
			test [eax], cl	; f & s == 0 means f is an integer multiple of 4/2/1/1
BASE:66131		je loc_dooropen_new_effective
BASE:66133		sub [edx], 02	; otherwise, do nothing and go to next frame
BASE:66136		sub eax, 0C
BASE:66139		jmp loc_dooropen_new_next

BASE:6613B	loc_dooropen_new_effective:
			mov eax, ebx
BASE:6613D		jmp TTSW10.dooropen
BASE:66142		nop


		; in TTSW10.stackwork
		; (13, A, B)
		; add preprocessing for the original door opening treatment
		; original bytes:
;BASE:53A2A		mov eax, ebx
;BASE:53A2C		call TTSW10.dooropen
;BASE:53A31		jmp loc_stackwork_end
		; patched bytes:
BASE:53A2A		push offset loc_stackwork_end	; will jump to this address when `ret`
BASE:53A2F		jmp loc_dooropen_new
BASE:53A34		xchg ax, ax	; 2-byte nop


;============================================================
		; Rev8: Fix the wrong prompt after finishing the 40F boss battle
		; Originally, TSW will show a 'The door has opened.' prompt after you pass the 40F boss battle, which is incorrect--It should be a 'gate' that opens, but there is no such prompts in the game, so I will simply delete this event sequence

BASE:6CB1C	TTSW10.ichicheck	proc near	; ichi = rōmaji of 位置; position

BASE:740BE	; original bytes:
;			mov word ptr [esi+eax*2], 0002	; originally, here will insert an event sequence (2,4,0) that will show 'The door has opened.' prompt in the status bar
		; patched bytes:
			jmp +48	; bypass this event sequence
		; ...

		TTSW10.ichicheck	endp

;============================================================
		; Rev9: Fix the wrong GOLD income prompt after defeating a "strike-first" monster
		; Originally, when you defeat a "strike-first" monster with LuckyGold in your hand, you will earn 2x GOLD, but the prompt in the status bar will incorrectly show the amount of GOLD you have earned to be just 1x GOLD
BASE:7F7D4	TTSW10.taisen2	proc near	; taisen = rōmaji of 対戦; battle (with strike-first monsters)
		; ...
		; below will synthesize the string shown in the status bar after you win the battle (by concatenating several substrings that are pushed to the stack)
BASE:7FF28		push [ebp-08]	; "You have defeated"
BASE:7FF2B		push BASE:8027C	; " "
BASE:7FF30		push [BASE:B867C]	; {monster name}
BASE:7FF36		push BASE:80288	; ". "
BASE:7FF3B		lea ecx, [ebp-0C]	; string buffer pointer
BASE:7FF3E		mov eax, [ebp-04]	; TTSW10
BASE:7FF41		mov eax, [eax+044C]	; TTSW10.ListBox2: TListBox; this is where most game relevant texts are stored
BASE:7FF47		mov eax, [eax+0100]	; ?
BASE:7FF4D		mov edx, 000000C8	; the 200-th text item, i.e., "Received"
BASE:7FF52		mov edi, [eax]

		; original bytes:
;BASE:7FF54		call [edi+0C]	; this supposedly retrieves the caption of the corresponding ListBox2 item
;BASE:7FF57		push [ebp-0C]	; "Received"
;BASE:7FF5A		push BASE:8027C	; " "
;BASE:7FF5F		lea edx, [ebp-10]	; string buffer pointer
;BASE:7FF62		mov eax, [BASE:8C5B8]	; monster id
;BASE:7FF67		add eax, eax
;BASE:7FF69		mov eax, [eax*8+BASE:8991C]	; dword_8991C[id*4] is monster's GOLD
;BASE:7FF70		call IntToStr	; BASE:05B6C (forgot to take into consideration the effect of LuckyGold here)
;BASE:7FF75		push [ebp-10]	; {monster GOLD}
;BASE:7FF78		lea ecx, [ebp-14]	; string buffer pointer
;BASE:7FF7B		mov eax, [ebp-04]	; TTSW10
;BASE:7FF7E		mov eax, [eax+044C]	; TTSW10.ListBox2: TListBox; this is where most game relevant texts are stored
;BASE:7FF84		mov eax, [eax+0100]	; this calculation is done same as above; can be optimized
;BASE:7FF8A		mov edx, 000000C9	; the 201-th text item, i.e., " Gold."

		; patched bytes:
BASE:7FF54		mov [ebp-14], eax	; originally this serves as the string buffer pointer to string " Gold." But it has not been used yet, so it can be used to store the value of pointer [TTSW10.ListBox2+0100], which can save a bit space
BASE:7FF57		call [edi+0C]	; this supposedly retrieves the caption of the corresponding ListBox2 item
BASE:7FF5A		push [ebp-0C]	; "Received"
BASE:7FF5D		push BASE:8027C	; " "
BASE:7FF62		mov eax,[BASE:8C5B8]	; same as above...
BASE:7FF67		add eax, eax
BASE:7FF69		mov eax, [eax*8+BASE:8991C]
BASE:7FF70		mov edx, [BASE:B8704]	; whether you have LuckyGold (0 or 1)
BASE:7FF76		inc edx
BASE:7FF77		mul edx	; eax *= 2 if you have LuckyGold; similar to BASE:4AB2C in `TTSW10.taisen`
BASE:7FF79		lea edx, [ebp-10]	; string buffer pointer
BASE:7FF7C		call IntToStr	; BASE:05B6C
BASE:7FF81		push [ebp-10]	; {monster GOLD}
BASE:7FF84		lea ecx, [ebp-14]	; currently [TTSW10.ListBox2+0100], will be string buffer pointer
BASE:7FF87		mov eax, [ecx]	; [TTSW10.ListBox2+0100]
BASE:7FF89		nop
BASE:7FF8A		mov edx, 000000C9	; the 201-th text item, i.e., " Gold."
		; ...

		TTSW10.taisen2	endp


;============================================================
		; Rev10: Minimize keyboard delay when you move
		; TSW uses KeyDown message to receive arrow key inputs. The disadvantage of doing so is the consequent involvement of system keyboard repeat delay. Under default cases, if you keep holding an arrow key, you have to wait for 500 milliseconds before you can move to the next position (known as keyboard repeat delay), and afterwards, you will move at a rough rate of 30 moves per second (known as keybard repeat rate, equivalent to a 33-millisecond interval). These are the system settings, which will cause some problems if you adjust them simply for this game. A better design is to not rely on the system KeyDown message but rather to use a timer to check whether an arrow key is pressed at a given, constant interval (e.g., 100 milliseconds)
		; TTSW10.Timer3 is a handy, existent timer we can utilize. Originally, it was only enabled when you use OrbOfFlight and hold your mouse on the "Up" or "Down" button. So, when it's not in use, we can take advantage of it to serve as our arrow keystroke monitor. For Low, Middle, High, and SuperFast modes, the intervals will be set as 225, 150, 60, and 50 milliseconds respectively (interval2 below). However, the intervals for High and SuperFast are too short, which can easily lead to misoperation, so for the first key press event, the waiting interval will be set a bit larger, i.e., 125 milliseconds (interval1 below). When the arrow key is released, the Timer3 interval will set back to the original value, interval0, i.e., 275, 200, 125, and 125 milliseconds for each speed mode
BASE:60BD8	TTSW10.formkeydown	proc near	; processed TForm.KeyDown event
			push ebp
BASE:60BD9		mov ebp, esp	; prolog
BASE:60BDB		push ebx
BASE:60BDC		push esi
BASE:60BDD		push edi
BASE:60BDE		mov esi, ecx	; now word ptr [esi] is the pressed virtual key code
BASE:60BE0		mov ebx, eax	; TTSW10
		; original bytes:
;BASE:60BE2		cmp [BASE:8C5AC], 0	; remaining event count
;BASE:60BE9		jnl BASE:60BF2
;BASE:60BEB		xor eax,eax
;BASE:60BED		mov [BASE:8C5AC], eax	; if < 0, set as 0
;BASE:60BF2		mov eax, [ebx+0328]	; TTSW10.Option1: TMenuItem
;BASE:60BF8		cmp byte ptr [eax+29], 1	; TMenuItem.FEnabled: Boolean; this checks if the game is in the middle of an internal event and thus you are not allowed to do anything during this period
;BASE:60BFC		jne loc_formkeydown_end	; BASE:610A3
;BASE:60C02		cmp [BASE:8C5AC], 0	; this can be done earlier with saved space
;BASE:60C09		jne loc_formkeydown_end	; BASE:610A3
		; patched bytes:
BASE:60BE2		xor eax, eax	; eax = 0
BASE:60BE4		mov dl, [esi]	; virtual key code
BASE:60BE6		sub dl, 25
BASE:60BE9		cmp dl, 03	; if 0x25 <= dl <= 0x28 (Left, Up, Right, and Down, respectively)
BASE:60BEC		jbe BASE:60C0F	; for arrow keys, do not judge whether the event count is non-zero or whether the keyboard event is disabled; always turn on Timer3; leave the judgement there
BASE:60BEE		cmp [BASE:8C5AC], eax	; eax = 0
BASE:60BF4		jg loc_formkeydown_end	; BASE:610A3
BASE:60BFA		mov [BASE:8C5AC], eax	; eax = 0
BASE:60BFF		mov eax, [ebx+0328]	; TTSW10.Option1: TMenuItem
BASE:60C05		cmp byte ptr [eax+29], 1	; TMenuItem.FEnabled: Boolean; this checks if the game is in the middle of an internal event and thus you are not allowed to do anything during this period
BASE:60C09		jne loc_formkeydown_end	; BASE:610A3
BASE:60C0F	; ...

BASE:60C63	; Up key pressed ([esi]==0x26)
			mov eax, [ebx+03F8]	; TTSW10.Image22:TImage
BASE:60C69		cmp byte ptr [eax+37], 0	; checks if you are choosing an item
BASE:60C6D		jne BASE:60CB8	; if so, arrow keys are used to select an item to use
BASE:60C6F	; original bytes:
		; ...
		; briefly, these codes make "hero move left," which is more or less the same with TTSW10.BitBtn1Click, so we can reuse that subroutine to save space here
		; patched bytes:
			jmp loc_formkeydown_arrowkeydown	; BASE:60D78; see below

BASE:60C74	loc_interval1:
			db 78, 78, 96, E1	; 120, 120, 150, 225; the initial waiting interval when you press an arrow key for the first time (for SuperFast, High, Middle, Low speed modes, respectively, same below)
		; these values must be different from those for interval0; see comments in BASE:617D6
BASE:60C78	loc_interval2:
			db 00, 0A, 64, AF	; 0(+50), 10(+50), 100(+50), 175(+50); the key repeat interval, interval2, is this number + 50
BASE:60C7C	loc_interval0:
			db 4B, 4B, 96, E1	; 75(+50), 75(+50), 150(+50), 225(+50), the original Timer3.Interval, interval0, is this number + 50, which will be restored after the arrow key is released. Because 275 > 255 (the maximum value for UCHAR), so I have to decrease each value by 50 to store them and will add 50 back later
BASE:60C80	loc_BitBtnXClick_addr:
			dd 484BB0, 484B5C, 484C04, 484C58	; these are addresses for TTSW10.BitBtn2/1/3/4Click for moving left/up/right/down respectively

BASE:60C90	loc_timer2on_judge:
		; Originally, in TTSW10.timer2on, when Timer2 is enabled, Timer3 would always be disabled; now we need to judge whether Timer3 is used by us for arrow keystroke monitoring; if so, no need to stop Timer3. See comments in TTSW10.timer2on
			cmp byte ptr [BASE:8C5C7], 25	; this byte is used to store the last pressed key's virtual key code; see comments below in TTSW10.timer3ontimer
BASE:60C97		jae BASE:60C9E	; if is >= 0x25, meaning that Timer3 is used by us for arrow keystroke monitoring, then do nothing
BASE:60C99		call TTimer.SetEnabled	; otherwise, disable Timer3 (eax=TTSW10.Timer3; edx=0; see TTSW10.timer2on)
BASE:60C9E		ret
		; ...

BASE:60D6C	; Left key pressed ([esi]==0x25)
		; ...
		; similar to above
BASE:60D78	; ...
		; similar to above
		; patched bytes:
		loc_formkeydown_arrowkeydown:	; this is common subroutine for all 4 arrow keydown events
			movzx ecx, byte ptr [esi]	; which arrow key is pressed (0x25-0x28)
BASE:60D7B		mov eax, [ebx+030C]	; TTSW10.Timer3
BASE:60D81		mov edx, offset BASE:8C5C7	; this byte is used to store the last pressed key's virtual key code; see comments below in TTSW10.timer3ontimer
BASE:60D86		cmp [edx], cl
BASE:60D88		mov [edx], cl
BASE:60D8A		pushfd	; store all flags register
BASE:60D8B		je BASE:60D9C	; if the last pressed key is the same as the current pressed key, then no need to change Timer3.Interval, just enable Timer3 (if Timer3 is already enabled, this will be a no-op). Forcing enabling Timer3 might be unnecessary here, but just to make sure

BASE:60D8D		mov cl, [BASE:89B9F]	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:60D93		mov cl, [ecx+loc_interval1]	; if this key is not pressed before, set the interval to be a bit larger to avoid misoperation (see discussions at the beginning). Because all high bytes of ecx have been set 0 earlier, so ecx=cl
BASE:60D99		mov [eax+24], ecx	; TTimer.Interval; Calling TTimer.SetEnabled will also update the interval if the enabled state of the timer changes. See TTimer.SetEnabled and TTimer.UpdateTimer
		; an attempt that got eventually abandoned here:
		; Currently, if you press a different arrow key, there will not be a delay involved, i.e., the Timer3 interval will remain `interval2` without changing to `interval1` in the middle. This is because Timer3.Enabled state doesn't change, so the interval change won't be updated. However, I think this is a good design
		; If we must add an additional delay here, we can add the following line to force timer interval update:
;			mov byte ptr [eax+20], 0	; this line itself won't stop the timer. But since `dl=1` below != byte ptr [eax+20], TTimer.UpdateTimer will always be called. See TTimer.SetEnabled and TTimer.UpdateTimer

BASE:60D9C		mov dl, 01
BASE:60D9E		call TTimer.SetEnabled	; enable Timer3 (and update its interval when needed)
BASE:60DA3		popfd	; retrieve all flags register (because they might have changed during the previous `call`)
BASE:60DA4		je BASE:60DAE	; if the last pressed key is the same as the current pressed key, then no need to do the following (because it's already taken care of in Timer3)

BASE:60DA6		movzx ecx, byte ptr [esi]	; otherwise, move immediately (do not wait for a timer interval to do that)
BASE:60DA9		call loc_move	; BASE:617F8; see below

BASE:60DAE		jmp loc_formkeydown_end	; BASE:610A3
BASE:60DB3		nop
BASE:60DB4		; ...

BASE:60E18	; Right key pressed ([esi]==0x27)
		; ...
		; similar to above
BASE:60E24	; ...
		; similar to above
		; patched bytes:
			jmp loc_formkeydown_arrowkeydown
		; ...

BASE:60E18	; Down key pressed ([esi]==0x28)
		; ...
		; similar to above
BASE:60E24	; ...
		; similar to above
		; patched bytes:
			jmp loc_formkeydown_arrowkeydown
		; ...

		TTSW10.formkeydown	endp


BASE:61760	TTSW10.timer3ontimer	proc near	; processed Timer3.OnTimer event
			push ebx
BASE:61761		mov ebx, eax	; prolog
		; original bytes:
;BASE:61763		mov ax, [BASE:8C5C6]	; this word is either 0 or 1, determining whether Timer3 should be subsequently disabled. Because its high byte was never used, so I will use [BASE:8C5C7] to store the virtual key code of the last pressed key
;BASE:61769		sub ax, 01
;BASE:6176D		jb BASE:61776	; ==0
;BASE:6176F		je BASE:61785	; ==1
;BASE:61771		jmp loc_timer3ontimer_end	; BASE:618F8; this case is not possible

;BASE:61776		xor edx, edx	; disable
;BASE:61778		mov eax, [ebx+030C]	; TTimer3
;BASE:6177E		call TTimer.SetEnabled
;BASE:61783		pop ebx
;BASE:61784		ret
		; patched bytes:
BASE:61763		xor edx, edx	; edx = 0 <- TTimer.Enabled (False)
BASE:61765		xor eax, eax	; clear all bytes
BASE:61767		mov al, [BASE:8C5C7]	; eax = pressed key's virtual key code
BASE:6176C		cmp al, 25
BASE:6176E		jae loc_timer3ontimer_task1	; BASE:617B6; if >= 0x25, meaning that Timer3 is used by us for arrow keystroke monitoring, then no need to care about the original treatment
BASE:61770		cmp [BASE:8C5C6], dl	; edx = 0
BASE:61776		jne BASE:61785
BASE:61778		mov eax, [ebx+030C]	; TTimer3
BASE:6177E		call BASE:2C454	; disable TTimer3
BASE:61783		pop ebx
BASE:61784		ret

		; ----------
BASE:61785		mov eax, [BASE:8C590]	; task index: 1-4 would have been moving up/left/right/down respectively but was never implemented (so it's safe for us to insert our new codes there); 5-6 = Go Up/Down stairs in OrbOfFlight
BASE:6178A		cmp eax, 06
BASE:6178D		ja loc_timer3ontimer_end	; BASE:618F8; this case is not possible
BASE:61793		jmp [eax*4+BASE:6179A]	; switch jump

BASE:6179A	; original bytes:
;			dd loc_timer3ontimer_end, loc_timer3ontimer_task1, loc_timer3ontimer_task2, loc_timer3ontimer_task3, loc_timer3ontimer_task4, loc_timer3ontimer_task5, loc_timer3ontimer_task6
		; patched bytes:
			dd loc_timer3ontimer_end, loc_timer3ontimer_end, loc_timer3ontimer_end, loc_timer3ontimer_end, loc_timer3ontimer_end, loc_timer3ontimer_task5, loc_timer3ontimer_task6	; do nothing for tasks 1-4 just to be safe

BASE:617B6	loc_timer3ontimer_task1:
		; original bytes:
		; ...
		; would have been moving up but was never implemented (so it's safe for us to insert our new codes (for processing arrow keystrokes) here)
		; patched bytes:
BASE:617B6		push eax	; store eax=pressed key's virtual key code
BASE:617B7		push eax	; vKey
BASE:617B8		call User32.GetKeyState	; BASE:04FCC
BASE:617BD		xor edx, edx	; edx = 0 <- TTimer.Enabled (False); clear all bytes
BASE:617BF		test ax, ax	; high bit is 1 if specified key pressed
BASE:617C2		mov eax, [ebx+030C]	; timer3
BASE:617C8		mov ecx, offset loc_interval2
BASE:617CD		pushfd	; store all flags register
BASE:617CE		js BASE:617DC

BASE:617D0		mov [BASE:8C5C7], dl	; reset last pressed key; edx=0
BASE:617D6		mov [eax+20], dl	; TTimer.Enabled; Calling TTimer.SetInterval will also update the enabled state if the timer interval changes. See TTimer.SetInterval and TTimer.UpdateTimer
BASE:617D9		lea ecx, [ecx+4]	; ecx=loc_interval0

BASE:617DC		mov dl, [BASE:89B9F]	; this stores the speed mode: 0=SuperFast; 1=High; 2=Middle; 3=Low
BASE:617E2		mov dl, [ecx+edx]	; if key pressed before, set the interval to be interval2 (see discussions at the beginning); if key released, set the Timer3 interval back to original value, interval0. Because all high bytes of edx have been set 0 earlier, so edx=dl
BASE:617E5		add edx, 32	; +50; see discusions in BASE:60C7C
		; an attempt that got eventually abandoned here:
		; Currently, there will be a delay when you first press an arrow key, where Timer3.Interval is `interval1`, and afterwards, Timer3.Interval will always be a shorter constant `interval2`. I previously thought that to make a smoother transition, it might be better if there could be a graduate (instead of abrupt) change of Timer3.Interval. The interval will halve every time, but no less than `interval2` (so it will eventually plateau). To take the SuperFast mode as an example, the interval can be 200, then 100, and then 50. However, it seems that the longer interval will make the game moving animation appear less smooth (because the refreshing rate will be lower), so actually we may want to keep the delay as short as possible, and having a "gradient" interval change will actually be worse.
		; If must add a "gradient" interval change, the line above should be changed and a few more lines need to be added:
;			lea edx, [edx+32]	; this is similar to `add edx, 32` but without affecting the flags register
;			jns +0B
;			mov ecx, [eax+24]	; Timer3.Interval
;			shr ecx, 1	; divided by 2
;			cmp edx, ecx	; see which one is larger and use the larger value
;			jae +2
;			mov edx, ecx

BASE:617E8		call TTimer.SetInterval	; change Timer3 interval (and update its enabled state when needed); if the interval is not changed (e.g., Timer3.Interval is already interval2), this will be a no-op
BASE:617ED		popfd	; retrieve all flags register (because they might have changed during the previous `call`)
BASE:617EE		pop ecx	; retrieve ecx = pressed key's virtual key code
BASE:617EF		jns BASE:617F6	; high bit not set, meaning key released, then don't call loc_move

BASE:617F1		call loc_move	; BASE:617F8

BASE:617F6		pop ebx
BASE:617F7		ret

BASE:617F8	loc_move:	; input: ecx: virtual key code (0x25-0x28: Left/Up/Right/Down); ebx: TTSW10 handle
			sub cl, 25
BASE:617FB		mov edx, [ebx+0328]	; TTSW10.option1: TMenuItem
BASE:61801		cmp byte ptr [edx+29], 1	; TMenuItem.FEnabled; need to judge here whether the game window is disabled for input now (was implemented in TTSW10.formkeydown originally, now moved to here)
		; but no need to judge whether event count is non-zero, as this will be done in TTSW10.BitBtnXClick later
BASE:61805		jne BASE:617F7	; ret (if window is disabled)
BASE:61807		mov eax, ebx
BASE:61809		jmp [ecx*4+loc_BitBtnXClick_addr]	; TTSW10.BitBtnXClick
		; ...

		TTSW10.timer3ontimer	endp

;============================================================
		; Rev11: Place TSW game window to a better location on the screen
		; TSW, upon startup or changing game window size, will put its window on the top left corner of the whole screen, which is a) a weird position and b) will overlap with the taskbar if it is located at the left or top side of the screen (though this is not an issue in Windows 11 because taskbar can only be at the bottom of the screen)
		; Currently, I changed the code such that 1) on startup, the game window will be in the primary screen center, excluding the taskbar area; 2) on game window size change, the window will grow / shrink from its original center; 3) however, if the window exceed the primary screen working area (i.e., excluding the taskbar area), then it will reposition itself such that its edge do not go beyond the screen working area edge
BASE:84F48	TTSW10.syokidata0	proc near	; (rōmaji of '初期data0') initialization of GUI
		; ... (for the part before BASE:84FFA, one can refer to Entry 5 of `tswMod.asm`)
		; original bytes:
;BASE:84FF0	; this part through BASE:850EF is about setting the position and size of the game window, but the code is too lengthy and redundant. Therefore, I will show the pseudocode instead here:
;		TControl.SetTop(TTSW10, 0);
;		if (byte_ptr_BASE_89BA4 < 1) { // TSW size setting: 0=640x400; 1=800x500
;			if (TScreen.GetWidth() > 640) { // this judgement is not useful
;				TControl.SetLeft(TTSW10, 0);
;				TForm.SetClientHeight(TTSW10, 424); // this contains 4 pixel margin
;				TControl.SetWidth(TTSW10, 648); // this contains 4 pixel margin and 4 pixel border
;			} else {
;				TControl.SetLeft(TTSW10, -4); // -4 might be used to account for the margin, but should be -2 (2 pixel on the left side and 2 pixel on the right side)
;				TForm.SetClientHeight(TTSW10, 424); // this contains 4 pixel margin
;				TControl.SetWidth(TTSW10, 648); // this contains 4 pixel margin and 4 pixel border
;			}
;		} else if (byte_ptr_BASE_89BA4 == 1) { // TSW size setting: 0=640x400; 1=800x500
;			if (TScreen.GetWidth() > 640) { // this judgement is not useful
;				TControl.SetLeft(TTSW10, 0);
;				TForm.SetClientHeight(TTSW10, 530); // this contains 4 (6?) pixel margin
;				TControl.SetWidth(TTSW10, 808); // this contains 4 pixel margin and 4 pixel border
;			} else {
;				TControl.SetLeft(TTSW10, -3); // -3 might be used to account for the margin, but should be -2 (2 pixel on the left side and 2 pixel on the right side)
;				TForm.SetClientHeight(TTSW10, 530); // this contains 4 (6?) pixel margin
;				TControl.SetWidth(TTSW10, 808); // this contains 4 pixel margin and 4 pixel border
;			}
;		}
;BASE:850EF	; ...

		; patched bytes:
		; these are the parameters for TForm.GetClientRect (eax=TForm; edx=&DWORD[4])
BASE:84FFA		lea edx, [ebp-14]	; use the 16 bytes pre-allocated by the syokidata0 subroutine (between ebp-14 ... ebp-04) as buffer for getting TSW window client area's [c_L, c_T, c_W, c_H] (C_L and C_T are always 0)
		; ebp-14:=_DWORD[0]
		; ebp-10:=_DWORD[1]
		; ebp-0C:=_DWORD[2]
		; ebp-08:=_DWORD[3]
BASE:84FFD		mov eax, ebx	; TTSW10

; we will first push the parameters for User32.SystemParametersInfoA to stack first
BASE:84FFF		push 0	; fWinIni = FALSE
BASE:85001		push edx	; pvParam = the 16 bytes between esp_old-16 .. esp_old as buffer for getting the primary screen's working area RECT [s_L, s_T, s_R, s_B] (excluding the taskbar)
BASE:85002		push 0	; uiParam
BASE:85004		push 30	; uiAction=SPI_GETWORKAREA

BASE:85006		call TForm.GetClientRect	; BASE:21370

; calculate the new TSW window size (width and height): esi:=n_W; edi:=n_H
BASE:8500B		mov esi, 0288	; 648
BASE:85010		mov edi, 01A8	; 424
BASE:85015		cmp byte ptr [BASE:89BA4], 0	; TSW size setting: 0=640x400; 1=800x500
BASE:8501C		je BASE:85026
BASE:8501E		mov si, 0328	; 808
BASE:85022		mov di, 0212	; 530

BASE:85026		add edi, [ebx+30]	; += old TSW window height (w_H)
BASE:85029		sub edi, [ebp-08]	; -= old TSW client height (c_H)

BASE:8502C		call BASE:0522C	; user32.SystemParametersInfoA
		; Known issue: this will only get information for the primary monitor; a better solution is to use MonitorFromWindow + GetMonitorInfo

		; calculate the new TSW window center position: edx:=2*c_X; ecx:=2*c_Y
BASE:85031		cmp byte ptr [ebx+5C], 0	; used to judge whether this subroutine is executed at the first time (this byte will +1/2/4/8 if TControl.SetLeft/Top/Width/Height has been called); if so, place the window in the screen center; otherwise, preserve the TSW window center
BASE:85035		je loc_first_time_reposition

BASE:85037		mov edx, [ebx+24]	; old TSW window left (w_L)
BASE:8503A		sal edx, 1
BASE:8503C		add edx, [ebx+2C]	; old TSW window width (w_W)
BASE:8503F		mov ecx, [ebx+28]	; old TSW window top (w_T)
BASE:85042		sal ecx, 1
BASE:85044		add ecx, [ebx+30]	; old TSW window height (w_H)
BASE:85047		jmp loc_first_time_reposition_end
BASE:85049	loc_first_time_reposition:
			mov edx, [ebp-14]	; screen working area: left (s_L)
BASE:8504C		add edx, [ebp-0C]	; screen working area: right (s_R)
BASE:8504F		mov ecx, [ebp-10]	; screen working area: top (s_T)
BASE:85052		add ecx, [ebp-08]	; screen working area: bottom (s_B)
BASE:85055	loc_first_time_reposition_end:
		; calculate the new TSW window left top: edx:=n_L; ecx:=n_T
			sub edx, esi
BASE:85057		sar edx, 1
BASE:85059		sub ecx, edi
BASE:8505B		sar ecx, 1

		; judge whether the resultant new corners exceed the screen working area edges, if so, place the new corner at the edge (check the bottom right first, and then the top left (higher priority to fulfill))
BASE:8505D		mov eax, [ebp-0C]	; screen working area: right (s_R)
BASE:85060		sub eax, esi	; new TSW window width (n_W)
BASE:85062		inc eax
BASE:85063		inc eax	; 2 pixel margin
BASE:85064		cmp eax, edx	; n_L should not exceed eax:= s_R-n_W+2
BASE:85066		cmovl edx, eax

BASE:85069		mov eax, [ebp-08]	; screen working area: bottom (s_B)
BASE:8506C		sub eax, edi	; new TSW window height (n_H)
BASE:8506E		inc eax
BASE:8506F		inc eax	; 2 pixel margin
BASE:85070		cmp eax, ecx	; n_T should not exceed eax:= s_B-n_H
BASE:85072		cmovl ecx, eax

BASE:85075		mov eax, [ebp-14]	; screen working area: left (s_L)
BASE:85078		dec eax
BASE:85079		dec eax	; 2 pixel margin
BASE:8507A		cmp edx, eax	; n_L should not be less than eax:= s_L-2
BASE:8507C		cmovl edx,eax

BASE:8507F		mov eax, [ebp-10]	; screen working area: top (s_T)
BASE:85082		cmp ecx, eax	; n_T should not be less than eax:= s_T
BASE:85084		cmovl ecx, eax

BASE:85087		push esi	; width
BASE:85088		push edi	; height
BASE:85089		mov eax, ebx	; TTSW10
		; edx = left; ecx = top
BASE:8508B		call TWinControl.SetBounds	; BASE:167AC
BASE:85090		or byte ptr [ebx+5C], 7	; see comment in BASE:85031; used to indicate that TControl.SetLeft/Top/Width has already be called
		; oddly enough, TForm.SetClientHeight will not set `[ebx+5C] |= 8`, so the value here is 7 not 15
BASE:85094		jmp BASE:850EF	; end
		; ...

		TTSW10.syokidata0	endp
