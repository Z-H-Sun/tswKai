#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun

# Known issue: not compatible with Ruby >= 3.0
# GetLastError and SetWindowsHookEx won't work with Win32API or win32/api for Ruby >= 3.0
# Likely thread-related

require 'win32/api'
include Win32
require 'strings'

GetModuleHandle = API.new('GetModuleHandle', 'I', 'L', 'kernel32')
OpenProcess = API.new('OpenProcess', 'LLL', 'L', 'kernel32')
ReadProcessMemory = API.new('ReadProcessMemory', 'LLPLL', 'L', 'kernel32')
WriteProcessMemory = API.new('WriteProcessMemory', 'LLPLL', 'L', 'kernel32')
VirtualAllocEx = API.new('VirtualAllocEx', 'LLLLL', 'L', 'kernel32')
VirtualFreeEx = API.new('VirtualFreeEx', 'LLLL', 'L', 'kernel32')
CloseHandle = API.new('CloseHandle', 'L', 'L', 'kernel32')
GetCurrentThreadId = API.new('GetCurrentThreadId', 'V', 'L', 'kernel32')
GetWindowThreadProcessId = API.new('GetWindowThreadProcessId', 'LP', 'L', 'user32')
AttachThreadInput = API.new('AttachThreadInput', 'III', 'I', 'user32')
SendInput = API.new('SendInput', 'IPI', 'I', 'user32')
GetClientRect = API.new('GetClientRect', 'LP', 'L', 'user32')
FindWindow = API.new('FindWindow', 'SS', 'L', 'user32')
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
SendMessage = API.new('SendMessageA', 'LLLP', 'I', 'user32')
SendMessageW = API.new('SendMessageW', 'LLLP', 'I', 'user32')
TranslateMessage = API.new('TranslateMessage', 'P', 'L', 'user32')
DispatchMessage = API.new('DispatchMessage', 'P', 'L', 'user32')
MsgWaitForMultipleObjects = API.new('MsgWaitForMultipleObjects', 'LSILL', 'I', 'user32')
RegisterHotKey = API.new('RegisterHotKey', 'LILL', 'L', 'user32')
UnregisterHotKey = API.new('UnregisterHotKey', 'LI', 'L', 'user32')

MAX_PATH = 260
MEM_COMMIT = 0x1000
MEM_RESERVE = 0x2000
MEM_RELEASE = 0x8000
PAGE_READWRITE = 0x04
PAGE_EXECUTE_READWRITE = 0x40
PROCESS_VM_WRITE = 0x20
PROCESS_VM_READ = 0x10
PROCESS_VM_OPERATION = 0x8
PROCESS_SYNCHRONIZE = 0x100000
QS_POSTMESSAGE = 0x8
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
VK_SHIFT = 0x10
VK_CONTROL = 0x11
VK_MENU = 0x12
VK_ESCAPE = 0x1b
VK_LEFT = 0x25
VK_UP = 0x26
VK_RIGHT = 0x27
VK_DOWN = 0x28
VK_SPACE = 0x20
VK_LWIN = 0x5b
VK_RWIN = 0x5c
INPUT_KEYBOARD = 1
KEYEVENTF_KEYUP = 2

POINTER_SIZE = [nil].pack('p').size
case POINTER_SIZE # pointer directive "J" is introduced in Ruby 2.3, for backward compatibility, use fixed-length integer directives here
when 4 # 32-bit ruby
  INPUT_STRUCT_LEN = 28
  INPUT_STRUCT = 'LSSLLLQ' # DWORD type; KEYBDINPUT ki {WORD wVK; WORD wScan; DWORD dwFlags; DWORD time; ULONG_PTR dwExtraInfo}; uint64_t dummy
  MSG_INFO_STRUCT = 'L5a8' # HWND hwnd; UINT message; WPARAM wParam; LPARAM lParam; DWORD time; POINT pt {LONG x; LONG y}
  HANDLE_STRUCT = 'L'
  GetWindowLong = API.new('GetWindowLong', 'LI', 'L', 'user32')
  SetWindowLong = API.new('SetWindowLong', 'LIL', 'L', 'user32')
