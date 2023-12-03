#!/usr/bin/env ruby
# encoding: ASCII-8Bit

# Known issue: not compatible with Ruby >= 3.0
# GetLastError and SetWindowsHookEx won't work with Win32API for Ruby >= 3.0

require 'win32/api'
include Win32

GetModuleHandle = API.new('GetModuleHandle', 'I', 'L', 'kernel32')
OpenProcess = API.new('OpenProcess', 'LLL', 'L', 'kernel32')
ReadProcessMemory = API.new('ReadProcessMemory', 'LLPLL', 'L', 'kernel32')
WriteProcessMemory = API.new('WriteProcessMemory', 'LLPLL', 'L', 'kernel32')
CloseHandle = API.new('CloseHandle', 'L', 'L', 'kernel32')
GetCurrentThreadId = API.new('GetCurrentThreadId', 'V', 'L', 'kernel32')
GetWindowThreadProcessId = API.new('GetWindowThreadProcessId', 'LP', 'L', 'user32')
AttachThreadInput = API.new('AttachThreadInput', 'III', 'I', 'user32')
GetClientRect = API.new('GetClientRect', 'LP', 'L', 'user32')
FindWindow = API.new('FindWindow', 'SL', 'L', 'user32')
ShowWindow = API.new('ShowWindow', 'LL', 'L', 'user32')
EnableWindow = API.new('EnableWindow', 'LI', 'L', 'user32')
SetWindowText = API.new('SetWindowTextA', 'LS', 'L', 'user32')
SetWindowTextW = API.new('SetWindowTextW', 'LS', 'L', 'user32')
SetWindowPos = API.new('SetWindowPos', 'LLIIIII', 'L', 'user32')
GetLastActivePopup = API.new('GetLastActivePopup', 'L', 'L', 'user32')
GetForegroundWindow = API.new('GetForegroundWindow', 'V', 'L', 'user32')
SetForegroundWindow = API.new('SetForegroundWindow', 'L', 'L', 'user32')
IsWindow = API.new('IsWindow', 'L', 'L', 'user32')
MessageBox = API.new('MessageBoxA', 'LSSI', 'L', 'user32')
MessageBoxW = API.new('MessageBoxW', 'LSSI', 'L', 'user32')
MessageBeep = API.new('MessageBeep', 'L', 'L', 'user32')
GetMessage = API.new('GetMessage', 'PLLL', 'I', 'user32')
PeekMessage = API.new('PeekMessage', 'PLLLI', 'I', 'user32')
PostMessage = API.new('PostMessage','LLLP', 'I', 'user32')
SendMessage = API.new('SendMessageA', 'LLLP', 'L', 'user32')
SendMessageW = API.new('SendMessageW', 'LLLP', 'L', 'user32')
TranslateMessage = API.new('TranslateMessage', 'P', 'L', 'user32')
DispatchMessage = API.new('DispatchMessage', 'P', 'L', 'user32')
MsgWaitForMultipleObjects = API.new('MsgWaitForMultipleObjects', 'LSILL', 'I', 'user32')
GetStockObject = API.new('GetStockObject', 'I', 'L', 'gdi32')

MEM_COMMIT = 0x1000
MEM_RESERVE = 0x2000
MEM_RELEASE = 0x8000
PAGE_READWRITE = 0x04
PAGE_EXECUTE_READWRITE = 0x40
PROCESS_VM_WRITE = 0x20
PROCESS_VM_READ = 0x10
PROCESS_VM_OPERATION = 0x8
PROCESS_SYNCHRONIZE = 0x100000
QS_TIMER = 0x10
QS_HOTKEY = 0x80
QS_ALLINPUT = 0x4FF
QS_ALLBUTTIMER = QS_ALLINPUT & ~QS_TIMER
WAIT_TIMEOUT = 258

