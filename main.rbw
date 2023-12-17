#!/usr/bin/env ruby
# encoding: ASCII-8Bit

APP_NAME = 'tswKai3'
APP_FNAME = $Exerb ? ExerbRuntime.filepath : ($0[/^[\/\\]{2}/] ? $0.dup : File.expand_path($0)) # after packed by ExeRB into exe, $0 or __FILE__ will be useless. There is a bug in Ruby's File#expand_path method, which fails to parse UNC paths, so ignore it if the path starts with \\
APP_PATH = File.dirname(APP_FNAME)
CUR_PATH = Dir.pwd
$:.unshift(APP_PATH, CUR_PATH) unless $Exerb # add load path
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
  $hDC = GetDC.call_r($hWnd)
  $hMemDC = CreateCompatibleDC.call_r($hDC)
  $hBMP = CreateCompatibleBitmap.call_r($hDC, 40, 40)
  SelectObject.call_r($hDC, $hBr)
  SelectObject.call_r($hDC, $hPen)
  SelectObject.call_r($hMemDC, $hBMP)
  SetROP2.call_r($hDC, R2_XORPEN)
  SetBkColor.call_r($hDC, HIGHLIGHT_COLOR[-2])
  SetBkMode.call_r($hDC, 1) # transparent
  SetTextColor.call_r($hDC, HIGHLIGHT_COLOR.last)

  $lpNewAddr = VirtualAllocEx.call_r($hPrc, 0, 4096, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE) # 1 page size
  SL.init
  BGM.init
  Mod.init
  HookProcAPI.hookK

  showWelcomingMsg() unless $CONonTSWstartup # if `$CONonTSWstartup`, will be handled elsewhere after the dialog window is gone
  return true
end
def showWelcomingMsg()
  keySL = Array.new(4)
  (0..3).each {|i| keySL[i] = getKeyName(SL_HOTKEYS[i] >> 8, SL_HOTKEYS[i] & 0xFF)}
  showMsgTxtbox(9, $pID, $hWnd)
  msgboxTxt(11, MB_ICONASTERISK, $MPhookKeyName, keySL[0], keySL[1], keySL[2], keySL[3], $regKeyName[1], $regKeyName[1], $regKeyName[0], $regKeyName[0])
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
        elsif !state and !$CONshowStatusTip.nil? # show status tip window
          ShowWindow.call($hWndStatic1, SW_SHOW)
          SetForegroundWindow.call($hWndStatic1)
        end
      when 1
        if state == 1
          if $configDlg # dialog -> console
            next if $configDlg == 'init' # do not do this if it's shown during startup
            $configDlg = false
            ShowWindow.call($hWndDialog, SW_HIDE)
            KaiMain()
          else # nothing -> dialog
            HookProcAPI.unhookK # no need for tswMP hook now; especially, console loop can cause significant delay when working in combination with hook; will reinstall later
            HookProcAPI.abandon(true)
            showMsgTxtbox(-1)
            Mod.showDialog(true)
          end
        elsif !state and !$CONshowStatusTip.nil? # show status tip window
          ShowWindow.call($hWndStatic1, SW_SHOW)
          SetForegroundWindow.call($hWndStatic1)
        end
      end
      next
    elsif msgType == WM_APP
      HookProcAPI.handleHookExceptions # check if error to be processed within hook callback func
    end

    TranslateMessage.call($buf)
    DispatchMessage.call($buf)
  end
end

$time = 0
$regKeyName = Array.new(2)
$_HOTKEYMP = true
$_HOTKEYCON = true
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
    if $CONaskOnTSWquit then quit() if msgboxTxt(22, MB_ICONASTERISK|MB_YESNO) == IDNO end
    waitInit()
    next
  when 1 # this thread's msg
    checkMsg()
  end
end
