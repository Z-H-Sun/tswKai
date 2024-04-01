BASE:00000	; Pre-defined functions in TSW.exe

BASE:00000	TSW_TTSW10_handle	:= dword ptr BASE:08C510
		TSW_tedit8_msg_id	:= dword ptr BASE:08C58C
		TSW_filename_addr	:= dword ptr BASE:08C5D4
		TSW_file_handle	:= dword ptr BASE:08C600
		TSW_item_id	:= dword ptr BASE:08C574
		TSW_gold_price	:= dword ptr BASE:08C594
		TSW_hero_status	:= dword ptr BASE:0B8688
		; dword array[12]
		; [4] -> floor; [6] -> x_pos; [7] -> y_pos; [8] -> yellow_key; [9] -> red_key; [A] -> blue_key
		TSW_hero_face	:= dword ptr BASE:0B87E8	; facing which direction; 1=down; 2=left; 3=right; 4=up
		TSW_datacheck1	:= dword ptr BASE:0B8918	; validates the data integrity; sum of all variables
		TSW_datacheck2	:= dword ptr BASE:0B891C	; validates the data integrity; sum of all odd-numbered variables minus all even-numbered variables
		TSW_map_data	:= dword ptr BASE:0B8934

BASE:01228	CloseHandle	proc near	; kernel32
BASE:01228	CloseHandle	endp

BASE:01230	CreateFileA	proc near	; kernel32
BASE:01230	CreateFileA	endp

BASE:01270	ReadFile	proc near	; kernel32
BASE:01270	ReadFile	endp

BASE:01290	WriteFile	proc near	; kernel32
BASE:01290	WriteFile	endp

BASE:012A8	GetLastError	proc near	; kernel32
BASE:012A8	GetLastError	endp

BASE:04B84	GetProcAddress	proc near	; kernel32
BASE:04B84	GetProcAddress	endp

BASE:04BFC	LoadLibraryA	proc near	; kernel32
BASE:04BFC	LoadLibraryA	endp

BASE:05184	SendMessageA	proc near	; user32
BASE:05184	SendMessageA	endp

BASE:051FC	SetWindowTextA	proc near	; user32
BASE:051FC	SetWindowTextA	endp

BASE:03140	system.@HandleFinally	proc near
		; ...
BASE:03175	system.@HandleFinally	endp

BASE:50880	TTSW10.itemlive	proc near
		; ...
BASE:50B75	TTSW10.itemlive	endp

		; patch to allow loading data during an event

BASE:50758	TTSW10.itemdel	proc near	; disable menu items and buttons etc. during an event
		; ...
		; original bytes:
;BASE:5084D		xor edx, edx	; disable menu item

		; patched bytes:
BASE:5084D		jmp loc_disable_save_menu

BASE:5084F		mov eax, [ebx+334]	;TTSW10.GameLoad1 (TMenuItem)
BASE:5084F		call BASE:10378	; TMenuItem.SetEnabled

BASE:5084F	loc_disable_save_menu:
		; ...

BASE:50875	TTSW10.itemdel	endp

		; formkeydown will be patched to allow tswSL hotkeys within TSW

BASE:60BD8	TTSW10.formkeydown	proc near	; TSW10.OnKeyDown
		; original bytes:
;			push ebp
;BASE:60BD9		mov ebp, esp	; this is redundant, not used in this subroutine
;BASE:60BDB		push ebx
;BASE:60BDC		push esi
;BASE:60BDD		push edi
;BASE:60BDE		mov esi, ecx	; these assignments will be moved into `sub_checkHotkey`
;BASE:60BE0		mov ebx, eax
		; ...

		; patched bytes:
BASE:60BD8		call sub_checkHotkey
BASE:60BDD		push ebp
BASE:60BDE		push ebx
BASE:60BDF		push esi
BASE:60BE0		push edi
BASE:60BE1		nop

BASE:610C0	TTSW10.formkeydown	endp

		; loadwork and savework subroutines will be patched to be compatible with the load temp and save temp functions

BASE:7E614	TTSW10.Load81Click	proc near	; this is called when you click the Load -> Data 8 menu
		; this will be used for loading temp data or arbitrary data file
		; `loadwork` alone is not enough, because it does not include some important pre- and post-processing. For example, save0.dat should be saved beforehand in case the data to load is a bad one; afterwards, `itemlive` should be called to re-enable buttons and menu items in case you were in the middle of a dialog, and TTimer1 should be re-enabled in case you are going up-/downstairs
		; "Load Data 1" was reserved by the legacy version of tswSL, so for compatibility and to avoid conflicts, we choose to work on "Load Data 8" in this 
		; ...
BASE:7E6C8		mov eax, TSW_file_handle	; to this point, the temporary save0.dat has been saved
BASE:7E6CD		call BASE:042B8	; system.@Close
BASE:7E6D2		call BASE:02710	; system.@_IOTest
BASE:7E6D7		lea ecx, [ebp-04]	; arg1, reserved for the pointer of savedat path
BASE:7E6DA		mov eax, [ebx+0444]	; TMemo12, which stores the savedat path
		; original bytes:
;BASE:7E6E0		mov eax, [eax+0118]	; TMemo.FAlignment.TAlignment
;BASE:7E6E6		xor edx, edx	; line number?
;BASE:7E6E8		mov esi, [eax]
;BASE:7E6EA		call [esi+0C]	; TMemo.TMemoStrings.Get (This likely only gets the first line (i.e. the savedat path)? Because the second line of TMemo12 is the installation folder of TSW)
;BASE:7E6ED		mov edx, [ebp-04]
;BASE:7E6F0		mov eax, offset TSW_filename_addr
;BASE:7E6F5		mov ecx, offset BASE:7E7C8	; string "\save8.dat"
;BASE:7E6FA		call @LStrCat3	; after this, [TSW_filename_addr] will be the pointer to the absolute path to save8.dat
		; ...

		; patched bytes:
		; actually the lines at BASE:7E6D7 and BASE:7E6DA are not necessary and can be removed. I kept them simply due to my "minimal perturbation" philosophy
BASE:7E6E0		mov eax, offset TSW_filename_addr
BASE:7E6E5		cmp eax, [filename_pointer_addr]	; check if you are loading data 8 (original function) or tempdata/arbitrary data (tswSL)
BASE:7E6EB		jne BASE:7E767	; for tempdata/arbitrary data, no need to set filename (already taken care of in `sub_load*`) or menu item check states
BASE:7E6ED		mov edi, [eax]	; string move destination
BASE:7E6EF		mov esi, BASE:7E7C8	; string "\save8.dat"; string move source
BASE:7E6F4		add edi, [edi-04]	; [edi-04]=length of the filename string; move to the end of string
BASE:7E6F7		mov ecx, [esi-04]	; [esi-04]=length of the basename string "\save8.dat"
BASE:7E6FA		sub edi, ecx	; move to the actual position for string replacement
BASE:7E6FC		inc ecx	; add 1 byte to the length to include the trailing "\0"
BASE:7E6FD		repe movsb	; to this point, the construction of the absolute filename of save8.dat is completed using simpler and shorter commands than the original version
		; ...
