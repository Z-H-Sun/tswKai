#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: https://github.com/Z-H-Sun/tswKai/blob/main/tswMod.asm
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
SetFocus = API.new('SetFocus', 'L', 'L', 'user32')
IsDialogMessage = API.new('IsDialogMessage', 'LP', 'I', 'user32')

LISTBOX2_45FMERCHANT_DIALOG_ID = 256
LISTBOX2_NEWENTRY_DIALOG_ID = 268
OFFSET_LISTBOX2 = 0x44c
OFFSET_RICHEDIT1 = 0x1cc
WINSIZE_ADDR = 0x89ba4 + BASE_ADDRESS # byte (0:640x400; 1:800x500)
STR_45FMERCHANT_ADDHP = ['2000', '88000'] # 1000 gold for 2000 HP in the 1st found; for 88000 HP in the backside tower

MOD_PATCH_OPTION_COUNT = 5
MOD_TOTAL_OPTION_COUNT = 8
MOD_DIALOG_WIDTH = 256
MOD_DIALOG_HEIGHT = 242
DIALOG_FONT = [-11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Tahoma']
$CONonTSWstartup = true # whether to show config window and apply default config on TSW startup
$CONmodStatus = [true, true, true, true, true] # if `$CONonTSWstartup`, this specifies the default config
$_TSWMOD = true

$hGUIFont2 = CreateFontIndirect.call_r(DIALOG_FONT.pack(LOGFONT_STRUCT))
$hWndDialogParent = CreateWindowEx.call_r(0, DIALOG_CLASS_NAME, APP_MUTEX_TITLE, 0, 0, 0, 0, 0, 0, 0, 0, 0) # the reason to create this hierarchy is to hide the following dialog window from the task bar
$hWndDialog = CreateWindowEx.call_r(0, DIALOG_CLASS_NAME, nil, WS_SYSMENU, 100, 100, MOD_DIALOG_WIDTH, MOD_DIALOG_HEIGHT, $hWndDialogParent, 0, 0, 0) # see https://learn.microsoft.com/en-us/windows/win32/shell/taskbar#managing-taskbar-buttons
SendMessagePtr.call($hWndDialog, WM_SETICON, ICON_BIG, $hIco)
$hWndChkBoxes = Array.new(7)
for i in 0...MOD_TOTAL_OPTION_COUNT
  if i < MOD_PATCH_OPTION_COUNT
    $hWndChkBoxes[i] = CreateWindowEx.call_r(0, BUTTON_CLASS_NAME, nil, BS_TSWCON, 5, i*36+8, 245, i==4 ? 18 : 36, $hWndDialog, 0, 0, 0)
  else
    $hWndChkBoxes[i] = CreateWindowEx.call_r(0, BUTTON_CLASS_NAME, nil, BS_TSWCON, i*80-395, 178, 80, 28, $hWndDialog, 0, 0, 0)
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
  MOD_PATCH_BYTES_1 = [ # offset, len, original bytes, patched bytes
# 49F Zeno animation bug
[0x637dd, 2, "\xFF\3", "\x90\x90"] # TTSW10.madoushi2
  ] # this list: always patch
  MOD_PATCH_BYTES_2 = [ # N, [offset]*N, [len]*N, [original bytes, patched bytes]*N
[6, [22, 13, 18, 18, 15, 6], # show only one-turn animation
 [0x4b492, 0x4a95e, 0x8002f, 0x7fa6f, 0x52bf4, 0x52c64],
 ["\x8B\x15\x6C\xC5\x48\x00\x4A\x85\xD2\x0F\x8E\x09\x02\x00\x00\xC7\x45\xF8\x01\x00\x00\x00",
  "\x8B\x15\x68\xC5\x48\x00\x29\x15\x88\x86\x4B\x00\xE9\x07\x02\x00\x00\x90\x90\x90\x90\x90"], # TTSW10.taisen
 ["\xFF\x03\x8B\x0B\x8D\x0C\x49\x66\xC7\x04\x4E\x00\x00",
  "\x31\xD2\x89\x15\x88\x86\x4B\x00\xE9\x3F\x0D\x00\x00"], # TTSW10.taisen (gameover)
 ["\xA1\x6C\xC5\x48\x00\x85\xC0\x0F\x8E\x05\x02\x00\x00\xBA\x01\x00\x00\x00",
  "\xA1\x68\xC5\x48\x00\x29\x05\x88\x86\x4B\x00\xB8\x01\x00\x00\x00\x8B\xD0"], # TTSW10.taisen2
 ["\xBA\x01\x00\x00\x00\x89\x15\x58\xC5\x48\x00\x83\x3D\x58\xC5\x48\x00\x01",
  "\x31\xD2\x89\x15\x88\x86\x4B\x00\x42\x8B\xC2\x83\xFA\x01\x90\x90\x90\x90"], # TTSW10.taisen2 (gameover)
 ["\x01\x05\xBC\xC5\x48\x00\x83\x3D\xBC\xC5\x48\x00\x00\x7D\x07", "\x90"*15], # TTSW10.stackwork (monster)
 ["\x01\x05\x88\x86\x4B\x00", "\x90"*6]], # TTSW10.stackwork (hero)
[1, [55], [0x4c600], # 47F MagicianA bug
 ["\x8B\xFE\x4F\x83\xEF\x09\x0F\x83\xCF\x00\x00\x00\x6B\xF6\x0B\x03\x35\xA0\x86\x4B\x00\x03\x35\x68\xC5\x48\x00\x83\xEE\x7A\x0F\x83\xB7\x00\x00\x00\x6B\x35\xA4\x86\x4B\x00\x0B\x03\x35\xA0\x86\x4B\x00\x03\x35\x68\xC5\x48\x00",
  "\x8B\x3D\x68\xC5\x48\x00\x01\xFE\x83\xEE\xEC\x83\xEE\x33\x0F\x83\xC7\x00\x00\x00\x03\x3D\xA0\x86\x4B\x00\x83\xFF\xFF\x0F\x84\xB8\x00\x00\x00\x83\xFF\x0B\x0F\x84\xAF\x00\x00\x00\x6B\x35\xA4\x86\x4B\x00\x0B\x01\xFE\x90\x90"]
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
  "\xA1\x04\x89\x4B\x00\x40\xC1\xE8\x02\x04\x0A\xA3\x58\xC5\x48\x00\xC6\x05\x98\xC5\x48\x00\x34\xC6\x05\x9C\xC5\x48\x00\x40"],
 ["\x73\x2E\x8D\x4D\xFC\x8B\x15\x58\xC5\x48\x00\x81\xC2\xF6\x00\x00\x00",
  "\x72\x05\x3C\x09\x75\x2A\x40\x8D\x4D\xFC\x05\x02\x01\x00\x00\x8B\xD0"]],
[1, [6], [0x55b78], # 50F 3rd round Zeno bug
 ["\x8B\x86\x7C\x02\x00\x00", "\x31\xC0\x90\x90\x90\x90"]], # TTSW10.syokidata2
[1, [148], [0x84f66], # increase dialog margin
 ["\xA1\xFC\xA6\x48\x00\xE8\x38\xEC\xF9\xFF\x3D\x20\x03\x00\x00\x7D\x10\x80\x3D\xA4\x9B\x48\x00\x01\x75\x07\xC6\x05\xA4\x9B\x48\x00\x00\xA0\xA4\x9B\x48\x00\x2C\x01\x72\x04\x74\x45\xEB\x66\xA1\xFC\xA6\x48\x00\xE8\x0A\xEC\xF9\xFF\x3D\x20\x03\x00\x00\x7D\x0D\x33\xD2\x8B\x83\x74\x04\x00\x00\xE8\xC6\xB3\xF8\xFF\xB8\xFC\xC5\x48\x00\xBA\x58\x88\x48\x00\xE8\x6B\xE5\xF7\xFF\xC7\x05\x78\xC5\x48\x00\x90\x00\x00\x00\xC7\x05\x7C\xC5\x48\x00\x18\x00\x00\x00\xEB\x23\xB8\xFC\xC5\x48\x00\xBA\x68\x88\x48\x00\xE8\x46\xE5\xF7\xFF\xC7\x05\x78\xC5\x48\x00\xB4\x00\x00\x00\xC7\x05\x7C\xC5\x48\x00\x1E\x00\x00\x00",
  "\x8A\x15\xA4\x9B\x48\x00\x6B\xD2\x03\xB0\x09\x00\xD0\xA3\x00\x9A\x48\x00\x2C\x04\xA3\x04\x9A\x48\x00\x8B\x93\xCC\x01\x00\x00\x8B\x4A\x2C\x04\x06\x28\xC1\x89\x0D\x08\x9A\x48\x00\x8B\x4A\x30\x2C\x04\x28\xC1\x89\x0D\x0C\x9A\x48\x00\x8B\x8A\xC0\x00\x00\x00\x50\x31\xC0\x68\x00\x9A\x48\x00\x50\xB0\xB3\x50\x51\xE8\xCD\x01\xF8\xFF\x66\xC7\x05\x0C\x9A\x48\x00\xF4\x01\x58\x3C\x07\xB8\xFC\xC5\x48\x00\xBA\x58\x88\x48\x00\x75\x15\xE8\x58\xE5\xF7\xFF\xC6\x05\x78\xC5\x48\x00\x90\xC6\x05\x7C\xC5\x48\x00\x18\xEB\x16\x83\xC2\x10\xE8\x40\xE5\xF7\xFF\xC6\x05\x78\xC5\x48\x00\xB4\xC6\x05\x7C\xC5\x48\x00\x1E"]
  ] # TTSW10.syokidata0
  ] # this list: patch only when set in config

  module_function
  def init
    MOD_PATCH_BYTES_1.each {|i| WriteProcessMemory.call_r($hPrc, i[0]+BASE_ADDRESS, i[3], i[1], 0)} # must-do patches
    $hWndListBox = readMemoryDWORD(readMemoryDWORD($TTSW+OFFSET_LISTBOX2)+OFFSET_HWND)
    $RichEdit1 = readMemoryDWORD($TTSW+OFFSET_RICHEDIT1)
    $hWndRichEdit = readMemoryDWORD($RichEdit1+OFFSET_HWND)
    (0...MOD_PATCH_OPTION_COUNT).each {|i| patch(i, $CONmodStatus[i] ? 1 : 0) unless $CONmodStatus[i].nil?}
    return unless $CONonTSWstartup
    showDialog(true)
    $configDlg = 'init' # need to wrap up after the dialog window is gone
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
    else
      workup = ($configDlg == 'init')
      $configDlg = false
      EnableWindow.call($hWnd, 1) # re-enable TSW
      ShowWindow.call($hWndDialog, SW_HIDE)
      return true unless tswActive
      IsWindow.call_r($hWnd)
      API.focusTSW()
      HookProcAPI.hookK() if $_TSWMP # reenable tswMP hook
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
  def patch(i, s) # index; new status (0 or 1)
    # extra treatment
    if i == 2 and s == 1 # merchant dialog content
      diff = SendMessage.call_r($hWndListBox, LB_GETCOUNT, 0, nil) - LISTBOX2_NEWENTRY_DIALOG_ID
      if diff < 0 or diff > 1 then msgboxTxt(42, MB_ICONEXCLAMATION, diff); return end
      if diff.zero? # need to add a new entry
        len = SendMessage.call_r($hWndListBox, LB_GETTEXT, LISTBOX2_45FMERCHANT_DIALOG_ID, $buf)
        newentry = $buf[0, len]
        numindex = newentry.index(STR_45FMERCHANT_ADDHP[0])
        unless numindex then API.msgbox($str::APP_TARGET_45F_ERROR_STR % LISTBOX2_45FMERCHANT_DIALOG_ID + newentry, MB_ICONEXCLAMATION); return end
        newentry[numindex, 4] = STR_45FMERCHANT_ADDHP[1]
        SendMessage.call_r($hWndListBox, LB_ADDSTRING, 0, newentry)
      else # new entry already exists
        len = SendMessage.call_r($hWndListBox, LB_GETTEXT, LISTBOX2_NEWENTRY_DIALOG_ID, $buf)
        newentry = $buf[0, len]
        unless newentry.include?(STR_45FMERCHANT_ADDHP[1]) then API.msgbox($str::APP_TARGET_45F_ERROR_STR % LISTBOX2_NEWENTRY_DIALOG_ID + newentry, MB_ICONEXCLAMATION); return end
      end
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