when 8 # 64-bit
  INPUT_STRUCT_LEN = 40
  INPUT_STRUCT = 'QSSLQQQ' # must take alignment into consideration
  MSG_INFO_STRUCT = 'Q4La8'
  HANDLE_STRUCT = 'Q'
  GetWindowLong = API.new('GetWindowLongPtr', 'LI', 'L', 'user32')
  SetWindowLong = API.new('SetWindowLongPtr', 'LIL', 'L', 'user32')
else
  raise Win32APIError, $str::ERR_MSG[0]
end

$bufHWait = "\0" * (POINTER_SIZE << 1)
$bufDWORD = "\0" * 4
$buf = "\0" * 640
$keybdinput_struct = "\xFF"
$keybdinput_num = 0
$hMod = GetModuleHandle.call(0)

module Win32
  FormatMessage = API.new('FormatMessage', 'ILIIPIP', 'I', 'kernel32')
  FORMAT_MESSAGE_FROM_SYSTEM = 0x1000
  FORMAT_MESSAGE_IGNORE_INSERTS = 0x200
  class API
    def self.focusTSW()
      if $console === true
        hWnd = $console.hConWin
      elsif $configDlg
        hWnd = $hWndDialog
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
    def self.msgbox(text, flag=MB_ICONASTERISK, api=(ansi=true; MessageBox), title=$appTitle || APP_NAME)
      if IsWindow.call($hWnd || 0).zero?
        hWnd = $hWnd = 0 # if the window has gone, create a system level msgbox
        flag |= MB_TOPMOST
      else
        hWnd = focusTSW() # if there is a popup child, use that as parent window for msgbox
# because if use $hWnd as parent in such cases, the main window will be activated,
# causing a) the popup window losing focus and b) the adverse effect discussed earlier
      end
      title = Str.utf8toWChar(title) unless ansi
      return api.call(hWnd, text, title, flag | MB_SETFOREGROUND)
    end
    unless defined?(self.last_error) # low version win32/api support
      def self.last_error; API.new('GetLastError', 'V', 'I', 'kernel32').call(); end
    end
    def errMsg(errID)
      return "\r\n" if errID.zero?
      langid = $isCHN ? LANG_CHINESE : LANG_ENGLISH
      sublangid = $isCHN ? SUBLANG_CHINESE_SIMPLIFIED : SUBLANG_DEFAULT
      len = FormatMessage.call(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, 0, errID, (sublangid << 10) | langid, $buf, 640, nil) # try chinese or english system error message first according to TSW lang, but Windows doesn't necessarily ship with the DLL required to get error messages in this lang
      len = FormatMessage.call(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, 0, errID, LANG_NEUTRAL, $buf, 640, nil) if len.zero? # then try default language
      return "\r\n" if len.zero?
      return $buf[0, len]
    end
    def call_r(*argv) # provide more info if a win32api returns null
      r = call(*argv)
      return r if $preExitProcessed # do not throw error if ready to exit
      if function_name == 'MsgWaitForMultipleObjects' or function_name == 'SetBkColor' or function_name == 'SetTextColor' or function_name == 'SetDCBrushColor'
        return r if r != -1 # WAIT_FAILED = CLR_INVALID = (DWORD)0xFFFFFFFF
      elsif function_name == 'SendMessageA'
        return r if r != -1 and r != -2 # LB_ERR = -1; LB_ERRSPACE = -2
      else
        return r unless r.zero?
      end
      $str = $isCHN ? Str::StrCN : Str::StrEN
      err = API.last_error
      case function_name
      when 'OpenProcess', 'WriteProcessMemory', 'ReadProcessMemory', 'VirtualAllocEx', 'MsgWaitForMultipleObjects'
        reason = $str::ERR_MSG[2] % $pID
      when 'RegisterHotKey'
        prefix = ['MP', 'CON'][argv[1]]
        reason = $str::ERR_MSG[3] % [$regKeyName[argv[1]], APP_NAME, prefix, prefix, APP_SETTINGS_FNAME]
      when 'ShellExecuteEx'
        buf = argv[0].unpack(SHELLEXECUTEINFO_STRUCT[0..-3]) # discard the last 6 pointers
        reason = $str::ERR_MSG[4] % [buf[4], buf[3], buf[5], buf[8]]
      when /Console/
        reason = $str::ERR_MSG[5]
      else
        reason = $str::ERR_MSG[6]
      end
      argv.collect! {|i| s = i.inspect; s.size > 64 ? (s[0, 60]+' ...$') : s} # trancate too long args
      raise_r(Win32APIError, $str::ERR_MSG[7] % [err, effective_function_name, dll_name, r, errMsg(err), reason, APP_NAME, prototype.join(''), return_type, argv.join(', ')])
    end
  end
