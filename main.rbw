#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun

APP_NAME = 'tswKai3'
APP_FNAME = $Exerb ? ExerbRuntime.filepath : ($0[/^[\/\\]{2}/] ? $0.dup : File.expand_path($0)) # after packed by ExeRB into exe, $0 or __FILE__ will be useless. There is a bug in Ruby's File#expand_path method, which fails to parse UNC paths, so ignore it if the path starts with \\
APP_PATH = File.dirname(APP_FNAME)
CUR_PATH = Dir.pwd
unless $Exerb then require 'rubygems'; $:.unshift(APP_PATH, CUR_PATH) end # add load path (requiring `rubygems` is because for Ruby 1.8, the gem installation path is not automatically included; and this has to happen before adding our path because the user-generated win32/api.so is preferred)
# For ExeRB-packed executables, the filenames of imported modules in the .exy file should be pre-processed such that they don't contain dirname

require 'common'
require 'gui'
require 'tswKai'
require 'tswMP'
require 'tswSL'
require 'tswBGM'
require 'tswMod'

INTERVAL_REHOOK = 450 # the interval for rehook (in msec)
INTERVAL_QUIT = 50 # for quit (in msec)
INTERVAL_TSW_RECHECK = 500 # in msec: when TSW is not running, check every 500 ms if a new TSW instance has started up

def init()
  return nil unless waitForTSW()
  $IMAGE6 = readMemoryDWORD($TTSW+OFFSET_IMAGE6)
  $hWndMemo = [] # reset as empty here and will be assigned later, because during prologue, these textboxes' hWnd are not assigned yet (a potential workaround is to `mov eax, TTSW10.TMemo1/2/3` and `call TWinControl.HandleNeeded`, but I'm lazy and it is really not worth the trouble)

  ShowWindow.call($hWndStatic1, SW_HIDE)
  return false if Str.isCHN().nil? # incompatible TSW game
  initLang()

  checkTSWsize()
  hDC = GetDC.call_r($hWnd)
  $hMemDC = CreateCompatibleDC.call_r(hDC)
  $hBMP = CreateCompatibleBitmap.call_r(hDC, 40, 80) # 40*80 memory bitmap; the top 40*40 region is for tswExt icon (see next line); the bottom 40*40 region is for legacy mode of tswMP, to store the tile image at the current cursor position (see tswMP.rb)
  SetDIBits.call_r(hDC, $hBMP, 0, 40, Ext::EXT_BMP[1], Ext::EXT_BMP[0], 0)
  $hBMP0 = SelectObject.call_r($hMemDC, $hBMP)
  ReleaseDC.call($hWnd, hDC)

  $lpNewAddr = VirtualAllocEx.call_r($hPrc, 0, 4096, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE) # 1 page size
  Kai.need_update # refresh Kai console interface in case there is any change
  SL.init
  BGM.init
  Mod.init
  MPExt.init
  HookProcAPI.hookK

  showWelcomingMsg() if $configDlg != 0 # if `$CONonTSWstartup` and `$configDlg == 0`, will be handled elsewhere after the dialog window is gone
  return true
end
def showWelcomingMsg()
  showMsgTxtbox(9, $pID, $hWnd)
  unless $CONmsgOnTSWstartup
    API.focusTSW()
    return
  end
  keySL = Array.new(4)
  (0..3).each {|i| keySL[i] = getKeyName(SL_HOTKEYS[i] >> 8, SL_HOTKEYS[i] & 0xFF)}
  msgboxTxt(11, MB_ICONASTERISK, $MPhookKeyName, keySL[0], keySL[1], keySL[2], keySL[3], $regKeyName[1], $regKeyName[1], $regKeyName[0], $regKeyName[0], $regKeyName[0])
