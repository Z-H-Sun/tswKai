require './common'
require './gui'
require './tswKai'

RegisterHotKey = API.new('RegisterHotKey', 'LILL', 'L', 'user32')
UnregisterHotKey = API.new('UnregisterHotKey', 'LI', 'L', 'user32')

INTERVAL_TSW_RECHECK = 500 # in msec: when TSW is not running, check every 500 ms if a new TSW instance has started up
$CONshowStatusTip = true # whether to show status tip window when TSW is not running (true: always show; false: do not show immediately you quit TSW but show upon pressing hotkey; nil: never show)
$CONaskOnTSWquit = true # if on, will ask whether to continue or not once TSW has quitted; if off, always continue

def initLang()
  if $isCHN
    alias :msgboxTxt :msgboxTxtW
    alias :setTitle :setTitleW
  else
    alias :msgboxTxt :msgboxTxtA
    alias :setTitle :setTitleA
  end
end
def initSettings()
  load(File.exist?(APP_SETTINGS_FNAME) ? APP_SETTINGS_FNAME : File.join(APP_PATH, APP_SETTINGS_FNAME))
rescue Exception
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
def init()
  $hWnd = FindWindow.call(TSW_CLS_NAME, 0)
  $tID = GetWindowThreadProcessId.call($hWnd, $buf)
  $pID = $buf.unpack('L')[0]
  return false if $hWnd.zero? or $pID.zero? or $tID.zero?

  initSettings()
  AttachThreadInput.call_r(GetCurrentThreadId.call_r(), $tID, 1) # This is necessary for GetFocus to work: 
  #https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getfocus#remarks
  # Also, this is also critical to circumvent the ForegroundLockTimeout (flashing in taskbar but not activated) because now this app is attached to the input of TSW
  $hPrc = OpenProcess.call_r(PROCESS_VM_WRITE | PROCESS_VM_READ | PROCESS_VM_OPERATION | PROCESS_SYNCHRONIZE, 0, $pID)
  $bufHWait[0, POINTER_SIZE] = [$hPrc].pack(HANDLE_ARRAY_STRUCT)

  tApp = readMemoryDWORD(TAPPLICATION_ADDR)
  $hWndTApp = readMemoryDWORD(tApp+OFFSET_OWNER_HWND)
  $TTSW = readMemoryDWORD(TTSW_ADDR)
  return unless (edit8 = waitTillAvail($TTSW+OFFSET_EDIT8))
  return unless ($hWndText = waitTillAvail(edit8+OFFSET_HWND))

  ShowWindow.call($hWndStatic1, SW_HIDE)
  Str.isCHN()
  initLang()
  $appTitle = 'tswKai3 - pID=%d' % $pID
  $appTitle = Str.utf8toWChar($appTitle) if $isCHN

  checkTSWsize()
  msgboxTxt(11)
  return true
end
def waitInit()
  setTitle($hWndStatic1, 20)
  if $CONshowStatusTip
    ShowWindow.call($hWndStatic1, SW_SHOW)
    SetForegroundWindow.call($hWndStatic1)
  end
  loop do # waiting while processing messages
    case MsgWaitForMultipleObjects.call_r(0, nil, 0, INTERVAL_TSW_RECHECK, QS_ALLBUTTIMER)
    when 0
      checkMsg(false)
    when WAIT_TIMEOUT
      break if init()
    end
  end
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
      # TODO
      when 1
        if state == 1
          KaiMain() # show console
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

CUR_PATH = Dir.pwd
APP_PATH = File.dirname($Exerb ? ExerbRuntime.filepath : __FILE__) # after packed by ExeRB into exe, __FILE__ will be useless
initSettings()
initLang()

RegisterHotKey.call_r(0, 1, CON_MODIFIER, CON_HOTKEY)
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