end

class TSWKaiError < RuntimeError
end
class Win32APIError < RuntimeError
end

RUBY_HAVE_ENCODING = String.method_defined?(:encoding)
class String  # backward compatibility w/ Ruby < 1.9
  define_method(:ord) { self[0] } unless RUBY_HAVE_ENCODING
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

APP_SETTINGS_FNAME = APP_NAME + 'Option.txt'
APP_ICON_ID = 1 # Icons will be shown in the GUI of this app; this defines the integer identifier of the icon resource in the executable
TSW_CLS_NAME = 'TTSW10'
BASE_ADDRESS = 0x400000
OFFSET_EDIT8 = 0x1c8 # status bar textbox at bottom
OFFSET_HWND = 0xc0
OFFSET_OWNER_HWND = 0x20
OFFSET_CTL_LEFT = 0x24
OFFSET_CTL_TOP = 0x28
OFFSET_CTL_WIDTH = 0x2c
OFFSET_CTL_HEIGHT = 0x30
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

def disposeRes() # when switching to a new TSW process, hDC and hPrc will be regenerated, and the old ones should be disposed of
  $appTitle = nil unless $preExitProcessed # if quitting, no need to change current $appTitle
  if $console === true # hide console on TSW exit
    $console.show(false, false) # when this app exits, even if TSW is still running, no need to do any further treatments
  elsif $configDlg # hide dialog on TSW exit
    Mod.showDialog(false, false) # like above
  end
  HookProcAPI.unhookK
  HookProcAPI.abandon(true)
  if $hBMP
    SelectObject.call($hMemDC, $hBMP0 || 0) # might be an overkill, but just to guarantee no GDI leak
    DeleteObject.call($hBMP)
  end
  DeleteDC.call($hMemDC || 0)
  VirtualFreeEx.call($hPrc || 0, $lpNewAddr || 0, 0, MEM_RELEASE)
  CloseHandle.call($hPrc || 0)
end
def preExit(msg=nil) # finalize
  return if $preExitProcessed # do not exec twice
  $preExitProcessed = true
  begin
    showMsgTxtbox(-1)
    SL.enableAutoSave(false)
    SL.compatibilizeExtSL(false)
    BGM.takeOverBGM(false) # restore
    MPExt.finalize()
    Mod::MOD_PATCH_BYTES_0.reverse_each {|i| WriteProcessMemory.call_r($hPrc, i[0]+BASE_ADDRESS, i[2], i[1], 0)} # restore in reverse order, i.e., restore WndProc first and then erase added function
  rescue Exception
  end
  disposeRes()
  msgboxTxt(msg) if msg
  UnregisterHotKey.call(0, 0)
  UnregisterHotKey.call(0, 1)
  FreeConsole.call() if $_TSWKAI
  DeleteObject.call($hGUIFont2 || 0)
  DeleteObject.call($hPen || 0)
  DeleteObject.call($hPen2 || 0)
  DeleteObject.call($hGUIFont || 0)
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
  checkTSWrects()