WM_SETTEXT = 0xC
WM_GETTEXT = 0xD
WM_GETTEXTLENGTH = 0xE
WM_SETICON = 0x80
WM_SETFONT = 0x30
WM_KEYDOWN = 0x100
WM_KEYUP = 0x101
WM_MOUSEMOVE = 0x200
WM_LBUTTONDOWN = 0x201
WM_LBUTTONUP = 0x202
WM_RBUTTONDOWN = 0x204
WM_RBUTTONUP = 0x205
WM_COMMAND = 0x111
WM_TIMER = 0x113
WM_HOTKEY = 0x312
WM_APP = 0x8000

IDOK = 1
IDCANCEL = 2
IDRETRY = 4
IDYES = 6
IDNO = 7
MB_OKCANCEL = 0x1
MB_YESNOCANCEL = 0x3
MB_YESNO = 0x4
MB_RETRYCANCEL = 0x5
MB_ICONERROR = 0x10
MB_ICONQUESTION = 0x20
MB_ICONEXCLAMATION = 0x30
MB_ICONASTERISK = 0x40
MB_DEFBUTTON2 = 0x100
MB_SETFOREGROUND = 0x10000
MB_TOPMOST = 0x40000
SW_HIDE = 0
SW_SHOW = 4 # SHOWNOACTIVATE
SW_RESTORE = 9

VK_BACK = 0x8
VK_TAB = 0x9
VK_RETURN = 0xd
VK_ESCAPE = 0x1b
VK_LEFT = 0x25
VK_UP = 0x26
VK_RIGHT = 0x27
VK_DOWN = 0x28
VK_SPACE = 0x20
VK_LWIN = 0x5b
VK_RWIN = 0x5c

POINTER_SIZE = [nil].pack('p').size
case POINTER_SIZE # pointer directive "J" is introduced in Ruby 2.3, for backward compatibility, use fixed-length integer directives here
when 4 # 32-bit ruby
  MSG_INFO_STRUCT = 'L5a8'
  HANDLE_ARRAY_STRUCT = 'L*'
  GetWindowLong = API.new('GetWindowLong', 'LI', 'L', 'user32')
  SetWindowLong = API.new('SetWindowLong', 'LIL', 'L', 'user32')
when 8 # 64-bit
  MSG_INFO_STRUCT = 'Q4La8'
  HANDLE_ARRAY_STRUCT = 'Q*'
  GetWindowLong = API.new('GetWindowLongPtr', 'LI', 'L', 'user32')
  SetWindowLong = API.new('SetWindowLongPtr', 'LIL', 'L', 'user32')
else
  raise Win32APIError, 'Unsupported system or ruby version (neither 32-bit or 64-bit).'
end

$bufHWait = "\0" * (POINTER_SIZE<<1)
$bufDWORD = "\0" * 4
$buf = "\0" * 640
$hMod = GetModuleHandle.call(0)

module Win32
  class API
    def self.focusTSW()
      if $console === true
        hWnd = $console.hConWin
      else
        hWnd = GetLastActivePopup.call($hWndTApp) # there is a popup child
        hWnd = $hWnd if hWnd == $hWndTApp
      end
      ShowWindow.call($hWndTApp, SW_SHOW) # this will restore the window if it was minimized
      SetForegroundWindow.call(hWnd) # SetForegroundWindow for $hWndTApp can also achieve similar effect, but can sometimes complicate the situation, e.g., LastActivePopup will be $hWndTApp if no mouse/keyboard input afterwards
      return hWnd
# by the way, SetForegroundWindow for $hWnd can cause some very serious side effect:
# it will trigger TTSW10.OnActivate=TTSW10.formactivate subroutine
# which will show prolog animation and restart the game! (can change the first opcode `push ebp` to `ret` to avoid)
    end
    def self.msgbox(text, flag=MB_ICONASTERISK, api=(ansi=true; MessageBox), title=$appTitle)
      if IsWindow.call($hWnd || 0).zero?
        hWnd = $hWnd = 0 # if the window has gone, create a system level msgbox
        flag |= MB_TOPMOST
      else
        hWnd = focusTSW() # if there is a popup child, use that as parent window for msgbox