end
def checkMsg(state=1) # state: false=TSW not running; otherwise, 1=no console; 2=console
  while !PeekMessage.call($buf, 0, 0, 0, 1).zero?
    msg = $buf.unpack(MSG_INFO_STRUCT)
    hWnd = msg[0]
    msgType = msg[1]
    if hWnd == $hWndStatic1
      Static1_CheckMsg(msg)
    elsif hWnd == $hWndDialog
      Dialog_CheckMsg(msg)
      next unless IsDialogMessage.call($hWndDialog, $buf).zero?
    elsif (i=$hWndChkBoxes.index(hWnd))
      ChkBox_CheckMsg(i, msg)
      next unless IsDialogMessage.call($hWndDialog, $buf).zero?
    elsif msgType == WM_HOTKEY
      if $keybdinput_num > 0xFF # this hotkey event only serves to "steal" the focus from another foreground process
        $keybdinput_num &= 0xFF
        next # don't do extra stuff
      end
      case msg[2]
      when 0
        time = msg[4]
        diff = time - $time
        $time = time
        if diff < INTERVAL_QUIT # hold
          quit()
        elsif diff < INTERVAL_REHOOK # twice
          next if !state or state==2 or $configDlg # TSW must be running; console/dialog must not be running
          showMsgTxtbox(-1)
          HookProcAPI.rehookK
          msgboxTxt(12, MB_ICONASTERISK, $MPhookKeyName)
        elsif state
          API.focusTSW()
        elsif !$CONshowStatusTip.nil? # show status tip window
          Static1_Show(true)
        end
      when 1
        if state == 1
          if $configDlg # dialog -> console
            next if $configDlg == 0 # do not do this if it's shown during startup
            $configDlg = false
            writeMemoryDWORD(Mod::MOD_FOCUS_HWND_ADDR, 0) # hiding the dialog window below will implicitly switch focus to the TSW game window, so need to unset the HWND to set focus to (see Entry #-1 of tswMod.asm)
            ShowWindow.call($hWndDialog, SW_HIDE)
            Kai.main()
          else # nothing -> dialog
            HookProcAPI.abandon()
            showMsgTxtbox(-1)
            Mod.showDialog(true)
          end
        elsif !state and !$CONshowStatusTip.nil? # show status tip window
          Static1_Show(true)
        end
      end
      next
    elsif msgType == WM_APP
      case msg[2]
      when 0
        HookProcAPI.handleHookExceptions # check if error to be processed within hook callback func
      when Ext::EXT_WPARAM
        Ext.main()
      else # signal from console by `SetConsoleCtrlHandler`
        $console.need_free = false # don't call `FreeConsole` (by unsetting `$console.need_free`; in this case, `$console` is definitely not `nil`), or it will freeze!
        quit()
      end
    end

    TranslateMessage.call($buf)
    DispatchMessage.call($buf)
  end
end

$time = 0
$regKeyName = Array.new(2)
initSettings()
initLang()
getRegKeyName()
RegisterHotKey.call_r(0, 0, MP_MODIFIER, MP_HOTKEY)
RegisterHotKey.call_r(0, 1, CON_MODIFIER, CON_HOTKEY)
res = init()
waitInit(!res.nil?) unless res

loop do
  case MsgWaitForMultipleObjects.call_r(1, $bufHWait, 0, -1, $configDlg ? QS_ALLINPUT : QS_ALLBUTTIMER) # For XP-style checkboxes, there is an animation with changed checked state, so WM_TIMER should still be processed for redrawing the checkboxes
  when 0 # TSW has quitted
    disposeRes()
    if $keybdinput_struct.ord == INPUT_KEYBOARD # there is at least one registered hotkeys
      SendInput.call_r($keybdinput_num, $keybdinput_struct, INPUT_STRUCT_LEN) # we can "steal" the focus from the current foreground process by sending a systemwide hotkey event
      $keybdinput_num |= 0x100 # to tell the msg loop no need to do extra stuff for this dummy hotkey event
    end
    if $CONaskOnTSWquit then quit() if msgboxTxt(22, MB_ICONASTERISK|MB_YESNO) == IDNO end
    waitInit()
    next
  when 1 # this thread's msg
    checkMsg()
  end
end