end
def initLang()
  if $regKeyName
    getRegKeyName()
    getHookKeyName()
  end
  if $isCHN
    alias :showMsg :showMsgW
    alias :showMsgTxtbox :showMsgTxtboxW
    alias :msgboxTxt :msgboxTxtW
    alias :setTitle :setTitleW
  else
    alias :showMsg :showMsgA
    alias :showMsgTxtbox :showMsgTxtboxA
    alias :msgboxTxt :msgboxTxtA
    alias :setTitle :setTitleA
  end
  setTitle($hWndStatic1, 20)
  setTitle($hWndDialog, 32, $pID)
  (0...MOD_TOTAL_OPTION_COUNT).each {|i| setTitle($hWndChkBoxes[i], 33+i)}
end
def initSettings()
  load(File.exist?(APP_SETTINGS_FNAME) ? APP_SETTINGS_FNAME : File.join(APP_PATH, APP_SETTINGS_FNAME))
rescue Exception
end
def updateSettings()
  mp_m, mp_k = MP_MODIFIER, MP_HOTKEY
  con_m, con_k = CON_MODIFIER, CON_HOTKEY
  initSettings()
  if mp_m != MP_MODIFIER or mp_k != MP_HOTKEY # hotkey changes
    UnregisterHotKey.call(0, 0)
    RegisterHotKey.call_r(0, 0, MP_MODIFIER, MP_HOTKEY)
  end
  if con_m != CON_MODIFIER or con_k != CON_HOTKEY
    UnregisterHotKey.call(0, 1)
    RegisterHotKey.call_r(0, 1, CON_MODIFIER, CON_HOTKEY)
  end
end
def waitForTSW()
  $hWnd = FindWindow.call(TSW_CLS_NAME, nil)
  $tID = GetWindowThreadProcessId.call($hWnd, $bufDWORD)
  $pID = $bufDWORD.unpack('L')[0]
  return if $hWnd.zero? or $pID.zero? or $tID.zero?

  updateSettings()
  AttachThreadInput.call_r(GetCurrentThreadId.call_r(), $tID, 1) # This is necessary for GetFocus to work: 
  #https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getfocus#remarks
  # Also, this is also critical to circumvent the ForegroundLockTimeout (flashing in taskbar but not activated) because now this app is attached to the input of TSW (see: https://devblogs.microsoft.com/oldnewthing/20080801-00/?p=21393)
  $hPrc = OpenProcess.call_r(PROCESS_VM_WRITE | PROCESS_VM_READ | PROCESS_VM_OPERATION | PROCESS_SYNCHRONIZE, 0, $pID)
  $bufHWait[0, POINTER_SIZE] = [$hPrc].pack(HANDLE_STRUCT)

  tApp = readMemoryDWORD(TAPPLICATION_ADDR)
  $hWndTApp = readMemoryDWORD(tApp+OFFSET_OWNER_HWND)
  $TTSW = readMemoryDWORD(TTSW_ADDR)
  return unless (edit8 = waitTillAvail($TTSW+OFFSET_EDIT8))
  return unless ($hWndText = waitTillAvail(edit8+OFFSET_HWND))
  $appTitle = APP_NAME + ' - pID=%d' % $pID
  return true
end
def waitTillAvail(addr) # upon initialization of TSW, some pointers or handles are not ready yet; need to wait
  r = readMemoryDWORD(addr)
  while r.zero?
    case MsgWaitForMultipleObjects.call_r(1, $bufHWait, 0, INTERVAL_TSW_RECHECK, QS_ALLBUTTIMER)
    when 0 # TSW quits during waiting
      disposeRes()
      return
    when 1 # this thread's msg
      checkMsg(false)
    when WAIT_TIMEOUT
      r = readMemoryDWORD(addr)
    end
  end
  return r
