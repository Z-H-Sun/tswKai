#!/usr/bin/env ruby
# encoding: ASCII-8Bit

# Known issue: not compatible with Ruby >= 3.0
# GetLastError and SetWindowsHookEx won't work with Win32API for Ruby >= 3.0

require 'win32/api'
include Win32

OpenProcess = API.new('OpenProcess', 'LLL', 'L', 'kernel32')
ReadProcessMemory = API.new('ReadProcessMemory', 'LLPLL', 'L', 'kernel32')
WriteProcessMemory = API.new('WriteProcessMemory', 'LLPLL', 'L', 'kernel32')
CloseHandle = API.new('CloseHandle', 'L', 'L', 'kernel32')
GetCurrentThreadId = API.new('GetCurrentThreadId', 'V', 'L', 'kernel32')
GetWindowThreadProcessId = API.new('GetWindowThreadProcessId', 'LP', 'L', 'user32')
FindWindow = API.new('FindWindow', 'SL', 'L', 'user32')
ShowWindow = API.new('ShowWindow', 'LL', 'L', 'user32')
EnableWindow = API.new('EnableWindow', 'LI', 'L', 'user32')
GetLastActivePopup = API.new('GetLastActivePopup', 'L', 'L', 'user32')
SetForegroundWindow = API.new('SetForegroundWindow', 'L', 'L', 'user32')
IsWindow = API.new('IsWindow', 'L', 'L', 'user32')
MessageBox = API.new('MessageBoxA', 'LSSI', 'L', 'user32')
MessageBoxW = API.new('MessageBoxW', 'LSSI', 'L', 'user32')
MessageBeep = API.new('MessageBeep', 'L', 'L', 'user32')
GetMessage = API.new('GetMessage', 'PLLL', 'I', 'user32')
SendMessage = API.new('SendMessageA', 'LLLP', 'L', 'user32')
SendMessageW = API.new('SendMessageW', 'LLLP', 'L', 'user32')

MEM_COMMIT = 0x1000
MEM_RESERVE = 0x2000
MEM_RELEASE = 0x8000
PAGE_READWRITE = 0x04
PAGE_EXECUTE_READWRITE = 0x40
PROCESS_VM_WRITE = 0x20
PROCESS_VM_READ = 0x10
PROCESS_VM_OPERATION = 0x8

WM_SETTEXT = 0xC
WM_GETTEXT = 0xD
WM_COMMAND = 0x111
WM_HOTKEY = 0x312

IDOK = 1
IDCANCEL = 2
IDRETRY = 4
IDYES = 6
IDNO = 7
MB_OKCANCEL = 0x1
MB_YESNO = 0x4
MB_RETRYCANCEL = 0x5
MB_ICONERROR = 0x10
MB_ICONQUESTION = 0x20
MB_ICONEXCLAMATION = 0x30
MB_ICONASTERISK = 0x40
MB_DEFBUTTON2 = 0x100
MB_SETFOREGROUND = 0x10000
SW_HIDE = 0
SW_SHOW = 4 # SHOWNOACTIVATE

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

case [nil].pack('p').size
when 4 # 32-bit ruby
  MSG_INFO_STRUCT = 'L7'
when 8 # 64-bit
  MSG_INFO_STRUCT = 'Q4L3'
else
  raise 'Unsupported system or ruby version (neither 32-bit or 64-bit).'
end

$bufDWORD = "\0" * 4
$buf = "\0" * 640

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
      return r unless r.zero?
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
      raise_r("Err #{err} when calling `#{effective_function_name}'@#{dll_name}.\n#{reason} tswKai has stopped. Details are as follows:\n\nPrototype='#{prototype.join('')}', ReturnType='#{return_type}', ARGV=#{argv.inspect}")
    end
  end
end

unless $Exerb # EXERB GUI has its own error handler window
  alias :_raise :raise
  def raise(*argv)
    _raise(*argv)
  rescue Exception
    API.msgbox("#{$!.inspect}\n\n#{$@.join "\n"}"[0, 1023], MB_ICONERROR) # can't show too long text
  ensure
    exit
  end
end

TSW_CLS_NAME = 'TTSW10'
BASE_ADDRESS = 0x400000
OFFSET_EDIT8 = 0x1c8 # status bar textbox at bottom
OFFSET_HWND = 0xc0
OFFSET_OWNER_HWND = 0x20
TTSW_ADDR = 0x8c510 + BASE_ADDRESS
TAPPLICATION_ADDR = 0x8a6f8 + BASE_ADDRESS
MIDSPEED_MENUID = 33 # The idea is to hijack the midspeed menu
MIDSPEED_ADDR = 0x7f46d + BASE_ADDRESS # so once click event of that menu item is triggered, arbitrary code can be executed
MIDSPEED_ORIG = 0x6F # original bytecode (call TTSW10.speedmiddle@0x47f4e0)
REFRESH_XYPOS_ADDR = 0x42c38 + BASE_ADDRESS # TTSW10.mhyouji
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
def preExit(msg=nil) # finalize
  return if $preExitProcessed # do not exec twice
  $preExitProcessed = true
  CloseHandle.call($hPrc || 0)
  msgboxTxt(msg) if msg
  FreeConsole.call()
end
def raise_r(*argv)
  preExit() # ensure all resources disposed
  raise(*argv)
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
