#!/usr/bin/env ruby
# encoding: ASCII-8Bit

APP_NAME = 'tswKai3'
APP_PATH = File.dirname($Exerb ? ExerbRuntime.filepath : File.expand_path($0)) # after packed by ExeRB into exe, $0 or __FILE__ will be useless
CUR_PATH = Dir.pwd
$:.unshift(APP_PATH, CUR_PATH) unless $Exerb # add load path
# For ExeRB-packed executables, the filenames of imported modules in the .exy file should be pre-processed such that they don't contain dirname

require 'common'
require 'gui'
require 'tswKai'
require 'tswMP'
require 'tswSL'
require 'tswBGM'

INTERVAL_REHOOK = 450 # the interval for rehook (in msec)
INTERVAL_QUIT = 50 # for quit (in msec)
INTERVAL_TSW_RECHECK = 500 # in msec: when TSW is not running, check every 500 ms if a new TSW instance has started up

def init()
  return unless waitForTSW()
  $IMAGE6 = readMemoryDWORD($TTSW+OFFSET_IMAGE6)
  $hWndMemo = [] # reset as empty here and will be assigned later, because during prologue, these textboxes' hWnd are not assigned yet (a potential workaround is to `mov eax, TTSW10.TMemo1/2/3` and `call TWinControl.HandleNeeded`, but I'm lazy and it is really not worth the trouble)

  ShowWindow.call($hWndStatic1, SW_HIDE)
  Str.isCHN()
  initLang()

  checkTSWsize()
  $hDC = GetDC.call_r($hWnd)
  $hMemDC = CreateCompatibleDC.call_r($hDC)
  $hBMP = CreateCompatibleBitmap.call_r($hDC, 40, 40)
  SelectObject.call_r($hDC, $hBr)
  SelectObject.call_r($hDC, $hPen)
  SelectObject.call_r($hMemDC, $hBMP)
  SetROP2.call_r($hDC, R2_XORPEN)
  SetBkColor.call($hDC, HIGHLIGHT_COLOR[-2])
  SetBkMode.call($hDC, 1) # transparent
  SetTextColor.call($hDC, HIGHLIGHT_COLOR.last)

  $lpNewAddr = VirtualAllocEx.call_r($hPrc, 0, 4096, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE) # 1 page size
  SL.init
  BGM.init
  HookProcAPI.hookK

  key1 = getKeyName(MP_MODIFIER, MP_HOTKEY); key2 = getKeyName(CON_MODIFIER, CON_HOTKEY); keySL = Array.new(4)
  (0..3).each {|i| keySL[i] = getKeyName(SL_HOTKEYS[i] >> 8, SL_HOTKEYS[i] & 0xFF)}
  showMsgTxtbox(9, $pID, $hWnd)
  msgboxTxt(11, MB_ICONASTERISK, $MPhookKeyName, keySL[0], keySL[1], keySL[2], keySL[3], key2, key1, key1)
  return true
end
def checkMsg(state=1) # state: false=TSW not running; otherwise, 1=no console, no dialog; 2=console; 3=dialog
  while !PeekMessage.call($buf, 0, 0, 0, 1).zero?
    msg = $buf.unpack(MSG_INFO_STRUCT)
    hWnd = msg[0]
    msgType = msg[1]
    if hWnd == $hWndStatic1
      Static1_CheckMsg(msg)
    elsif msgType == WM_HOTKEY
      case msg[2]
      when 0
        time = msg[4]
        diff = time - $time
        $time = time
        if diff < INTERVAL_QUIT # hold
          quit()
        elsif diff < INTERVAL_REHOOK # twice
          next if !state or state==2 # TSW must be running; console must not be running
          showMsgTxtbox(-1)
          HookProcAPI.rehookK {}
          msgboxTxt(12, MB_ICONASTERISK, $MPhookKeyName)
        elsif !state and !$CONshowStatusTip.nil? # show status tip window
          ShowWindow.call($hWndStatic1, SW_SHOW)
          SetForegroundWindow.call($hWndStatic1)
        end
      when 1
        if state == 1 # show console
          HookProcAPI.rehookK { KaiMain() } # console loop can cause significant delay when working in combination with hook, so need to stop hook temporarily and reinstall after it is done
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
initSettings()
initLang()
RegisterHotKey.call_r(0, 0, MP_MODIFIER, MP_HOTKEY); $_HOTKEYMP = true
RegisterHotKey.call_r(0, 1, CON_MODIFIER, CON_HOTKEY); $_HOTKEYCON = true
getRegKeyName()
waitInit() unless init()

loop do
  case MsgWaitForMultipleObjects.call_r(1, $bufHWait, 0, -1, QS_ALLBUTTIMER)
  when 0 # TSW has quitted
    disposeRes()
    if $CONaskOnTSWquit then quit() if msgboxTxt(22, MB_ICONASTERISK|MB_YESNO) == IDNO end
    waitInit()
    next
  when 1 # this thread's msg
    checkMsg()
  end
end