# because if use $hWnd as parent in such cases, the main window will be activated,
# causing a) the popup window losing focus and b) the adverse effect discussed earlier
      end
      title = (ansi ? 'tswKai' : "t\0s\0w\0K\0a\0i\0\0") unless $appTitle
      return api.call(hWnd, text, title, flag | MB_SETFOREGROUND)
    end
    def call_r(*argv) # provide more info if a win32api returns null
      r = call(*argv)
      return r if $preExitProcessed # do not throw error if ready to exit
      if function_name == 'MsgWaitForMultipleObjects'
        return r if r >= 0 # WAIT_FAILED = (DWORD)0xFFFFFFFF
      else
        return r unless r.zero?
      end
      err = '0x%04X' % API.last_error
      case function_name
      when 'OpenProcess', 'WriteProcessMemory', 'ReadProcessMemory', 'VirtualAllocEx'
        reason = "Cannot open / read from / write to / alloc memory for the TSW process. Please check if TSW V1.2 is running with pID=#{$pID} and if you have proper permissions."
      when 'RegisterHotKey'
        reason = "Cannot register hotkey. It might be currently occupied by other processes or another instance of tswKai. Please close them to avoid confliction..."
      when /Console/
        reason = 'Console related...'
      else
        reason = 'This is a fatal error. That is all we know.'
      end
      raise_r(Win32APIError, "Err #{err} when calling `#{effective_function_name}'@#{dll_name}.\n#{reason} tswKai has stopped. Details are as follows:\n\nPrototype='#{prototype.join('')}', ReturnType='#{return_type}', ARGV=#{argv.inspect}")
    end
  end
end

class TSWKaiError < RuntimeError
end
class Win32APIError < RuntimeError
end

unless String.instance_methods.include?(:ord) # backward compatibility w/ Ruby < 1.9
  class String
    def ord
      self[0]
    end
  end
end

unless $Exerb # EXERB GUI has its own error handler window
  alias :_raise :raise
  def raise(*argv)
    if argv[0].is_a?(Class) and argv[0] <= TSWKaiError
      _raise(*argv) # for subclass of TSWKaiError, do not catch here (will be processed later)
    else
      _raise(*argv) rescue API.msgbox("#{$!.inspect}\n\n#{$@.join("\n")}"[0, 1023], MB_ICONERROR) # can't show too long text
      exit
    end
  end
end

APP_SETTINGS_FNAME = 'tswKaiOption.txt'
APP_ICON_ID = 1 # Icons will be shown in the GUI of this app; this defines the integer identifier of the icon resource in the executable
TSW_CLS_NAME = 'TTSW10'
BASE_ADDRESS = 0x400000
OFFSET_EDIT8 = 0x1c8 # status bar textbox at bottom
OFFSET_HWND = 0xc0
OFFSET_OWNER_HWND = 0x20
OFFSET_CTL_LEFT = 0x24
OFFSET_CTL_TOP = 0x28
OFFSET_CTL_WIDTH = 0x2c
# OFFSET_CTL_HEIGHT = 0x30
# OFFSET_CTL_VISIBLE = 0x37 # byte
# OFFSET_CTL_ENABLED = 0x38 # byte
TTSW_ADDR = 0x8c510 + BASE_ADDRESS
TAPPLICATION_ADDR = 0x8a6f8 + BASE_ADDRESS
TEDIT8_MSGID_ADDR = 0x8c58c + BASE_ADDRESS
MAP_LEFT_ADDR = 0x8c578 + BASE_ADDRESS
MAP_TOP_ADDR = 0x8c57c + BASE_ADDRESS
MIDSPEED_MENUID = 33 # The idea is to hijack the midspeed menu
MIDSPEED_ADDR = 0x7f46d + BASE_ADDRESS # so once click event of that menu item is triggered, arbitrary code can be executed
MIDSPEED_ORIG = 0x6F # original bytecode (call TTSW10.speedmiddle@0x47f4e0)
REFRESH_XYPOS_ADDR = 0x42c38 + BASE_ADDRESS # TTSW10.mhyouji
ITEM_LIVE_ADDR = 0x50880 + BASE_ADDRESS # TTSW10.itemlive
BGM_ID_ADDR = 0xb87f0 + BASE_ADDRESS
BGM_CHECK_ADDR = 0x7c8f8 + BASE_ADDRESS # TTSW10.soundcheck
BGM_PLAY_ADDR = 0x7c2bc + BASE_ADDRESS # TTSW10.soundplay
SACREDSHIELD_ADDR = 0xb872c + BASE_ADDRESS
STATUS_ADDR = 0xb8688 + BASE_ADDRESS
STATUS_INDEX = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 9, 11] # HP; ATK; ... Sword and shield are in item list
STATUS_LEN = 12
STATUS_TYPE = 'l12'
ITEM_ADDR = 0xb86c4 + BASE_ADDRESS
ITEM_INDEX = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16] # The first 2 are sword and shield respectively; OrbOfHero; OrbOfWis; ...
ITEM_LEN = 17
ITEM_TYPE = 'l17'
MAP_ADDR = 0xb8934 + BASE_ADDRESS
MAP_TYPE = 'C121'

