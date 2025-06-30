#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: tswMod.asm
# My special thanks to Bilibili User '竹林眠り猫', who pioneered the work of analyzing the assembly codes for TSW's battle events and came up with the idea of realizing 'OTK' in TSW (i.e., displaying only one-turn battle animation to save time)

BS_NOTIFY = 0x4000
BS_MULTILINE = 0x2000
BS_TOP = 0x400
BS_3STATE = 5
BS_TSWCON = WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_NOTIFY | BS_MULTILINE | BS_TOP | BS_3STATE
EM_GETRECT = 0xb2
EM_SETRECT = 0xb3
BM_GETCHECK = 0xf0
BM_SETCHECK = 0xf1
LB_ADDSTRING = 0x180
LB_INSERTSTRING = 0x181
LB_DELETESTRING = 0x182
LB_GETTEXT = 0x189
LB_GETTEXTLEN = 0x18a
LB_GETCOUNT = 0x18b
DEFAULT_CHARSET = 1
SetFocus = API.new('SetFocus', 'L', 'L', 'user32')
IsDialogMessage = API.new('IsDialogMessage', 'LP', 'I', 'user32')
EnumFontFamilies = API.new('EnumFontFamilies', 'LSKL', 'I', 'gdi32')

LISTBOX2_45FMERCHANT_DIALOG_ID = 256
LISTBOX2_2NDMAGICIAN_DIALOG_ID = [265, 266]
LISTBOX2_NEWENTRY_DIALOG_ID = 268
OFFSET_LISTBOX2 = 0x44c
OFFSET_RICHEDIT1 = 0x1cc
WINSIZE_ADDR = 0x89ba4 + BASE_ADDRESS # byte (0:640x400; 1:800x500)
STR_45FMERCHANT_GOLD = '1000'
INT_45FMERCHANT_ADDHP = 2000 # 1000 gold for 2000 HP in the 1st round
INT_1STMAGICIAN_SUBHP = [200, 100] # 1st-round Magician A and B's magic attack damage

MOD_PATCH_OPTION_COUNT = 5
MOD_TOTAL_OPTION_COUNT = 8
MOD_DIALOG_WIDTH = 278
MOD_DIALOG_HEIGHT = 250
DIALOG_FONT_NAME_PREFERRED = 'Segoe UI' # will try using this font if the system is shipped with it (Segoe UI -> Tahoma -> MSYH (微软雅黑) -> Microsoft YaHei UI -> ...)
DIALOG_FONT_NAME_FALLBACK = 'MS Shell Dlg' # otherwise use this old one instead (Microsoft Sans Serif -> SimSum (宋体) -> ...)
DIALOG_FONT = [-12, 0, 0, 0, 0, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 0, 0, DIALOG_FONT_NAME_FALLBACK]
$CONonTSWstartup = true # whether to show config window and apply default config on TSW startup
$CONmsgOnTSWstartup = true # whether to show tutorial message on TSW startup
$CONmodStatus = [true, true, true, true, true] # if `$CONonTSWstartup`, this specifies the default config

hDC_tmp = GetDC.call(0)
enumFontCallBack = API::Callback.new('LLIL', 'I') {|lpelf, lpntm, font_type, lParam| DIALOG_FONT[-1] = DIALOG_FONT_NAME_PREFERRED; 0} # once find this font, set it as the dialog font, and then return immediately
EnumFontFamilies.call(hDC_tmp, DIALOG_FONT_NAME_PREFERRED, enumFontCallBack, 0)
ReleaseDC.call(0, hDC_tmp)