end
def waitInit(waitForNextCompatibleTSW = false)
  Static1_Show()
  loop do # waiting while processing messages
    if waitForNextCompatibleTSW # though unlikely, if current TSW is incompatible, wait till its end
      case MsgWaitForMultipleObjects.call_r(1, $bufHWait, 0, -1, QS_ALLBUTTIMER)
      when 0 # incompatible TSW is ended
        CloseHandle.call($hPrc)
        waitForNextCompatibleTSW = false
      when 1 # current thread's msg
        checkMsg(false)
      end
    else
      case MsgWaitForMultipleObjects.call_r(0, nil, 0, INTERVAL_TSW_RECHECK, QS_ALLBUTTIMER)
      when 0
        checkMsg(false)
      when WAIT_TIMEOUT
        res = init()
        break if res
        next if res.nil?
        # though unlikely, if current TSW is incompatible, reshow waiting status window and wait till its end
        if $CONaskOnTSWquit then quit() if msgboxTxt(22, MB_ICONASTERISK|MB_YESNO) == IDNO end
        waitForNextCompatibleTSW = true
        Static1_Show()
      end
    end
  end
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

def getKeyName(modifier, key)
  return nil if key.zero?
  ctrl = !(modifier & 2).zero?
  shift = !(modifier & 4).zero?
  win = !(modifier & 8).zero?
  alt = !(modifier & 1).zero?
  res = ''
  res << 'Ctrl+' if ctrl
  res << 'Shift+' if shift
  res << 'Win+' if win
  res << 'Alt+' if alt
  key = 0 if key > 223
  res << $str::VKEYNAMES[key]
  if $keybdinput_struct.ord.zero? # indicate this needs updating
    $keybdinput_num = 2 # 2 events: key down and key up
    $keybdinput_struct = ''
    if ctrl then $keybdinput_num += 2; $keybdinput_struct << [INPUT_KEYBOARD, VK_CONTROL, 0, 0, 0, 0, 0].pack(INPUT_STRUCT) end
    if shift then $keybdinput_num += 2; $keybdinput_struct << [INPUT_KEYBOARD, VK_SHIFT, 0, 0, 0, 0, 0].pack(INPUT_STRUCT) end
    if win then $keybdinput_num += 2; $keybdinput_struct << [INPUT_KEYBOARD, VK_RWIN, 0, 0, 0, 0, 0].pack(INPUT_STRUCT) end
    if alt then $keybdinput_num += 2; $keybdinput_struct << [INPUT_KEYBOARD, VK_MENU, 0, 0, 0, 0, 0].pack(INPUT_STRUCT) end
    $keybdinput_struct << [INPUT_KEYBOARD, key, 0, 0, 0, 0, 0].pack(INPUT_STRUCT)
    $keybdinput_struct << [INPUT_KEYBOARD, key, 0, KEYEVENTF_KEYUP, 0, 0, 0].pack(INPUT_STRUCT)
    $keybdinput_struct << [INPUT_KEYBOARD, VK_CONTROL, 0, KEYEVENTF_KEYUP, 0, 0, 0].pack(INPUT_STRUCT) if ctrl
    $keybdinput_struct << [INPUT_KEYBOARD, VK_SHIFT, 0, KEYEVENTF_KEYUP, 0, 0, 0].pack(INPUT_STRUCT) if shift
    $keybdinput_struct << [INPUT_KEYBOARD, VK_RWIN, 0, KEYEVENTF_KEYUP, 0, 0, 0].pack(INPUT_STRUCT) if win
    $keybdinput_struct << [INPUT_KEYBOARD, VK_MENU, 0, KEYEVENTF_KEYUP, 0, 0, 0].pack(INPUT_STRUCT) if alt
  end
  return res
end
def getRegKeyName()
  $keybdinput_struct[0] = "\0" # indicate this needs updating
  $regKeyName[0] = getKeyName(MP_MODIFIER, MP_HOTKEY)
  $regKeyName[1] = getKeyName(CON_MODIFIER, CON_HOTKEY)
  $keybdinput_struct[0] = "\xFF" if $keybdinput_struct.ord.zero? # failed (unlikely)
end