require './strings'
def disposeRes() # when switching to a new TSW process, hDC and hPrc will be regenerated, and the old ones should be disposed of
  CloseHandle.call($hPrc || 0)
  $appTitle = nil
  if $console === true # hide console on TSW exit
    $console.show(false, $preExitProcessed) # TSW exited: false,false; this app exited: false,true
  end
end
def preExit(msg=nil) # finalize
  return if $preExitProcessed # do not exec twice
  $preExitProcessed = true
  disposeRes()
  msgboxTxt(msg) if msg
  FreeConsole.call()
end
def quit()
  preExit(13); exit
end
def raise_r(*argv)
  preExit() # ensure all resources disposed
  raise(*argv)
end
def checkTSWsize()
  GetClientRect.call_r($hWnd, $buf)
  w, h = $buf[8, 8].unpack('ll')
  return if w == $W and h == $H
  $W, $H = w, h

  $MAP_LEFT = readMemoryDWORD(MAP_LEFT_ADDR)
  $MAP_TOP = readMemoryDWORD(MAP_TOP_ADDR)
end

def readMemoryDWORD(address)
  ReadProcessMemory.call_r($hPrc, address, $bufDWORD, 4, 0)
  return $bufDWORD.unpack('l')[0]
end
def writeMemoryDWORD(address, dword)
  WriteProcessMemory.call_r($hPrc, address, [dword].pack('l'), 4, 0)
end
def callFunc(address) # execute the subroutine at the given address
  writeMemoryDWORD(MIDSPEED_ADDR, address-MIDSPEED_ADDR-4)
  SendMessage.call($hWnd, WM_COMMAND, MIDSPEED_MENUID, 0)
  writeMemoryDWORD(MIDSPEED_ADDR, MIDSPEED_ORIG) # restore
end
def msgboxTxtA(textIndex, flag=MB_ICONASTERISK, *argv)
  API.msgbox(Str::StrEN::STRINGS[textIndex] % argv, flag)
end
def msgboxTxtW(textIndex, flag=MB_ICONASTERISK, *argv)
  API.msgbox(Str.utf8toWChar(Str::StrCN::STRINGS[textIndex] % argv), flag, MessageBoxW)
end
def setTitleA(hWnd, textIndex, *argv)
  SetWindowText.call_r(hWnd, Str::StrEN::STRINGS[textIndex] % argv)
end
def setTitleW(hWnd, textIndex, *argv)
  SetWindowTextW.call_r(hWnd, Str.utf8toWChar(Str::StrCN::STRINGS[textIndex] % argv))
end