$hGUIFont2 = CreateFontIndirect.call_r(DIALOG_FONT.pack(LOGFONT_STRUCT))
# the reason to create this hierarchy is to hide the following dialog window from the task bar
$hWndDialog = CreateWindowExW.call_r(0, DIALOG_CLASS_NAME, nil, WS_SYSMENU, 100, 100, MOD_DIALOG_WIDTH, MOD_DIALOG_HEIGHT, $hWndDialogParent, 0, 0, 0) # see https://learn.microsoft.com/en-us/windows/win32/shell/taskbar#managing-taskbar-buttons
SendMessagePtr.call($hWndDialog, WM_SETICON, ICON_BIG, $hIco)
$hWndChkBoxes = Array.new(7)
for i in 0...MOD_TOTAL_OPTION_COUNT
  if i < MOD_PATCH_OPTION_COUNT
    $hWndChkBoxes[i] = CreateWindowExW.call_r(0, BUTTON_CLASS_NAME, nil, BS_TSWCON, 10, i*36+12, MOD_DIALOG_WIDTH-12, i==4 ? 18 : 36, $hWndDialog, 0, 0, 0)
  else
    $hWndChkBoxes[i] = CreateWindowExW.call_r(0, BUTTON_CLASS_NAME, nil, BS_TSWCON, i*87-425, 180, 87, 36, $hWndDialog, 0, 0, 0)
  end
  SendMessagePtr.call($hWndChkBoxes[i], WM_SETFONT, $hGUIFont2, 0)
end

def Dialog_CheckMsg(msg)
  case msg[1]
  when WM_COMMAND # close the dialog through [x] button or sysmenu or Alt+F4
    return if msg[2] != IDCANCEL
  when WM_KEYDOWN
    return if msg[2] != VK_ESCAPE and msg[2] != VK_RETURN # continue if pressed ESC or RETN
  else
    return
  end
  Mod.showDialog(false)
end

def ChkBox_CheckMsg(index, msg)
  msgType = msg[1]
  if msgType == WM_KEYDOWN
    return if msg[2] != VK_ESCAPE and msg[2] != VK_RETURN # if pressed ESC or RETN
    Mod.showDialog(false)
    return
  elsif msgType == WM_LBUTTONUP
  elsif msgType == WM_KEYUP and msg[2] == VK_SPACE
  else return
  end

  hWnd = msg[0]
  case index
  when 0...MOD_PATCH_OPTION_COUNT
    return if $CONmodStatus[index] == 2 and msgboxTxt(41, MB_ICONEXCLAMATION|MB_OKCANCEL) == IDCANCEL
    status = $CONmodStatus[index]
    status = status.zero? ? 1 : 0 # toggle Boolean
    Mod.patch(index, status)
  when MOD_PATCH_OPTION_COUNT
    if !$MPshowMapDmg
      s = 2; $MPshowMapDmg = true # show damage only when you have orb of hero
    elsif $MPshowMapDmg == 1
      s = 0; $MPshowMapDmg = false # never show
    else
      s = $MPshowMapDmg = 1
    end
    MPExt.changeState if $MPnewMode
    SendMessagePtr.call(hWnd, BM_SETCHECK, s, 0)
  when MOD_PATCH_OPTION_COUNT+1
    $SLautosave = !$SLautosave
    SL.enableAutoSave($SLautosave)
    SendMessagePtr.call(hWnd, BM_SETCHECK, $SLautosave ? 1 : 0, 0)
  when MOD_PATCH_OPTION_COUNT+2
    if BGM.bgm_path # BGM files must be ready
      $BGMtakeOver = !$BGMtakeOver
      BGM.takeOverBGM($BGMtakeOver)
      SendMessagePtr.call(hWnd, BM_SETCHECK, $BGMtakeOver ? 1 : 0, 0)
    elsif $BGMtakeOver
      $BGMtakeOver = false
      SendMessagePtr.call(hWnd, BM_SETCHECK, 0, 0)
    else
      $BGMtakeOver = true
      BGM.init()
      SendMessagePtr.call(hWnd, BM_SETCHECK, BGM.bgm_path ? 1 : 2, 0)
    end
  end
  SetFocus.call($hWndChkBoxes[(index+1) % MOD_TOTAL_OPTION_COUNT]) # focus next checkbox
end