BASE:7E7AA	TTSW10.Load81Click	endp

BASE:7E7D4	TTSW10.loadwork	proc near
		; ...
		; `TSW_filename_addr` is a pointer to a temporary string instance that was generated by e.g. `system.@LStrCat3`
		; Directly assigning a new pointer to `TSW_filename_addr` can mess things up if Delphi's intrinsic string functions (e.g. `@LStrCat3`) are called. This is not an issue in `savework` as no such string functions are called, but in `loadwork`, we need to come up with a different workaround
		; since Delphi has memory written protection, we cannot change the opcodes in TSW at runtime, so we need a "pointer of pointer," which in normal cases points to TSW_filename_addr, but when we want to load an arbitrary data, then it will point to a pointer of `dat_filename` or `tmp_filename`
		; note: we need a pointer of pointer, not a pointer, so in the latter case, `filename_pointer_addr` will point to a pointer which points to the string, then we still need an intermediate pointer
		; now `TSW_datacheck1` becomes handy, because it will be immediately assigned later by the game process, so we just use it as a temp var here
		; to sum up, `filename_pointer_addr` will point to `TSW_filename_addr` in normal cases, but will point to `TSW_datacheck1` when we want to load an arbitrary data, and in the latter case, we will temporarily assign `TSW_datacheck1` as the pointer to the filename string (see `sub_loadtemp`)

		; original bytes:
;BASE:7E810		mov edx, [TSW_filename_addr]	; AnsiString
;BASE:7E816		mov eax, offset TSW_file_handle	; TFileRec
;BASE:7E81B		call BASE:0414D	; system.@Assign
;BASE:7E820		xor edi, edi
;BASE:7E822		push ebp
;BASE:7E823		push BASE:7EA42	; location to jump if failed
;BASE:7E828		push fs:[edi]
;BASE:7E82B		mov fs:[edi], esp
;BASE:7E82E		mov edx, 1
;BASE:7E833		mov eax, offset TSW_file_handle
		; ...

		; patched bytes (* means changed lines):
