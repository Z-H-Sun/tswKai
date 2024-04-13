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
;BASE:7F53A		mov byte ptr [BASE:89B9F], 2	; this stores the speed mode: 1=High; 2=Middle; 3=Low
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
		; original bytes
;BASE:7F5A5		pop ebx
;BASE:7F5A6		ret
		; patched bytes
BASE:7F5A5		jmp loc_set_speedsup_unchecked
		TTSW10.Low1Click	endp
BASE:7F5A7	align 04


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

		; In addition to the Timer2.Interval settings above (recall that Timer2 controls game event processing), sometimes its interval will be separately changed in certain events like door opening (see TTSW10.dooropen at BASE:7717A as an example) / scrolling caption / stair animation / etc.
		; However, the change will only happen when the High / Middle / Low speed menu itme is ticked; therefore, in cases where SuperHigh speed mode is selected, these interval-changing codes will not be executed, and Timer2.Interval will remain to be 10 msec, the shortest possible interval. So nothing is required to be done in these scenarios.


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
		; original bytes
;BASE:4C0D6		mov eax, [ebx+03A8]	; TTSW10.High1: TMenuItem
;BASE:4C0DC		cmp byte ptr [eax+28], 1	; TMenuItem.FChecked
		; ... (briefly: for high-speed mode, esi /= 4; for middle-speed mode, esi /= 2)
;BASE:4C0FF		mov ebp, esi	; ebp = esi = width or width/2 or width/4
;BASE:4C101		test ebp, ebp
;BASE:4C103		jle loc_idou_loop_end
		; patched bytes
BASE:4C0D6		shr esi, 2	; esi = width/4 (everytime, draw hero at this offset)
BASE:4C0D9		mov ebp, 4	; ebp = 4 (draw 4 frames in total)
BASE:4C0DE		jmp BASE:4C109	; ebp = 4 (draw 4 frames in total)
BASE:4C0E0	; ...
		; ----------
BASE:4C109		mov edi, 1	; edi = 1, 2, ..., ebp
BASE:4C10E	loc_idou_loop_begin:
			mov [BASE:8C56C], edi
		; original bytes
;BASE:4C114		mov [BASE:8C55C], edi	; distance w.r.t original position
		; ... (briefly, test if esi is width/2 or width/4, and if so, multiply [BASE:8C55C] with 2 or 4)
		; patched bytes
BASE:4C114		mov eax, edi	; eax = 1, 2, 3, or 4
BASE:4C116		mul esi	; eax *= width/4
BASE:4C118		mov [BASE:8C55C], eax	; distance w.r.t original position
BASE:4C11D		push offset BASE:4C15E	; will call loc_idou_sleep next; then should goto this address after `ret`
BASE:4C122		xchg ax, ax	; 2-byte nop

BASE:4C124	loc_idou_sleep:
			mov eax, [ebx+02EC]	; TTSW10.Timer2: TTimer
BASE:4C12A		mov eax, [eax+24]	; TTimer.Interval
BASE:4C12D		shr eax, 3	; /=8 (floor)
BASE:4C130		dec eax	; -=1
BASE:4C131		push eax	; dwMilliseconds: SuperFast: 0 ms; Fast: 5 ms; Middle: 11 ms; Low: 17 ms
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
		; original bytes
;BASE:803E6		test ebp, ebp
;BASE:803E8		jle loc_monidou_loop_end
;BASE:803EE		mov [esp], 1	; [esp] = 1, 2, ..., width
;BASE:803F5	loc_monidou_loop_begin:
		; patched bytes
BASE:803E6		shr ebp, 2	; distance w.r.t original position = width/4
BASE:803E9		mov [esp], ebp	; [esp] = width/4 (then width/2, 3width/4, width)
BASE:803EC		nop [eax+0]	; 3-byte nop
BASE:803F0	loc_monidou_loop_begin_new:
			call loc_idou_sleep
		; ----------

BASE:803F5		mov eax, [esp]
			; ...

		; original bytes
;BASE:807B2		inc [esp]
;BASE:807B5		dec ebp
;BASE:807B6		jne loc_monidou_loop_begin
;BASE:807BC	loc_monidou_loop_end:
;			mov eax, [ebx+0254]	; TTSW10.Image6: TImage (icon for OrbOfHero)
;BASE:807C2		mov eax, [eax+2C]	; TImage.Width (32 or 40)
		; patched bytes
BASE:807B2		add [esp], ebp	; [esp] = width/2 (then 3width/4, width, 5width/4)
BASE:807B5		mov eax, ebp
BASE:807B7		shr eax, 2	; eax = width
BASE:807BA		cmp [esp], eax
BASE:807BD		jbe loc_monidou_loop_begin_new
BASE:807C3		xchg ax, ax	; 2-byte nop
BASE:807C5	; ...
		TTSW10.monidou	endp