module Mod
  MOD_FOCUS_HWND_ADDR = 0x89bf8 + BASE_ADDRESS # there is 88-byte vacant space starting from 0x489ba8 through 0x489c00 (from which the space is reserved for future tswMP functions); the DWORD @ 0x489bfc is reserved by tswRev to store Kernel32.Sleep farproc; so we are using 0x489ba8-f8 to write asm codes for extra TTSW10 WndProc processing (see below); the DWORD @ 0x489bf8 is used to store the HWND of the dialog/console window to set focus to
  MOD_PATCH_BYTES_0 = [ # offset, len, original bytes, patched bytes
[0x89ba8, 84, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", "\x8B\x0D\xF8\x9B\x48\x00\x31\xD2\x39\xD1\x74\x3E\x3B\x1D\x10\xC5\x48\x00\x75\x36\x83\xF8\x1C\x75\x05\x39\x56\x04\x75\x12\x83\xF8\x20\x75\x27\x8B\x46\x0A\x66\x2D\x01\x02\x74\x04\x3C\x03\x75\x18\x6A\x13\x52\x52\x52\x52\x51\xFF\xB3\xC0\x00\x00\x00\x51\xE8\xC1\xB5\xF7\xFF\xE8\x04\xB6\xF7\xFF\x8B\x06\x3D\x84\x00\x00\x00\xC3\0\0\0\0"], # extra TTSW10 WndProc processing + 4-byte HWND of the dialog/console window to set focus to
[0x154a8, 5, "\x3D\x84\0\0\0", "\xE8\xFB\x46\7\0"] # TWinControl.WndProc
  ] # this list: extra function to add to compatibilize dialog/console window display (see Entry #-1 of tswMod.asm)
  MOD_PATCH_BYTES_1 = [ # offset, len, original bytes, patched bytes
[0x637dd, 2, "\xFF\3", "\x90\x90"], # TTSW10.madoushi2; fix 49F Zeno animation bug (see Entry #0 of tswMod.asm)

# ====================
# Item from tswSL.asm (used to be an item in `SL::SL_PATCH_BYTES_1` treated in the SL module)
[0x5084d, 2, "\x33\xD2", "\xEB\x0B"], # TTSW10.itemdel; enable loading during event

# ====================
# List from tswBGM.asm (used to be `BGM::BGM_PATCH_BYTES_0` treated in the BGM module)
[0x312cb, 65, "\x80\xBB\xE2\1\0\0\0\x74\x17\x80\xBB\xE0\1\0\0\0\x74\7\x83\x8B\xDC\1\0\0\2\xC6\x83\xE2\1\0\0\0\x80\xBB\xE4\1\0\0\0\x74\x18\x83\x8B\xDC\1\0\0\4\x8B\x83\xF0\1\0\0\x89\x44\x24\4\xC6\x83\xE4\1\0\0\0", "\x8B\x43\4\x3B\x98\xD8\2\0\0\x74\x3D\x31\xD2\x89\x54\x24\4\5\x64\4\0\0\x3B\x18\x74\x1F\x3B\x58\xFC\xB2\4\x74\2\xB2\x40\xB8\x3B\xA1\x4B\0\x8A\x08\x39\x15\xAC\xC5\x48\0\x0F\x9F\0\x7F\x0C\x84\xC9\x75\x08\x83\x8B\xDC\1\0\0\4\x90"], # TMediaPlayer.Play; improve consecutive sound effects

[0x7ebad, 79, "\x6A\0\xBA\x34\x89\x4B\0\xB9\x81\x18\0\0\xB8\0\xC6\x48\0\xE8\x91\x56\xF8\xFF\xE8\x48\x3B\xF8\xFF\x6A\0\xBA\x88\x86\x4B\0\xB9\xAC\2\0\0\xB8\0\xC6\x48\0\xE8\x76\x56\xF8\xFF\xE8\x2D\x3B\xF8\xFF\xB8\0\xC6\x48\0\xE8\xCB\x56\xF8\xFF\xE8\x1E\x3B\xF8\xFF\xC7\5\x8C\xC5\x48\0\x86\0\0\0", "\x31\xFF\xA1\0\xC6\x48\0\x50\x8D\x4D\xF8\x57\x51\x68\xAC\2\0\0\x68\x88\x86\x4B\0\x50\x57\x51\x68\x81\x18\0\0\x68\x34\x89\x4B\0\x50\xBE\xF0\x87\x4B\0\x87\x3E\xB8\x18\x89\x4B\0\x29\x38\x29\x78\4\xE8\xA8\x26\xF8\xFF\xE8\xA3\x26\xF8\xFF\xE8\x36\x26\xF8\xFF\x89\x3E\xC6\5\x8C\xC5\x48\0\x86\x90"], # TTSW10.savework; do not save BGM_ID into data
[0x7ec3a, 79, "\x6A\0\xBA\x34\x89\x4B\0\xB9\x81\x18\0\0\xB8\0\xC6\x48\0\xE8\4\x56\xF8\xFF\xE8\xBB\x3A\xF8\xFF\x6A\0\xBA\x88\x86\x4B\0\xB9\xAC\2\0\0\xB8\0\xC6\x48\0\xE8\xE9\x55\xF8\xFF\xE8\xA0\x3A\xF8\xFF\xB8\0\xC6\x48\0\xE8\x3E\x56\xF8\xFF\xE8\x91\x3A\xF8\xFF\xC7\5\x8C\xC5\x48\0\x86\0\0\0", "\x31\xFF\xA1\0\xC6\x48\0\x50\x8D\x4D\xF8\x57\x51\x68\xAC\2\0\0\x68\x88\x86\x4B\0\x50\x57\x51\x68\x81\x18\0\0\x68\x34\x89\x4B\0\x50\xBE\xF0\x87\x4B\0\x87\x3E\xB8\x18\x89\x4B\0\x29\x38\x29\x78\4\xE8\x1B\x26\xF8\xFF\xE8\x16\x26\xF8\xFF\xE8\xA9\x25\xF8\xFF\x89\x3E\xC6\5\x8C\xC5\x48\0\x86\x90"], # same above
[0x55aab, 42, "\x83\xBE\x64\1\0\0\0\x75\x0D\xB2\1\x8B\x83\x2C\3\0\0\xE8\x2F\xA8\xFB\xFF\x83\xBE\x68\1\0\0\0\x74\x14\xB2\1\x8B\x83\x30\3\0\0\xE8\x19\xA8", "\xBF\xA3\x9B\x48\0\x80\x3F\0\x75\x0B\x8B\x83\x6C\4\0\0\xE8\xC8\xB6\xFD\xFF\xBA\xEC\x87\x4B\0\x8A\7\x88\2\x8A\x47\xFF\x84\xC0\x75\x17\x88\x42\4\xEB\x25"], # TTSW10.syokidata2_0; WAV and BGM after load; stop previous sound effect

# ====================
# List from tswRev.asm (selected ones that are most critical, not all)
[0x54e0b, 34, "\x33\xD2\x8B\x83\xCC\1\0\0\xE8\xE8\xE6\xFB\xFF\x33\xD2\x8B\x83\xD0\1\0\0\xE8\xDB\xE6\xFB\xFF\x33\xD2\x8B\x83\xD4\1\0\0", "\x31\xFF\x31\xD2\x8B\x84\xBB\xCC\1\0\0\xE8\xE5\xE6\xFB\xFF\x47\x83\xFF\3\x75\xEC\xA0\x46\x99\x4B\0\xA2\x5C\x99\x4B\0\xEB\5"], # Rev 8; Fix a bug of the 33F trap room on the right
[0x73723, 27, "\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46", "\x8D\4\x46\x31\xD2\x89\x10\x66\x89\x50\4\xC6\5\x46\x99\x4B\0\6\xC6\5\x5C\x99\x4B\0\6\xEB\3"], # Rev 8; same above
[0x740be, 2, "\x66\xC7", "\xEB\x48"], # Rev8-b; Fix the wrong prompt after finishing the 40F boss battle

[0x7ff54, 54, "\xFF\x57\x0C\xFF\x75\xF4\x68\x7C\2\x48\0\x8D\x55\xF0\xA1\xB8\xC5\x48\0\3\xC0\x8B\4\xC5\x1C\x99\x48\0\xE8\xF7\x5B\xF8\xFF\xFF\x75\xF0\x8D\x4D\xEC\x8B\x45\xFC\x8B\x80\x4C\4\0\0\x8B\x80\0\1\0\0", "\x89\x45\xEC\xFF\x57\x0C\xFF\x75\xF4\x68\x7C\2\x48\0\xA1\xB8\xC5\x48\0\1\xC0\x8B\4\xC5\x1C\x99\x48\0\x8B\x15\4\x87\x4B\0\x42\xF7\xE2\x8D\x55\xF0\xE8\xEB\x5B\xF8\xFF\xFF\x75\xF0\x8D\x4D\xEC\x8B\1\x90"] # Rev9; Fix the wrong GOLD income prompt after defeating a "strike-first" monster
  ] # this list: always patch
  MOD_PATCH_BYTES_2 = [ # N, [offset]*N, [len]*N, [original bytes, patched bytes]*N
[6, [15, 11, 13, 13, 2, 2], # show only one-turn animation
 [0x4b494, 0x4a95e, 0x80030, 0x7fa6f, 0x52bf4, 0x52c64],
 ["\x6C\xC5\x48\x00\x4A\x85\xD2\x0F\x8E\x09\x02\x00\x00\xC7\x45",
  "\x68\xC5\x48\x00\x29\x15\x88\x86\x4B\x00\xE9\x07\x02\x00\x00"], # TTSW10.taisen
 ["\xFF\x03\x8B\x0B\x8D\x0C\x49\x66\xC7\x04\x4E",
  "\x31\xD2\x89\x15\x88\x86\x4B\x00\xE9\x3F\x0D"], # TTSW10.taisen (gameover)
 ["\x6C\xC5\x48\x00\x85\xC0\x0F\x8E\x05\x02\x00\x00\xBA",
  "\x68\xC5\x48\x00\x29\x05\x88\x86\x4B\x00\x90\x90\xB8"], # TTSW10.taisen2
 ["\xBA\x01\x00\x00\x00\x89\x15\x58\xC5\x48\x00\x83\x3D",
  "\x31\xC0\xA3\x88\x86\x4B\x00\x40\xE9\xBB\x02\x00\x00"], # TTSW10.taisen2 (gameover)
 ["\x01\x05", "\xEB\x0D"], # TTSW10.stackwork (monster)
 ["\x01\x05", "\xEB\x04"]], # TTSW10.stackwork (hero)
[1, [54], [0x4c601], # 47F MagicianA bug
 ["\xFE\x4F\x83\xEF\x09\x0F\x83\xCF\x00\x00\x00\x6B\xF6\x0B\x03\x35\xA0\x86\x4B\x00\x03\x35\x68\xC5\x48\x00\x83\xEE\x7A\x0F\x83\xB7\x00\x00\x00\x6B\x35\xA4\x86\x4B\x00\x0B\x03\x35\xA0\x86\x4B\x00\x03\x35\x68\xC5\x48\x00",
  "\x3D\x68\xC5\x48\x00\x01\xFE\x83\xEE\xEC\x83\xEE\x33\x0F\x83\xC7\x00\x00\x00\x03\x3D\xA0\x86\x4B\x00\x83\xFF\xFF\x0F\x84\xB8\x00\x00\x00\x83\xFF\x0B\x0F\x84\xAF\x00\x00\x00\x6B\x35\xA4\x86\x4B\x00\x0B\x01\xFE\x90\x90"]
  ], # TTSW10.mazyutu1
[3, [25, 8, 22, 30, 17], # first 3: 45F 2nd round merchant bug; last 2: change dialog contents as well
 [0x4e356, 0x4e39f, 0x4e3d7, # TTSW10.Button2Click (OK)
  0x494ee, 0x4958b], # TTSW10.syounin
 ["\x9F\xE3\x44\x00\xA7\xE3\x44\x00\xB6\xE3\x44\x00\xC5\xE3\x44\x00\xCE\xE3\x44\x00\xD7\xE3\x44\x00\xE3",
  "\x7E\xE3\x44\x00\xA7\xE3\x44\x00\xB6\xE3\x44\x00\xC5\xE3\x44\x00\xCE\xE3\x44\x00\x9F\xE3\x44\x00\xE6"],
 ["\xFF\x05\xB0\x86\x4B\x00\xEB\x46", "\xA1\x04\x89\x4B\x00\x40\xEB\x30"],
 ["\x81\x05\x88\x86\x4B\x00\xD0\x07\x00\x00\xEB\x0A\xC7\x05\x00\x87\x4B\x00\x01\x00\x00\x00",
  "\xBA\xD0\x07\x00\x00\xF7\xE2\x01\x05\x88\x86\x4B\x00\xEB\x07\xC6\x05\x00\x87\x4B\x00\x01"],
 ["\xC7\x05\x58\xC5\x48\x00\x0A\x00\x00\x00\xC7\x05\x98\xC5\x48\x00\x34\x00\x00\x00\xC7\x05\x9C\xC5\x48\x00\x40\x00\x00\x00",
  "\x31\xC0\xBA\x58\xC5\x48\x00\x83\x3D\x04\x89\x4B\x00\x00\x74\x02\xB0\x0C\x04\x0A\x89\x02\xC6\x42\x40\x34\xC6\x42\x44\x40"],
 ["\x73\x2E\x8D\x4D\xFC\x8B\x15\x58\xC5\x48\x00\x81\xC2\xF6\x00\x00\x00",
  "\x72\x04\x3C\x0A\x75\x2A\x8D\x90\x02\x01\x00\x00\x8D\x4D\xFC\x66\x90"]],
[1, [4], [0x55b78], # 50F 3rd round Zeno bug
 ["\x8B\x86\x7C\x02", "\x31\xC0\xEB\x02"]], # TTSW10.syokidata2
[1, [148], [0x84f66], # increase dialog margin
 ["\xA1\xFC\xA6\x48\x00\xE8\x38\xEC\xF9\xFF\x3D\x20\x03\x00\x00\x7D\x10\x80\x3D\xA4\x9B\x48\x00\x01\x75\x07\xC6\x05\xA4\x9B\x48\x00\x00\xA0\xA4\x9B\x48\x00\x2C\x01\x72\x04\x74\x45\xEB\x66\xA1\xFC\xA6\x48\x00\xE8\x0A\xEC\xF9\xFF\x3D\x20\x03\x00\x00\x7D\x0D\x33\xD2\x8B\x83\x74\x04\x00\x00\xE8\xC6\xB3\xF8\xFF\xB8\xFC\xC5\x48\x00\xBA\x58\x88\x48\x00\xE8\x6B\xE5\xF7\xFF\xC7\x05\x78\xC5\x48\x00\x90\x00\x00\x00\xC7\x05\x7C\xC5\x48\x00\x18\x00\x00\x00\xEB\x23\xB8\xFC\xC5\x48\x00\xBA\x68\x88\x48\x00\xE8\x46\xE5\xF7\xFF\xC7\x05\x78\xC5\x48\x00\xB4\x00\x00\x00\xC7\x05\x7C\xC5\x48\x00\x1E\x00\x00\x00",
  "\x8A\x15\xA4\x9B\x48\x00\x6B\xD2\x03\xB0\x09\x00\xD0\xA3\x00\x9A\x48\x00\x2C\x04\xA3\x04\x9A\x48\x00\x8B\x93\xCC\x01\x00\x00\x8B\x4A\x2C\x04\x06\x28\xC1\x89\x0D\x08\x9A\x48\x00\x8B\x4A\x30\x2C\x04\x28\xC1\x89\x0D\x0C\x9A\x48\x00\x8B\x8A\xC0\x00\x00\x00\x50\x31\xC0\x68\x00\x9A\x48\x00\x50\xB0\xB3\x50\x51\xE8\xCD\x01\xF8\xFF\x66\xC7\x05\x0C\x9A\x48\x00\xF4\x01\x58\x3C\x07\xB8\xFC\xC5\x48\x00\xBA\x58\x88\x48\x00\x75\x15\xE8\x58\xE5\xF7\xFF\xC6\x05\x78\xC5\x48\x00\x90\xC6\x05\x7C\xC5\x48\x00\x18\xEB\x16\x83\xC2\x10\xE8\x40\xE5\xF7\xFF\xC6\x05\x78\xC5\x48\x00\xB4\xC6\x05\x7C\xC5\x48\x00\x1E"]
  ] # TTSW10.syokidata0
  ] # this list: patch only when set in config

  module_function
  def init
    (MOD_PATCH_BYTES_0+MOD_PATCH_BYTES_1).each {|i| WriteProcessMemory.call_r($hPrc, i[0]+BASE_ADDRESS, i[3], i[1], 0)} # must-do and compatibilizing patches
    $hWndListBox = readMemoryDWORD(readMemoryDWORD($TTSW+OFFSET_LISTBOX2)+OFFSET_HWND)
    $RichEdit1 = readMemoryDWORD($TTSW+OFFSET_RICHEDIT1)
    $hWndRichEdit = readMemoryDWORD($RichEdit1+OFFSET_HWND)
    (0...MOD_PATCH_OPTION_COUNT).each {|i| patch(i, $CONmodStatus[i] ? 1 : 0) unless $CONmodStatus[i].nil?}
    return unless $CONonTSWstartup
    return if showDialog(true).nil? # fail due to existence of child window
    $configDlg = 0 # need to wrap up after the dialog window is gone
  end
  def showDialog(active, tswActive=true) # active=true/false : show/hide config window; tswActive: if TSW is still running, determining whether to do further operations
    return false if !(active ^ $configDlg) # i.e., `$config` has the same Boolean state with `active`
    if active
      if tswActive and API.focusTSW() != $hWnd # has popup child
        msgboxTxt(28, MB_ICONASTERISK); return nil # fail
      end
      $configDlg = true
      checkChkStates()
      ShowWindow.call($hWndDialog, SW_RESTORE)
      SetForegroundWindow.call($hWndDialog)
      return true unless tswActive
      IsWindow.call_r($hWnd)
      checkTSWsize()
      xy = [$W-MOD_DIALOG_WIDTH >> 1, $H-MOD_DIALOG_HEIGHT >> 1].pack('l2')
      ClientToScreen.call_r($hWnd, xy)
      x, y = xy.unpack('l2')
      SetWindowPos.call_r($hWndDialog, 0, x, y, 0, 0, SWP_NOSIZE|SWP_FRAMECHANGED)
      EnableWindow.call($hWnd, 0) # disable TSW
      writeMemoryDWORD(MOD_FOCUS_HWND_ADDR, $hWndDialog) # tell TSW to set focus to this window when switched to or clicked on (see Entry #-1 of tswMod.asm)
    else
      writeMemoryDWORD(MOD_FOCUS_HWND_ADDR, 0) if tswActive # revert the above operation
      workup = ($configDlg == 0)
      $configDlg = false
      EnableWindow.call($hWnd, 1) # re-enable TSW
      ShowWindow.call($hWndDialog, SW_HIDE)
      return true unless tswActive
      IsWindow.call_r($hWnd)
      API.focusTSW()
      showWelcomingMsg() if workup # wrap up `init` after the initial config dialog window is gone
    end
    return true
  end
  def checkChkStates()
    for i in 0...MOD_PATCH_OPTION_COUNT
      d = MOD_PATCH_BYTES_2[i]
      s = 0
      d[1].each_with_index do |l, j|
        ReadProcessMemory.call_r($hPrc, d[2][j]+BASE_ADDRESS, $buf, l, 0)
        t = d[3+j].index($buf[0, l])
        s = t if j.zero? # first one
        if !t or s != t then s = 2; break end
      end
      $CONmodStatus[i] = s
      SendMessagePtr.call($hWndChkBoxes[i], BM_SETCHECK, s, 0)
    end
    SendMessagePtr.call($hWndChkBoxes[5], BM_SETCHECK, $MPshowMapDmg ? ($MPshowMapDmg==1 ? 1 : 2) : 0, 0)
    SendMessagePtr.call($hWndChkBoxes[6], BM_SETCHECK, $SLautosave ? 1 : 0, 0)
    SendMessagePtr.call($hWndChkBoxes[7], BM_SETCHECK, $BGMtakeOver ? (BGM.bgm_path ? 1 : 2) : 0, 0)
  end
  def replace45FmerchantDialog(factor)
    diff = SendMessage.call_r($hWndListBox, LB_GETCOUNT, 0, nil) - LISTBOX2_NEWENTRY_DIALOG_ID
    if diff < 0 or diff > 1 then msgboxTxt(42, MB_ICONEXCLAMATION, diff); return end

    newhp_str = (INT_45FMERCHANT_ADDHP * (factor+1)).to_s
    len = SendMessage.call_r($hWndListBox, LB_GETTEXT, LISTBOX2_45FMERCHANT_DIALOG_ID, $buf)
    newentry = $buf[0, len]
    numindex = newentry.index(INT_45FMERCHANT_ADDHP.to_s)
    unless newentry.include?(STR_45FMERCHANT_GOLD) and numindex then API.msgbox($str::APP_TARGET_45F_ERROR_STR % LISTBOX2_45FMERCHANT_DIALOG_ID + newentry, MB_ICONEXCLAMATION); return end
    newentry[numindex, 4] = newhp_str
    if diff.zero? # need to add a new entry
      SendMessage.call_r($hWndListBox, LB_ADDSTRING, 0, newentry)
    else # new entry already exists
      len = SendMessage.call_r($hWndListBox, LB_GETTEXT, LISTBOX2_NEWENTRY_DIALOG_ID, $buf)
      newentry2 = $buf[0, len]
      unless newentry2.include?(STR_45FMERCHANT_GOLD) then API.msgbox($str::APP_TARGET_45F_ERROR_STR % LISTBOX2_NEWENTRY_DIALOG_ID + newentry2, MB_ICONEXCLAMATION); return end
      unless newentry2.include?(newhp_str) then SendMessage.call_r($hWndListBox, LB_DELETESTRING, LISTBOX2_NEWENTRY_DIALOG_ID, nil); SendMessage.call_r($hWndListBox, LB_INSERTSTRING, LISTBOX2_NEWENTRY_DIALOG_ID, newentry) end # replace this entry when the HP value is incorrect
    end
    return true
  end
  def replace2ndMagicianDialog(factor)
    diff = SendMessage.call_r($hWndListBox, LB_GETCOUNT, 0, nil) - LISTBOX2_NEWENTRY_DIALOG_ID
    if diff < 0 or diff > 1 then msgboxTxt(42, MB_ICONEXCLAMATION, diff); return end

    (0..1).each do |i|
      hp_str = (INT_1STMAGICIAN_SUBHP[i] * (factor+1)).to_s
      len = SendMessage.call_r($hWndListBox, LB_GETTEXT, LISTBOX2_2NDMAGICIAN_DIALOG_ID[i], $buf)
      entry = $buf[0, len]
      numindex = (entry =~ /(\d+)/)
      unless numindex then API.msgbox($str::APP_TARGET_2ND_ERROR_STR % LISTBOX2_2NDMAGICIAN_DIALOG_ID[i] + entry, MB_ICONEXCLAMATION); return end
      unless entry.include?(hp_str) # replace this entry when the HP value is incorrect
        entry[numindex, $1.size] = hp_str
        SendMessage.call_r($hWndListBox, LB_DELETESTRING, LISTBOX2_2NDMAGICIAN_DIALOG_ID[i], nil)
        SendMessage.call_r($hWndListBox, LB_INSERTSTRING, LISTBOX2_2NDMAGICIAN_DIALOG_ID[i], entry)
      end
    end
    return true
  end
  def patch(i, s) # index; new status (0 or 1)
    # extra treatment
    if i == 2 and s == 1 # merchant dialog content
      factor = readMemoryDWORD(MONSTER_STATUS_FACTOR_ADDR)
      factor = readMemoryDWORD(FUTURE_STATUS_FACTOR_ADDR) if factor.zero?
      return unless replace45FmerchantDialog(factor) # do not proceed if an error is thrown
    elsif i == 4 # make margin change immediately
      w = readMemoryDWORD($RichEdit1+OFFSET_CTL_WIDTH)
      h = readMemoryDWORD($RichEdit1+OFFSET_CTL_HEIGHT)
      if s.zero?
        destRect = [2, 2, w-2, h-2].pack('l4')
      else
        tswSize = readMemoryDWORD(WINSIZE_ADDR) & 0xFF
        if tswSize.zero?
          destRect = [9, 5, w-11, h-7].pack('l4')
        else
          destRect = [12, 8, w-14, h-10].pack('l4')
        end
      end
      SendMessage.call($hWndRichEdit, EM_SETRECT, 0, destRect)
    end

    d = MOD_PATCH_BYTES_2[i]
    d[1].each_with_index {|l, j| WriteProcessMemory.call_r($hPrc, d[2][j]+BASE_ADDRESS, d[3+j][s], l, 0)}
    $CONmodStatus[i] = s
    SendMessagePtr.call($hWndChkBoxes[i], BM_SETCHECK, s, 0)
  end
end

require 'tswModStatic' unless $*.empty? # static patch if there is a filename in the argument