BASE:7E810		mov eax, [filename_pointer_addr]	;* pointer of pointer
BASE:7E815		mov edx, [eax]	;* pointer to string
BASE:7E817		mov eax, offset TSW_file_handle
BASE:7E81C		push eax	;* to save space, push `eax=TSW_file_handle` to stack and pop later (2 bytes vs 5 bytes)
BASE:7E81D		call BASE:0414D
BASE:7E822		pop eax	;* must pop here to balance the stack
BASE:7E823		xor edi, edi
		; ... the remainder opcodes are the same as the original ones
		; no need to `mov eax, offset TSW_file_handle` later

		; these lines will be executed if the data is loaded successfully
		; if so, we need to reset `last_coordinate`, so that even if you stay at the save location after loading a new game, still always save the first temp data (because it's like you are starting a new game, the last status from the previous game should not be considered)
		; original bytes:
;BASE:7E8C0		cmp edx, A4	; loop, load 0xA4 dword variables from the data
;BASE:7E8C6		jne BASE:7E89F	; loop not ended
;BASE:7E8C8		cmp esi, [BASE:B8918]
;BASE:7E8CE		jne BASE:7E8F7	; the data is corrupted; 'Do not use this data'
;BASE:7E8D0		cmp ecx, [BASE:B891C]
;BASE:7E8D6		jne BASE:7E8F7	; likewise
;BASE:7E8D8		mov eax, [ebp-04]	; TTSW10
;BASE:7E8DB		call BASE:54DE8	; TTSW10.syokidata2
;BASE:7E8E0		mov [TSW_tedit8_msg_id], 85	; 'Loaded the Game'
;BASE:7E8EA		mov eax, [ebp-04]
;BASE:7E8ED		call BASE:4CB34	; TTSW10.disp
;BASE:7E8F2		jmp BASE:7EA38

		; patched bytes (* means changed lines):
BASE:7E8C0		cmp dl, A4	;* this can save 3 bytes
BASE:7E8C3		jne BASE:7E89F
BASE:7E8C5		cmp esi, [BASE:B8918]
BASE:7E8CB		jne BASE:7E8F7
BASE:7E8CD		cmp ecx, [BASE:B891C]
BASE:7E8D3		jne BASE:7E8F7
BASE:7E8D5		mov eax, [ebp-04]
BASE:7E8D8		push eax	;* to save space, push `eax=TSW_TTSW10_handle` to stack and pop later (2 bytes vs 3 bytes)
BASE:7E8D9		call BASE:54DE8
BASE:7E8DE		mov byte ptr [BASE:8C58C], 85	;* this can save 3 bytes
BASE:7E8E5		pop eax	;*
BASE:7E8E6		call BASE:4CB34
BASE:7E8EB		mov byte ptr [last_coordinate], FF	;* initialize (inserted 7 bytes)
BASE:7E8F2		jmp BASE:7EA38
		; ...

BASE:7EAA0	TTSW10.loadwork	endp

BASE:7EADC	TTSW10.savework	proc near
		; ...
		; these lines will be executed if the filename already exists, so you are at a risk of overwriting
		; normally, a msgdlg will pop up, but this can be annoying when saving a temp data
		; so we will add a judgement: if `save_overwrite_dialog_style` is 0, then do not show the msgdlg and directly overwrite the existing temp data; otherwise, show the msgdlg as normal (see `sub_savetemp`)
BASE:7EB51		mov eax, offset TSW_file_handle	; TFileRec
		; original bytes:
;BASE:7EB56		call BASE:0458D	; might be some CreateFile subroutine
;BASE:7EB5B		call BASE:02710	; system.@_IOTest
;BASE:7EB60		mov eax, offset TSW_file_handle
;BASE:7EB65		call BASE:042B8	; system.@Close
;BASE:7EB6A		call BASE:02710	; system.@_IOTest
;BASE:7EB6F		push 0
;BASE:7EB71		mov cx, [BASE:7ECA0]	; const word 3
;BASE:7EB78		mov dl, 2
;BASE:7EB7A		mov eax, offset BASE:7ECAC	; const string '...Overwrite?'
;BASE:7EB7F		call BASE:2CEC8	; _Unit9.MessageDlg
;BASE:7EB84		cmp eax, 6 ;	yes
;BASE:7EB87		jne BASE:7EC04	;	abandon
;BASE:7EB89	; ...

		; patched bytes (* means changed lines):
BASE:7EB56		push eax	;* to save space, push `eax=TSW_file_handle` to stack and pop later (2 bytes vs 5 bytes)
BASE:7EB57		call BASE:0458D
BASE:7EB5C		call BASE:02710
BASE:7EB61		pop eax	;*
BASE:7EB62		call BASE:042B8
BASE:7EB67		call BASE:02710
BASE:7EB6C		mov ecx, [save_overwrite_dialog_style] ;* in replacement of [BASE:7eca0]
BASE:7EB72		test ecx, ecx	;* if 0 => direct overwrite; 3 => msgdlg
BASE:7EB74		jz BASE:7EB89	;* directly overwrite
BASE:7EB76		push 0
BASE:7EB78		mov dl, 2
		; ... the remainder opcodes are the same as the original ones

		; these lines will be executed if you choose "yes" in the msgdlg asking you whether to 'overwrite'
		; originally, if saving is successful, there will always show a 'Saved the Game' message (save_success_msg_tedit8_id = 0x86)
		; however, this is not necessary - but even annoying - if a message always shows up every time a temp data is saved
		; so we will assign `TSW_tedit8_msg_id` to, rather than a constant 0x86, a variable `save_success_msg_tedit8_id`, which is 0x86 in normal cases, but will be 0 (empty string) when saving a temp data (see `sub_savetemp`)
		; original bytes:
;BASE:7EBF2		mov [TSW_tedit8_msg_id], 0086	; 'Saved the Game'
		; patched bytes:
BASE:7EBF2		mov eax, [save_success_msg_tedit8_id]
BASE:7EBF7		mov [TSW_tedit8_msg_id], eax
BASE:7EBFC	; ...

		; same as BASE:7EBF2, but these lines will be executed if there was no data with the same name, thus without the risk of overwriting
BASE:7EC7F		mov eax, [save_success_msg_tedit8_id]	; was: mov [TSW_tedit8_msg_id], 0086
BASE:7EC84		mov [TSW_tedit8_msg_id], eax
BASE:7EC89	; ...

BASE:7EC9C	TTSW10.savework	endp

		; the following subroutines will be patched to enable the save temp function

		TTSW10.taisen	proc near	; 'attack-first' monsters use another subroutine: `taisen2`
		; ...
		; original bytes
;BASE:4A588		jns loc_if_end1	; your ATK <= monster's DEF
;BASE:4A58A		mov eax, [ebp-04]
;BASE:4A58D		call BASE:4C04C	; TTSW10.idou
;BASE:4A592		mov [BASE:B86B8], 1
;BASE:4A59C	loc_if_end1:
;			mov eax, [BASE:8C5B8]	; monster ID
;BASE:4A5A1		mov [BASE:8C55C], eax	; some temp var
;BASE:4A5A6		mov eax, [BASE:8C5B8]	; this is unnecessary
		; patched bytes
BASE:4A588		jns loc_if_end1
BASE:4A58A		call sub_savetemp
BASE:4A58F		mov eax, [ebp-04]
BASE:4A592		call BASE:4C04C
BASE:4A597	loc_if_end1:
			mov [BASE:B86B8], 1
BASE:4A5A1		mov eax, [BASE:8C5B8]
BASE:4A5A6		mov [BASE:8C55C], eax
		; ...

		TTSW10.taisen	endp

		TTSW10.handan	proc near	; exec whenever you move 1 step
		; ...
		; door
		; original bytes
;BASE:4460B		cmp dword ptr [BASE:B86A8], 00	; check if you have yellow key
;BASE:44612		jle BASE:4468C	; no key
		; patched bytes
BASE:4460B		mov al, 8	; TSW_hero_status[8] is your key number
BASE:4460D		call sub_checkkey
BASE:44612		jl BASE:4468C	; in `sub_checkkey`, your key number will be compared with 1, so show 'no key' if `jl` instead of `jle`
		; ...
		; blue door
		; original bytes
;BASE:4463A		cmp dword ptr [BASE:B86B0], 00	; check if you have blue key
;BASE:44641		jle BASE:4468C	; no key
		; patched bytes
BASE:4463A		mov al, 0A	; TSW_hero_status[10] is your blue key number
BASE:4463C		call sub_checkkey
BASE:44641		jl BASE:4468C
		; ...
		; red door
		; original bytes
;BASE:44669		cmp dword ptr [BASE:B86AC], 00	; check if you have red key
;BASE:44670		jle BASE:4468C	; no key
		; patched bytes
BASE:44669		mov al, 9	; likewise
BASE:4466B		call sub_checkkey
BASE:44670		jl BASE:4468C
		; ...
		TTSW10.handan	endp

		TTSW10.roujin	proc near	; old man (we just need to save temp data for 2F oldman)
		; ...
		; original bytes
;BASE:497EE		mov [BASE:8C55C], 42
;BASE:497F8		cmp [BASE:B8810], 0	; whether you have seen 2F oldman before
;BASE:497FF		jne BASE:49B6A
;BASE:49805		mov [BASE:B8810], 1
		; patched bytes
BASE:497EE		mov al, 42	; according to previous opcodes, the high byte/word of eax is 0
BASE:497F0		mov [BASE:8C55C], eax	; this can save 3 bytes
BASE:497F5		cmp [BASE:B8810], 0
BASE:497FC		jne BASE:49B6A
BASE:49802		call sub_savetemp
BASE:49807		mov byte ptr [BASE:B8810], 1	; if [4B8810] is 0, then its high byte/word must be 0; this can save 3 bytes
BASE:4980E		nop
		; ...
		TTSW10.roujin	endp

		TTSW10.Button2Click	proc near	; you click yes for merchant
		; ...
		; normal merchants
		; original bytes
BASE:4E267		cmp eax, [TSW_gold_price]	; eax is the gold you have
		; patched bytes
BASE:4E267		call sub_checkgold
BASE:4E26C		nop
		; ...
		; 28F merchant who buys yellow keys from you
		; original bytes
;BASE:4E4F8		cmp [BASE:B86A8], 0	; eax is the gold you have
;BASE:4E4FF		jne BASE:4E55C	; do business
		; patched bytes
BASE:4E4F8		mov al, 8	; TSW_hero_status[8] is your key number
BASE:4E4FA		call sub_checkkey
BASE:4E4FF		jnl BASE:4E55C	; in `sub_checkkey`, your key number will be compared with 1, so do business if `jnl` instead of `jne`
		; ...
		TTSW10.Button2Click	endp

		TTSW10.Button38Click	proc near	; you click 'use' for an item
		; ...
		; original bytes
;BASE:50BDF		mov eax, [TSW_item_id]
		; patched bytes
BASE:50BDF		call sub_checkitem
		; ...
		TTSW10.Button38Click	endp

		TTSW10.Button39Click	proc near	; you click 'add HP' at an altar
		; ...
		; normal merchants
		; original bytes
BASE:52116		cmp eax, [TSW_gold_price]	; eax is the gold you have
		; patched bytes
BASE:52116		call sub_checkgold
BASE:5211B		nop
		; ...
		TTSW10.Button39Click	endp

		; likewise for TTSW10.Button40Click (add ATK) and TTSW10.Button41Click (add DEF)

		TTSW10.mevent	proc near	; type-7 trap tile
		; ...
		; original bytes
;BASE:6399B		mov eax, [BASE:B8698]	; floor number
		; patched bytes
BASE:6399B		call sub_checkfloor
		; ...
		TTSW10.mevent	endp


; ==========


EXTRA:0000	; Injected buffer by tswSL

EXTRA:0000	tmp_id_addr	:= dword ptr EXTRA:0039	; the index where to replace 'ID' with 2-digit number
			; this is just an example; if `tmp_filename` changes, the index will of course change accordingly

		; char tmp_filename[0x108]
EXTRA:0000	tmp_filename	db 'C:\Program Files (x86)\Tower of the Sorcerer\Savedat\autoID.tmp',0
			; this is just an example; if the installation path of TSW is different, this string will of course change accordingly
			; autoID.tmp: stores current index; auto00~FF.tmp: 256 temp data files
EXTRA:0040		align 0108	; len = MAX_PATH + 4

EXTRA:0108	bytesRead	dd 0	; dummy parameter passed to `ReadFile` and `WriteFile`
EXTRA:010C	tmp_id	db 0	; current temp data index
EXTRA:010D		align 02
EXTRA:010E	last_coordinate	dw 00FE	; = x+y*16+floor*256
			; do not save temp data with the same `last_coordinate`; set as 254 at the start of / after loading a game, so no coordinate will be equal to this value (i.e. always save a first temp data)

		; char dat_filename[0x108]
EXTRA:0110	dat_filename	db 'C:\Program Files (x86)\Tower of the Sorcerer\Savedat\%y%m%d_0.dat',0
			; this is just an example; if the installation path of TSW is different, this string will of course change accordingly
EXTRA:0152		align 0108	; len = MAX_PATH + 4

EXTRA:0218	dat_suffix	db '_0.dat',0,0	; if the data file already exists, the suffix to append at the end to avoid overwriting

		; word id_str[0x100]
EXTRA:0220	id_str	dw '00','01','02','03','04','05','06','07','08','09','0A','0B','0C','0D','0E','0F','10','11','12','13','14','15','16','17','18','19','1A','1B','1C','1D','1E','1F','20','21','22','23','24','25','26','27','28','29','2A','2B','2C','2D','2E','2F','30','31','32','33','34','35','36','37','38','39','3A','3B','3C','3D','3E','3F','40','41','42','43','44','45','46','47','48','49','4A','4B','4C','4D','4E','4F','50','51','52','53','54','55','56','57','58','59','5A','5B','5C','5D','5E','5F','60','61','62','63','64','65','66','67','68','69','6A','6B','6C','6D','6E','6F','70','71','72','73','74','75','76','77','78','79','7A','7B','7C','7D','7E','7F','80','81','82','83','84','85','86','87','88','89','8A','8B','8C','8D','8E','8F','90','91','92','93','94','95','96','97','98','99','9A','9B','9C','9D','9E','9F','A0','A1','A2','A3','A4','A5','A6','A7','A8','A9','AA','AB','AC','AD','AE','AF','B0','B1','B2','B3','B4','B5','B6','B7','B8','B9','BA','BB','BC','BD','BE','BF','C0','C1','C2','C3','C4','C5','C6','C7','C8','C9','CA','CB','CC','CD','CE','CF','D0','D1','D2','D3','D4','D5','D6','D7','D8','D9','DA','DB','DC','DD','DE','DF','E0','E1','E2','E3','E4','E5','E6','E7','E8','E9','EA','EB','EC','ED','EE','EF','F0','F1','F2','F3','F4','F5','F6','F7','F8','F9','FA','FB','FC','FD','FE','FF'
			; covert byte number to 2-digit hex string


EXTRA:0420	comdlg32_dllname	db 'ComDlg32.dll',0
EXTRA:042E		align 04
EXTRA:0430	opendialog_funcname	db 'GetOpenFileNameA',0
EXTRA:0441		align 04
EXTRA:0444	savedialog_funcname	db 'GetSaveFileNameA',0
EXTRA:0455		align 04

EXTRA:0458	opendialog_addr	dd 0	; will be populated by `GetProcAddress` in `sub_init`
EXTRA:045C	savedialog_addr	dd 0	; will be populated by `GetProcAddress` in `sub_init`
EXTRA:0460	save_overwrite_dialog_style	dd 0003	; in replacement of BASE:7eca0
EXTRA:0464	save_success_msg_tedit8_id	dd 0086	; in replacement of const 0x86 ('Saved the game.')
EXTRA:0468	filename_pointer_addr	dd 0048c5d4	; pointer of pointer; in replacement of BASE:8c5d4
EXTRA:046C	dialog_filter	db 'Game Data (*.dat)',0,'*.dat',0,'Temp Data (*.tmp)',0,'*.tmp',0,'All Files',0,'*.*',0,0
EXTRA:04AB		align 0040

EXTRA:04AC	title_load	db 'Load Data',0
EXTRA:04B6		align 04
EXTRA:04B8	title_save	db 'Save Data',0
EXTRA:04C2		align 04

EXTRA:04C4	dialog_struct: 
			istruc OPENFILENAME
			at OPENFILENAME.lStructSize,	dd 004C
			at OPENFILENAME.hwndOwner,	dd $hWnd
			at OPENFILENAME.hInstance,	dd 0
			at OPENFILENAME.lpstrFilter,	dd offset dialog_filter
			at OPENFILENAME.lpstrCustomFilter,	dd 0
			at OPENFILENAME.nMaxCustFilter,	dd 0
			at OPENFILENAME.nFilterIndex,	dd 1	; should set to 1 every time
			at OPENFILENAME.lpstrFile,	dd offset dat_filename
			at OPENFILENAME.nMaxFile,	dd 0108	; MAX_PATH + 4
			at OPENFILENAME.lpstrFileTitle,	dd 0
			at OPENFILENAME.nMaxFileTitle,	dd 0
			at OPENFILENAME.lpstrInitialDir,	dd 0
			at OPENFILENAME.lpstrTitle,	dd offset title_load	; should set to `title_load` or `title_save` every time
			at OPENFILENAME.Flags,	dd 221804	; 0x200000=LongNames; 0x20000=NoNetworkButton; 0x1000=FileMustExist; 0x800=PathMustExist; 0x4=HideReadOnly; should not set `FileMustExist` or `HideReadOnly` for save dialogs
			at OPENFILENAME.nFileOffset,	dw 0
			at OPENFILENAME.nFileExtension,	dw 0
			at OPENFILENAME.lpstrDefExt,	dd 0
			at OPENFILENAME.lCustData,	dd 0
			at OPENFILENAME.lpfnHook,	dd 0
			at OPENFILENAME.lpTemplateName,	dd 0
			iend


		;===== SUBROUTINE =====
EXTRA:0510	sub_init	proc near	;load open/save dialog lib; load last saved tmp data id (default 0 and create hidden file if file not exist)

			push offset comdlg32_dllname
EXTRA:0515		call LoadLibraryA	; the loaded functions will be reused once they are loaded for the first time, so no need to `FreeLibrary`
EXTRA:051A		push offset savedialog_funcname
EXTRA:051F		push eax
EXTRA:0520		push offset opendialog_funcname
EXTRA:0525		push eax
EXTRA:0526		call GetProcAddress
EXTRA:052b		mov [opendialog_addr], eax
EXTRA:0530		call GetProcAddress
EXTRA:0535		mov [savedialog_addr], eax

EXTRA:053A		push 00
EXTRA:053C		push 02	; dwFlagsAndAttributes=FILE_ATTRIBUTE_HIDDEN
EXTRA:053E		push 04	; dwCreationDisposition=OPEN_ALWAYS
EXTRA:0540		push 00
EXTRA:0542		push 07	; dwShareMode=FILE_SHARE_(READ|WRITE|DELETE)
EXTRA:0544		push 080000000	; dwDesiredAccess=GENERIC_READ
EXTRA:0549		push offset tmp_filename	; lpFileName
EXTRA:054E		call CreateFileA
EXTRA:0553		cmp eax, -1	; INVALID_HANDLE_VALUE
EXTRA:0556		je loc_ret1
EXTRA:0558		push eax
EXTRA:0559		push 0
EXTRA:055B		push offset bytesRead
EXTRA:0560		push 1	; nNumberOfBytesToRead=1
EXTRA:0562		push offset tmp_id	; lpBuffer
EXTRA:0567		push eax
EXTRA:0568		call ReadFile
EXTRA:056D		call CloseHandle

EXTRA:0572	loc_ret1:
			ret

		sub_init	endp
EXTRA:0573	align 04


		;===== SUBROUTINE =====
EXTRA:0574	sub_loadtemp	proc near	; load last temp data; if successful, decrease `temp_id` by 1

			xor eax, eax
EXTRA:0576		mov [tedit8_msg_id], eax	; reset the msg as empty str (this is to prevent the last msg being 0x85)
EXTRA:057B		mov al, byte ptr [tmp_id]
EXTRA:0580		sub al, cl	; prev tempdata: cl=1; next tempdata: cl=-1 (need to pass cl value to this subroutine beforehand; see `sub_checkHotkey`)
EXTRA:0582		push eax	; this will be used later for assigning new values to `tmp_id`
EXTRA:0583		mov ax, word ptr [eax*2+id_str]	; change tmp data filename
EXTRA:058B		push eax	; this will be used later for showing status bar messages
EXTRA:058C		mov [tmp_id_addr], ax
EXTRA:0592		mov eax, offset TSW_datacheck1
EXTRA:0597		mov [filename_pointer_addr], eax	; `TSW_datacheck1` is now used as a temporary pointer to the tmp data file name (see `TTSW10.loadwork`)
EXTRA:059C		mov [eax], offset tmp_filename
EXTRA:05A2		mov eax, ebx	; TSW_TTSW10_handle (ebx is perserved in almost all subroutines)
			; ebx usually should be preserved (pushed at the beginning and popped at the end), but since most subroutines (e.g. menu click and form keydown) will do these treatments, so we do not need to anything further
EXTRA:05A4		call TTSW10.Load81Click	; note: after calling this subroutine, ecx is automatically set as 0 (there is a `push 0` at the beginning and a `pop ecx` at the end)
			; to be more specific, ecx is [ebp-4], which is set as the pointer of the title of TMemo12, i.e. the savedat path; after @LStrClr is called (always called even with error), the memory is freed and the pointer (and thus ecx) is set as 0
EXTRA:05A9		mov [filename_pointer_addr], offset TSW_filename_addr
EXTRA:05B3		pop eax	; this is the string form of temp data ID
EXTRA:05B4		mov edx, offset msg_load_result
EXTRA:05C9		mov word ptr [edx+17], ax	; replace ID string
EXTRA:05BD		pop eax	; this is the integer form of temp data ID
EXTRA:05BE		cmp byte ptr [tedit8_msg_id], 85	; success
EXTRA:05C5		jne loc_fail	; cl = 0 and do not change `tmp_id`

EXTRA:05C7		mov byte ptr [tmp_id], al	; change `tmp_id` if successful
EXTRA:05CC		mov cl, 8	; msg_load_succ is 8 bytes after msg_load_unsucc

EXTRA:05CE	loc_fail:
			ret	; the remainder will be treated in `sub_checkHotkey` because I run out of space here

		sub_loadtemp	endp
EXTRA:05CF	align 04


		;===== SUBROUTINE =====
EXTRA:05D0	sub_rec_tmpid	proc near	; record the current tmp data ID in `autoID.tmp`

			mov word ptr [tmp_id_addr], 4449	; "\x49\x44" = 'ID'
EXTRA:05D9		push 00
EXTRA:05DB		push 02
EXTRA:05DD		push 04
EXTRA:05DF		push 00
EXTRA:05E1		push 07
EXTRA:05E3		push 40000000	; dwDesiredAccess=GENERIC_WRITE
EXTRA:05E8		push offset tmp_filename	; lpFileName
EXTRA:05ED		call CreateFileA
EXTRA:05F2		cmp eax, -01
EXTRA:05F5		je loc_ret2
EXTRA:05F7		push eax
EXTRA:05F8		push 00
EXTRA:05FA		push offset bytesRead
EXTRA:05FF		push 1	; nNumberOfBytesToRead=1
EXTRA:0601		push offset tmp_id	; lpBuffer
EXTRA:0606		push eax
EXTRA:0607		call WriteFile
EXTRA:060C		call CloseHandle
EXTRA:0611	loc_ret2:
			ret

		sub_init	endp
EXTRA:0612	align 04


		;===== SUBROUTINE =====
EXTRA:0614	sub_loadanydat	proc near	; load an arbitrary data file using the OpenFile dialog

			mov eax, offset dialog_struct
EXTRA:0619		mov [eax+OPENFILENAME.nFilterIndex], 1
EXTRA:0620		mov [eax+OPENFILENAME.lpstrTitle], offset title_load
EXTRA:0627		mov [eax+OPENFILENAME.Flags], 00221804	; LongNames|NoNetworkButton|FileMustExist|PathMustExist|HideReadOnly
EXTRA:062E		push eax
EXTRA:062F		call dword ptr [opendialog_addr]
EXTRA:0635		test eax,eax
EXTRA:0637		je loc_ret3	; cancel
EXTRA:0639		mov eax, offset TSW_datacheck1
EXTRA:063E		mov [filename_pointer_addr], eax
EXTRA:0643		mov [eax], offset dat_filename
EXTRA:0649		mov eax, ebx
EXTRA:064B		call TTSW10.Load81Click
EXTRA:0650		mov [filename_pointer_addr], offset TSW_filename_addr

EXTRA:065A	loc_ret3:
			ret

		sub_init	endp
EXTRA:065B	align 04


		;===== SUBROUTINE =====
EXTRA:065C	sub_saveanydat	proc near	; load an arbitrary data file using the OpenFile dialog
			; if the default file already exists, then rename according the following rules:
			; * if the ending char (excluding the extname) is 0-9, then change it to 1-A
			; otherwise, add dat_suffix="_1.dat" at the end (ignore the original extname)
			push 00
EXTRA:065E		push 00	; dwFlagsAndAttributes=do not care
EXTRA:0660		push 03	; dwCreationDisposition=OPEN_EXISTING
EXTRA:0662		push 00
EXTRA:0664		push 07
EXTRA:0666		push 00	; dwDesiredAccess=query only
EXTRA:0668		push offset dat_filename
EXTRA:066D		call CreateFileA
EXTRA:0672		cmp eax, -1
EXTRA:0675		je loc_nochange	; such file doesn't exist (there are actually many other causes for CreateFile to fail; the best method is to call GetFileAttributes, but unfortunately it is not loaded by TSW. Another method might be to check GetLastError, but the possibilities are just too many)
EXTRA:0677		push eax
EXTRA:0678		call CloseHandle

EXTRA:067D	loc_forloop1_start:	; find the extname
			xor eax, eax	; al = i; ah = dat_filename[i]
EXTRA:067F		xor edx, edx	; dl = last_index_of('.'); dh = last_index_of('\')
EXTRA:0681		cmp al, FF	; break when i reaches 255
EXTRA:0683		je loc_forloop1_end
EXTRA:0685		mov ah, [eax+offset dat_filename]
EXTRA:068B		test ah, ah	; break when dat_filename[i] == '\0'
EXTRA:068D		je loc_forloop1_end
EXTRA:068F		cmp ah, 5C	; dat_filename[i] == '\'
EXTRA:0692		je loc_foundslash
EXTRA:0694		cmp ah, 2E	; dat_filename[i] == '.'
EXTRA:0697		jne loc_defaultcase1
EXTRA:0699		mov dl, al
EXTRA:069B		jmp loc_defaultcase1

EXTRA:069D	loc_foundslash:
			mov dh, al

EXTRA:069F	loc_defaultcase1:
			xor ah, ah	; this is necessary because eax will be used
EXTRA:06A1		inc al
EXTRA:06A3		jmp loc_forloop1_start

EXTRA:06A5		cmp dh, dl
EXTRA:06A7		jae loc_no_extname	; jae not jge because dh and dl can be > 127
EXTRA:06A9		mov al, dl	; al = i; use the index of '.' if '.' appears after the last '\'; otherwise, use the end index

EXTRA:06AB	loc_no_extname:
			sub al, 01	; sub not dec because dec won't set CF
EXTRA:06AD		jb loc_nochange	; abort if al==0; jb not jl because al can be > 127
EXTRA:06AF		push edi
EXTRA:06B0		push esi
EXTRA:06B1		cld	; DF=0 (incremental ESI/EDI)
EXTRA:06B2		lea esi, [eax+offset dat_filename]
EXTRA:06B8		mov edi, esi	; esi = edi = &dat_filename[i]
EXTRA:06BA		lodsb	; al = [esi]; esi += 1
EXTRA:06BB		sub al, 30
EXTRA:06BD		sub al, 09
EXTRA:06BF		jb loc_is0to8	; al in [0x30, 0x30+9)
EXTRA:06C1		je loc_is9	; al == 0x39
EXTRA:06C3		inc edi	; otherwise... edi = &dat_filename[i+1]
EXTRA:06C4		mov esi, offset dat_suffix	; '_1.dat\0\0' len=8
EXTRA:06C9		movsd	; [edi] = [esi]; edi += 4; esi += 4
EXTRA:06CA		movsd	; twice because length is 8
EXTRA:06CB		jmp loc_finishchange

EXTRA:06CD	loc_is9:
			add al, 07	; '9' +8 = 'A'

EXTRA:06CF	loc_is0to8:
			add al, 3A	; '0'~'8' +1 = '1'~'9' (need to add 0x39 back first)
EXTRA:06D1		stosb	; [edi] = al

EXTRA:06D2	loc_finishchange:
			pop esi
EXTRA:06D3		pop edi
EXTRA:06D4		jmp sub_saveanydat	; loop until a file is available

EXTRA:06D6	loc_nochange:
			mov eax, offset dialog_struct
EXTRA:06DB		mov [eax+OPENFILENAME.nFilterIndex], 1
EXTRA:06E2		mov [eax+OPENFILENAME.lpstrTitle], offset title_save
EXTRA:06E9		mov [eax+OPENFILENAME.Flags], 00220800	; LongNames|NoNetworkButton|PathMustExist
EXTRA:06F0		push eax
EXTRA:06F1		call dword ptr [savedialog_addr]
EXTRA:06F7		test eax, eax
EXTRA:06F9		jne loc_saveas1
EXTRA:06FB		ret

EXTRA:06FC	loc_saveas1:
			mov [TSW_tedit8_msg_id], 09	; this is another empty string. If this is not changed, then saving fails
EXTRA:0706		mov ecx, offset dat_filename	; will then continue to exec `sub_saveas`

		sub_saveanydat	endp
EXTRA:070B	align 04


		;===== SUBROUTINE =====
EXTRA:070C	sub_saveas	proc near	; note: eax, ecx, and edx will be changed! they will become 0, 0, and fs:[0] respectively
			push ebp	; initiate error handling
EXTRA:070D		mov ebp, esp
EXTRA:070F		push 00
EXTRA:0711		push ebx
EXTRA:0712		push esi
EXTRA:0713		push edi
EXTRA:0714		xor eax, eax
EXTRA:0716		push ebp
EXTRA:0717		push offset loc_handle_error1
EXTRA:071C		push fs:[eax]
EXTRA:071F		mov fs:[eax], esp	; finish initiating error handling

EXTRA:0722		mov edx, offset TSW_filename_addr
EXTRA:0727		mov eax, [edx]
EXTRA:0729		mov [filename_pointer_addr], eax
EXTRA:072E		mov [edx], ecx	; [ecx] = filename to save (parameter passed to this subroutine)
EXTRA:0730		mov eax, [TSW_TTSW10_handle]
EXTRA:0735		call TTSW10.savework

EXTRA:073A		xor eax, eax	; finalize error handling
EXTRA:073C		pop edx
EXTRA:073D		pop ecx
EXTRA:073E		pop ecx
EXTRA:073F		mov fs:[eax], edx
EXTRA:0742		push offset loc_sub_end1	; complete finalizing error handling

EXTRA:0747	loc_finally1:
			mov edx, offset TSW_filename_addr
EXTRA:074C		mov ecx, [edx]
EXTRA:074E		mov ebx, offset filename_pointer_addr
EXTRA:0753		mov eax, [ebx]
EXTRA:0755		mov [edx], eax
EXTRA:0757		mov [ebx], edx	; restore original string pointer
EXTRA:0759		xor eax, eax
EXTRA:075B		mov al, 03	; restore (see `sub_savetemp`)
EXTRA:075D		mov [save_overwrite_dialog_style], eax
EXTRA:0762		mov al, 86	; restore (see `sub_savetemp`)
EXTRA:0764		mov [save_success_msg_tedit8_id], eax
EXTRA:0769		mov edx, offset TSW_tedit8_msg_id
EXTRA:076E		cmp dword ptr [edx], 09	; saving fails
EXTRA:0771		jne loc_savesuccess
EXTRA:0773		mov byte ptr [edx], 00
EXTRA:0776		mov ebx, offset msg_save_unsucc
EXTRA:077B		xor edx, edx	; '\0'
EXTRA:077D		cmp ecx, offset tmp_filename	; now is saving a temp data
EXTRA:0783		jne loc_noshowID
EXTRA:0785		mov dl, 20	; space
EXTRA:0787		mov ax, [tmp_id_addr]
EXTRA:078D		mov [ebx+15], ax

EXTRA:0791	loc_noshowID:
			mov [ebx+0E], dl
EXTRA:0794		push ebx
EXTRA:0795		push $hWndText
EXTRA:079A		call SetWindowTextA	; show "Game not saved" msg
EXTRA:079F		mov eax, [TSW_TTSW10_handle]
EXTRA:07A4		call TTSW10.itemlive	; this is necessary because if you are in the middle of an event (so items not "alive"), then the game will freeze if saving fails (because the later `TTSW10.itemlive` in the game event subroutine will never be called)
EXTRA:07A9		xor eax, eax	; set ZF=1

EXTRA:07AB	loc_savesuccess:
			ret	; this will go to either loc_sub_end1 or some error cleanup function

EXTRA:07AC	loc_handle_error1:
			jmp system.@HandleFinally
EXTRA:07B1		jmp loc_finally1

EXTRA:07B3	loc_sub_end1:
			pop edi
EXTRA:07B4		pop esi
EXTRA:07B5		pop ebx
EXTRA:07B6		pop ecx
EXTRA:07B7		pop ebp
EXTRA:07B8		ret

		sub_saveas	endp
EXTRA:07B9	align 0010


EXTRA:07C0	msg_save_unsucc	db 'Game not saved - autoID.tmp',0
EXTRA:07DC		align 0010


		;===== SUBROUTINE =====
EXTRA:07E0	sub_checkkey	proc near
			and eax, 7F	; get only the low-7 bit
EXTRA:07E3		cmp [eax*4+offset TSW_hero_status], 1	; eax = index of hero status; 8->yellow_key; 9->red_key; A->blue_key
EXTRA:07EB		jnl sub_savetemp	; have at least 1 key; then do `sub_savetemp`
			; note: after returned from `sub_savetemp`, no need to do `cmp` again, because `xor eax, eax` will set the correct flag registers (same below)

EXTRA:07ED	loc_ret4:
			ret

		sub_checkkey	endp
EXTRA:07EE	align 04


		;===== SUBROUTINE =====
EXTRA:07F0	sub_checkgold	proc near
			cmp eax, [TSW_gold_price]	; eax = gold you have
EXTRA:07F6		jl loc_ret4	; don't have enough gold; then return; otherwise continue to exec `sub_savetemp`

		sub_checkgold	endp


		;===== SUBROUTINE =====
EXTRA:07F8	sub_savetemp	proc near

			mov edx, offset TSW_hero_status
EXTRA:07FD		mov eax, [edx+10]	; floor
EXTRA:0800		shl eax, 04
EXTRA:0803		or eax, [edx+1C]	; y_pos
EXTRA:0806		shl eax, 04
EXTRA:0809		or eax, [edx+18]	; x_pos
EXTRA:080C		mov edx, last_coordinate
EXTRA:0811		cmp ax, word ptr [edx]
EXTRA:0814		je loc_ret5	; equal then won't trigger `jl`
EXTRA:0816		mov word ptr [edx], ax
EXTRA:0819		xor eax,eax
EXTRA:081B		mov al, byte ptr [tmp_id]
EXTRA:0820		mov ax, word ptr [eax*2+id_str]
EXTRA:0828		mov word ptr [tmp_id_addr], ax
EXTRA:082E		xor eax, eax
EXTRA:0830		mov [save_overwrite_dialog_style], eax
EXTRA:0835		mov [save_success_msg_tedit8_id], eax
EXTRA:083A		mov al, 09
EXTRA:083C		mov [TSW_tedit8_msg_id], eax
EXTRA:0841		mov ecx, offset tmp_filename
EXTRA:0846		call sub_saveas
EXTRA:084B		je loc_ret5	; saving fails (see EXTRA:076E and EXTRA:07A9); equal then won't trigger `jl`
EXTRA:084D		inc byte ptr [tmp_id]
EXTRA:0853		call sub_rec_tmpid
EXTRA:0858		xor eax, eax	; set ZF=1, OF=SF=0, which can trigger `jnl` and `je`

EXTRA:085A	loc_ret5:
			ret

		sub_saveas	endp
EXTRA:085B	align 04


		;===== SUBROUTINE =====
EXTRA:085C	sub_checkfloor	proc near	; this will be checked if a type-7 tile is met (floor with trap) because some of them are not worth saving a temp data
			mov edx, offset TSW_hero_status
EXTRA:0861		mov eax, [edx+10]	; floor
EXTRA:0864		cmp eax, 03	; 3F "Zeno"
EXTRA:0867		je loc_ret6
EXTRA:0869		cmp eax, 17	; 23F "Go 0F"
EXTRA:086C		je loc_ret6
EXTRA:086E		cmp eax, 2A	; 42F "Golden Knight & Zeno"
EXTRA:0871		je loc_ret6
EXTRA:0873		cmp eax, 20	; 32F "Golden Knight"
EXTRA:0876		je loc_downstairs
EXTRA:0878		mov edx, offset last_coordinate	; otherwise, check if is boss battle
EXTRA:087D		mov ax, word ptr [edx]
EXTRA:0880		cmp ax, 1495	; last coordinate is F=20, x=5, y=9 (before the red door for Vampire battle)
EXTRA:0884		je loc_move_lastcoord
EXTRA:0886		cmp ax, 19A5	; last coordinate is F=25, x=5, y=10 (before the red door for Archsorcerer battle)
EXTRA:088A		je loc_move_lastcoord
EXTRA:088C		cmp ax, 2885	; last coordinate is F=40, x=5, y=8 (before the red door for GoldenKnight battle)
EXTRA:0890		je loc_move_lastcoord
EXTRA:0892		cmp ax, 3175	; last coordinate is F=49, x=5, y=7 (before the gate for Zeno battle)
EXTRA:0896		je loc_move_lastcoord
EXTRA:0898		cmp ax, 0A95	; last coordinate is F=10, x=5, y=9 (before the red door for SkeletonA battle)
EXTRA:089C		jne loc_saveas2	; if not so, save the temp data as normal
EXTRA:089E		sub byte ptr [edx], 30	; if so, change the value of `last_coordinate` to the current position, so that no new temp data will be saved (because there is already one before the boss battle door)

EXTRA:08A1	loc_move_lastcoord:
			sub byte ptr [edx], 10	; the specialness of 10F boss battle is that the trap position is 4 steps up w.r.t the red door, whereas for all other boss battles, the trap position is only 2 steps up
EXTRA:08A4		jmp loc_saveas2	; do not exec the following 2 lines

EXTRA:08A6	loc_downstairs:
			dec [edx+10]	; the specialness of the 32F event is that this happens as soon as you touch the 31F stairs and arrives at 32F; so if a temp data is saved on 32F, then this event won't be triggered after you load that temp data (unless you go downstaris and then upstairs again), so let's revert the stairs event
EXTRA:08A9		mov byte ptr [TSW_hero_face], 1 ; by decreasing the floor number by 1 and making hero face down


EXTRA:08B0	loc_saveas2:
			call sub_saveas
EXTRA:08B5		mov edx, offset TSW_hero_status
EXTRA:08BA		mov eax, [edx+10]	; floor
EXTRA:08BD		cmp eax, 1F	; 32F->31F; after we save the temp data, we should now change back
EXTRA:08C0		jne loc_ret6
EXTRA:08C2		inc eax	; this is important, because eax=floor_number will be used later
EXTRA:08C3		mov [edx+10], eax	; change floor number back to 32F
EXTRA:08C6		mov byte ptr [TSW_hero_face], 4	; and make hero face up again

EXTRA:08CD	loc_ret6:
			ret

		sub_checkfloor	endp
EXTRA:08CE	align 04


		;===== SUBROUTINE =====
EXTRA:08D0	sub_checkitem	proc near	; xxx

			mov eax, TSW_item_id
EXTRA:08D6		cmp eax, 0C	; SnowCrystal; no need to save temp data
EXTRA:08D9		je loc_ret6

EXTRA:08DB		push eax
EXTRA:08DC		cmp eax, 09	; ascent wing
EXTRA:08DF		je loc_wings
EXTRA:08E1		cmp eax, 0A	; descent wing
EXTRA:08E4		jne loc_saveas3	; normal item

EXTRA:08E6	loc_wings:
			mov edx, offset TSW_hero_status
EXTRA:08EB		mov eax, [edx+10]	; floor
EXTRA:08EE		cmp [esp], 09	; ascent wing
EXTRA:08F2		je loc_ascent_wing

EXTRA:08F4		cmp eax, 01	; descent wing; should not be used below 1F
EXTRA:08F7		jl loc_ret7
EXTRA:08F9		dec eax
EXTRA:08FA		jmp loc_check_dest

EXTRA:08FC	loc_ascent_wing:
			cmp eax, 32	; ascent wing; should not be used above 50F
EXTRA:08FF		jnl loc_ret7
EXTRA:0901		inc eax

EXTRA:0902	loc_check_dest:
			imul ecx, eax, 7B
EXTRA:0905		mov eax, [edx+1C]	; y_pos
EXTRA:0908		imul eax, eax, 0B
EXTRA:090B		add ecx, eax
EXTRA:090D		mov eax, [edx+18]	; x_pos
EXTRA:0910		add eax, 02	; offset = 123*F+11*y+x+2
EXTRA:0913		cmp byte ptr [eax+ecx+offset TSW_map_data], 06	; is floor
EXTRA:091B		jne loc_ret7

EXTRA:091D	loc_saveas3:
			call sub_savetemp

EXTRA:0922	loc_ret7:
			pop eax	; eax=item_id will be used later
EXTRA:0923		ret

		sub_checkitem	endp


		;===== SUBROUTINE =====
EXTRA:0924	sub_checkHotkey	proc near	; judge what key is pressed in TSW so as to enable the hotkey function of tswSL
			mov esi, ecx	; ecx is the pointer to the pressed virtual key code
EXTRA:0926		mov ebx, eax	; TSW_TTSW10_handle
			; these two lines are copied from the original TTSW10.formkeydown subroutine

EXTRA:0928		mov dh, [esp+08]	; According to detailed analysis, Delphi stores the modifiers (Ctrl/Alt/Shift) in 3 bytes: [esp+8], [esp+0C], and [esp+0x18+1]
EXTRA:092C		mov dl, 00	; caution: Delphi's modifier definition is different from `RegisterHotKey`: here, 1=Shift, 2=Alt, 4=Ctrl
EXTRA:092E		shr dx,1	; so we need to convert it to the `RegisterHotKey` convention here, which is 1=Alt, 2=Ctrl, 4=Shift
EXTRA:0931		shr dl, 05	; basically we rotate the 3-bit to the right by 1 bit
EXTRA:0934		or dh, dl
EXTRA:0936		mov dl, [esi]	; dh=Modifier; dl=VirtualKeyCode
EXTRA:0938		mov byte ptr [esi], 0	; cancel further processing key events in subroutine `formkeydown` (in case there is any conflict of hotkeys)
EXTRA:093B		cmp dx, $SLHotKeys0	; default Ctrl+L = 0x24C
EXTRA:0940		je sub_loadanydat
EXTRA:0946		cmp dx, $SLHotKeys1	; default Ctrl+S = 0x253
EXTRA:094B		je sub_saveanydat
EXTRA:0951		mov cl, 1	; cl value will be passed to `sub_loadtemp` to indicate loading whether the prev or next temp data
EXTRA:0953		cmp dx, $SLHotKeys2	; default Bksp = 0x008
EXTRA:0958		je loc_load_temp_2	; cl=1; load prev temp data
EXTRA:095A		cmp dx, $SLHotKeys3	; default Shift+Bksp = 0x408
EXTRA:095F		je loc_load_temp_1	; cl=0 or -1; load next temp data

EXTRA:0961		mov byte ptr [esi], dl	; recover the virtual key code to allow further processing key events in subroutine `formkeydown`
EXTRA:0963		ret

EXTRA:0964	loc_load_temp_1:
			mov cl, -1	; cl=-1; load next temp data
EXTRA:0966		cmp byte ptr [last_coordinate], cl	; if `last_coordinate`==0xFF, then it means you just load the prev tempdata; in this case, `tmp_id` should add 1 (cl=-1)
EXTRA:096C		je loc_load_temp_2
EXTRA:096E		mov cl, 0	; otherwise, no need to change `tmp_id`, so cl=0

EXTRA:0970	loc_load_temp_2:
			call sub_loadtemp

EXTRA:0975		mov eax, [ecx+edx-10]	; copy the corresponding 8-byte string (`msg_load_succ` or `msg_load_unsucc`) to the placeholder at the beginning of `msg_load_result` (ecx is either 0 or 8, defined in `sub_loadtemp`)
EXTRA:0979		mov [edx], eax
EXTRA:097B		mov eax, [ecx+edx-0C]	; 8 bytes = move dword twice
EXTRA:097F		mov [edx+04], eax
EXTRA:0982		push edx	; lpString of user32.SetWindowTextA

EXTRA:0983		jne loc_show_load_msg	; if load data failed, no need to record tmp id (the `cmp` is in `sub_loadtemp`, since there are only `mov` opcodes, the flags are not affected)
EXTRA:0985		call sub_rec_tmpid

EXTRA:098A	loc_show_load_msg:
			push $hWndText	; hwnd
EXTRA:098F		call SetWindowTextA
EXTRA:0994		ret

		sub_checkHotkey	endp
EXTRA:0995	align 10

EXTRA:09A0	msg_load_unsucc	dq 'No such '
EXTRA:09A8	msg_load_succ	dq 'Loaded: '
EXTRA:09B0	msg_load_result	db 'PLCHLDR tempdata - autoID.tmp', 0
EXTRA:09CE		align 0010

; By the way, the TSW .dat game data is a binary format,
; which directly copies the memory data to the file:
; the first 0x1881 bytes are map data starting from BASE:b8934
; the later 0x2AC bytes are status data starting from BASE:b8688 (e.g., the first dword is hero's HP)
