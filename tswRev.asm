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
BASE:42613	;dd offset BASE:7F464	; original bytes
		dd offset BASE:7F47C	; patched bytes
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
		; original code
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
		; original bytes
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
		; patched bytes
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
		; original bytes
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
;BASE:7F53A		mov byte ptr [BASE:89B9F], 1	; this stores the speed mode: 1=High; 2=Middle; 3=Low
;BASE:7F541		pop ebx
;BASE:7F542		ret
;BASE:7F543		nop	; align 04
;		TTSW10.speedmiddle	endp
		; patched bytes
BASE:7F4E3		push 2	; push arg0 (speed mode = 2 = Middle) to stack
BASE:7F4E5		jmp loc_set_speed
BASE:7F4E7		nop	; align 04
		TTSW10.speedmiddle	endp

BASE:7F4E8	loc_set_speed_next:
			cmp [esp], 1	; [esp] is arg0 (speed mode) on stack
BASE:7F4EC		sete dl	; check/uncheck
BASE:7F4EF		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
BASE:7F4F5		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F4FA		pop eax
BASE:7F4FB		test al, al	; 0=SuperFast
BASE:7F4FD		sete dl	; check/uncheck
BASE:7F500		mov eax, [ebx+0358]	; TTSW10.N7: TMenuItem
BASE:7F506		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F50B		xor edx, edx	; uncheck
BASE:7F50D		mov eax, [ebx+03B0]	; TTSW10.Low1: TMenuItem
BASE:7F513		call TMenuItem.SetChecked	; BASE:102F0
BASE:7F518		pop ebx
BASE:7F519		ret
		; ...


BASE:7D324	TTSW10.OptionSave1Click	proc near	; save speed mode and other settings
		; ...
		; original bytes
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
		; patched bytes
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
		; original bytes
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
		; patched bytes
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


;============================================================
		; Rev2: Fix prolog bug
BASE:4280C	TTSW10.formactivate	proc near	; <= TTSW10.OnActivate
		; this will be called when the main form is initialized and shown
		; ...
		; original bytes
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
