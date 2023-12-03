#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# ref: https://github.com/luislavena/win32console

MF_GRAYED = 1
SC_CLOSE = 0xF060
STD_INPUT_HANDLE = -10
STD_OUTPUT_HANDLE = -11
FOREGROUND_BLUE = 1
FOREGROUND_GREEN = 2
FOREGROUND_RED = 4
FOREGROUND_INTENSITY = 8
BACKGROUND_BLUE = 0x10
BACKGROUND_GREEN = 0x20
BACKGROUND_RED = 0x40
BACKGROUND_INTENSITY = 0x80
COMMON_LVB_UNDERSCORE = 0x8000 # warning: COMMON_LVB_* is not yet implemented in Windows Terminal (https://github.com/microsoft/terminal/issues/8037), nor is it supported on or before Win 7 (https://github.com/prompt-toolkit/python-prompt-toolkit/issues/775#issuecomment-436047407)

STYLE_NORMAL = FOREGROUND_BLUE|FOREGROUND_GREEN|FOREGROUND_RED
STYLE_INVERT = BACKGROUND_BLUE|BACKGROUND_GREEN|BACKGROUND_RED
STYLE_CYAN_I = BACKGROUND_GREEN|BACKGROUND_BLUE
STYLE_B_YELLOW_U = FOREGROUND_GREEN|FOREGROUND_RED|FOREGROUND_INTENSITY|COMMON_LVB_UNDERSCORE
STYLE_B_YELLOW = FOREGROUND_GREEN|FOREGROUND_RED|FOREGROUND_INTENSITY
STYLE_B_GREEN = FOREGROUND_GREEN|FOREGROUND_INTENSITY
STYLE_B_RED = FOREGROUND_RED|FOREGROUND_INTENSITY

ENABLE_PROCESSED_OUTPUT = 1
ENABLE_WRAP_AT_EOL_OUTPUT = 2
ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4
KEY_EVENT = 1

GetConsoleWindow = API.new('GetConsoleWindow', 'V', 'L', 'kernel32')
GetSystemMenu = API.new('GetSystemMenu', 'LL', 'L', 'user32')
EnableMenuItem = API.new('EnableMenuItem', 'LLL', 'L', 'user32')

GetStdHandle = API.new('GetStdHandle', 'I', 'L', 'kernel32')
AllocConsole = API.new('AllocConsole', 'V', 'L', 'kernel32')
FreeConsole = API.new('FreeConsole', 'V', 'L', 'kernel32')
SetConsoleScreenBufferSize = API.new('SetConsoleScreenBufferSize', 'LL', 'L', 'kernel32')
SetConsoleWindowInfo = API.new('SetConsoleWindowInfo', 'LLS', 'L', 'kernel32')
SetConsoleCtrlHandler = API.new('SetConsoleCtrlHandler', 'PL', 'L', 'kernel32')
SetConsoleTitle = API.new('SetConsoleTitleA', 'S', 'L', 'kernel32')
SetConsoleTitleW = API.new('SetConsoleTitleW', 'S', 'L', 'kernel32')
SetConsoleMode = API.new('SetConsoleMode','LL','L','kernel32')

ReadConsole = API.new('ReadConsole', 'LPLPL', 'L', 'kernel32')
ReadConsoleInput = API.new('ReadConsoleInput', 'LPLP', 'L', 'kernel32')
PeekConsoleInput = API.new('PeekConsoleInput', 'LPLP', 'L', 'kernel32')
WriteConsole = API.new('WriteConsoleA', 'LSIPL', 'L', 'kernel32')
WriteConsoleW = API.new('WriteConsoleW', 'LSIPL', 'L', 'kernel32')
WriteConsoleOutput = API.new('WriteConsoleOutput', 'LSLLP', 'L', 'kernel32')
WriteConsoleOutputCharacter = API.new('WriteConsoleOutputCharacterA', 'LSLLP', 'L', 'kernel32')
WriteConsoleOutputCharacterW = API.new('WriteConsoleOutputCharacterW', 'LSLLP', 'L', 'kernel32')
WriteConsoleOutputAttribute = API.new('WriteConsoleOutputAttribute', 'LSLLP', 'L', 'kernel32')
SetConsoleTextAttribute = API.new('SetConsoleTextAttribute', 'LL', 'L', 'kernel32')
FlushConsoleInputBuffer = API.new('FlushConsoleInputBuffer', 'L', 'L', 'kernel32')
FillConsoleOutputCharacter = API.new('FillConsoleOutputCharacter', 'LILLP', 'L', 'kernel32')
FillConsoleOutputAttribute = API.new('FillConsoleOutputAttribute', 'LILLP', 'L', 'kernel32')
SetConsoleCursorPosition = API.new('SetConsoleCursorPosition', 'LL', 'L', 'kernel32')
GetConsoleScreenBufferInfo = API.new('GetConsoleScreenBufferInfo', 'LP', 'L', 'kernel32')
SetConsoleCursorInfo = API.new('SetConsoleCursorInfo', 'LP', 'L', 'kernel32')

ClientToScreen = API.new('ClientToScreen', 'LP', 'L', 'user32')
ShowScrollBar = API.new('ShowScrollBar', 'LII', 'L', 'user32')
SB_BOTH = 3

class TSWQuitedError < TSWKaiError
end

class Console
  class STDINTimeoutError < TSWKaiError
  end

  attr_reader :hConIn
  attr_reader :hConOut
  attr_reader :hConWin
  attr_reader :conWidth
  attr_reader :conHeight
  attr_accessor :active
  EMPTY_EVENT_ARRAY = [{}]
  BUFFER_EVENT_SIZE = 16
  BUFFER_SIZE = 20*BUFFER_EVENT_SIZE # enough in this application
  def initialize(conWidth=60, conHeight=15)
    if (@hConWin = GetConsoleWindow.call).zero?
      AllocConsole.call_r
      @hConWin = GetConsoleWindow.call
    end
    @hConIn = GetStdHandle.call_r(STD_INPUT_HANDLE)
    @hConOut = GetStdHandle.call_r(STD_OUTPUT_HANDLE)
    $bufHWait[POINTER_SIZE, POINTER_SIZE] = [@hConIn].pack(HANDLE_ARRAY_STRUCT) # $bufHWait: [0] is $hPrc; [1] is @hConIn

    @conWidth, @conHeight = conWidth, conHeight
    @conSize = @conWidth*@conHeight
    @active = false
    @lastIsCHN = nil # depending on whether the language is changed, the interface may need reloading
    SetConsoleMode.call(@hConOut, ENABLE_PROCESSED_OUTPUT|ENABLE_WRAP_AT_EOL_OUTPUT|ENABLE_VIRTUAL_TERMINAL_PROCESSING) # Virtual Terminal mode is important for modern console (https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences)
    SetConsoleCtrlHandler.call(nil, 1) # depress Ctrl-C

    SetConsoleScreenBufferSize.call(@hConOut, packS2(1024, 1024)) # win size must be <= buffer size, so first set a very large buf size to make sure set_win_size works
    SetConsoleWindowInfo.call(@hConOut, 1, [0, 0, conWidth-1, conHeight-1].pack('S4')) # -1 is necessary because the last row/col is included
    SetConsoleScreenBufferSize.call(@hConOut, packS2(conWidth, conHeight))
    # remember to call self.setConWinProp somewhere later
  end
  def ===(activated) # if the activated state is the same (true=true; false=false; false=nil)
    return !(@active ^ activated)
  end
  def switchLang()
    if $isCHN
      alias :title :titleW
      alias :print :printW
      alias :print_pos :print_posW
      isCHN = true # redefine: 1 or true ==> true
    else
      alias :title :titleA
      alias :print :printA
      alias :print_pos :print_posA
      isCHN = false # redefine: nil or false ==> false
    end
    return false if @lastIsCHN == isCHN # no need to reload interface
    @lastIsCHN = isCHN
    return true # need to reload interface
  end
  def setConWinProp()
    title($str::STRINGS[30], $pID)
    ShowScrollBar.call_r(@hConWin, SB_BOTH, 0) # sometimes, even if window size == buffer size, scroll bars will unexpectedly show up, blocking part of texts, which is very annoying
    stl = GetWindowLong.call(@hConWin, GWL_STYLE)
#   exstl = GetWindowLong.call(@hConWin, GWL_EXSTYLE)
    hConMenu = GetSystemMenu.call(@hConWin, 0)
    EnableMenuItem.call(hConMenu, SC_CLOSE, MF_GRAYED) # disable close
#   SetWindowLong.call(@hConWin, GWL_HWNDOWNER, $hWndTApp) # make TSW the owner of the console window so the console can be hidden from the taskbar (caveat: XP won't work for console win)
#   SetWindowLong.call(@hConWin, GWL_EXSTYLE, exstl & ~ WS_EX_APPWINDOW).zero? # hide from taskbar for owned window (caveat: XP won't work for console win)
    SetWindowLong.call(@hConWin, GWL_STYLE, stl & ~ WS_ALLRESIZE | WS_MINIMIZEBOX).zero? # disable resize/maximize (caveat: XP won't work for console win)
  end
  def show(active, tswActive=true) # active=true/false : show/hide console window; tswActive: if TSW is still running, determining whether to do further operations
    return if self === active
    if active
      API.focusTSW()
      @active = true
      ShowWindow.call(@hConWin, SW_RESTORE)
      SetForegroundWindow.call(@hConWin)
      return unless tswActive
      IsWindow.call_r($hWnd)
      checkTSWsize()
      xy = [$MAP_LEFT, $MAP_TOP].pack('l2')
      ClientToScreen.call_r($hWnd, xy)
      x, y = xy.unpack('l2')
      SetWindowPos.call(@hConWin, 0, x, y, 0, 0, SWP_NOSIZE|SWP_FRAMECHANGED)
    else
      @active = false
      ShowWindow.call(@hConWin, SW_HIDE)
      unless tswActive
#       SetWindowLong.call(@hConWin, GWL_HWNDOWNER, 0)
        return
      end
      IsWindow.call_r($hWnd)
      API.focusTSW()
    end
  end
  def titleA(title, *argv)
    SetConsoleTitle.call(title % argv)
  end
  def titleW(title, *argv)
    SetConsoleTitleW.call(Str.utf8toWChar(title % argv))
  end
  def gets(strip=true)
    ReadConsole.call_r(@hConIn, $buf, BUFFER_SIZE, $bufDWORD, 0)
    bytesRead = $bufDWORD.unpack('L')[0]
    return nil if bytesRead.zero?
    res = $buf[0, bytesRead]
    res.rstrip! if strip # note: usually there will be \r\n at the end
    return res
  end
  def printA(s, *argv) # high-level print, matching with SetConsoleTextAttribute
    s = strf(s, *argv)
    WriteConsole.call_r(@hConOut, s, s.size, $bufDWORD, 0)
  end
  def printW(s, *argv)
    s = strf(s, *argv).unpack('U*').pack('S*')
    WriteConsoleW.call_r(@hConOut, s, s.size >> 1, $bufDWORD, 0)
  end
  def p_rect(x, y, w, h, str, attr)
    suffix = [0, attr].pack('CS') # the first \0 is to convert ASCII to UTF-16
    buf = str.scan(/./).join(suffix)+suffix
    WriteConsoleOutput.call_r(@hConOut, buf, packS2(w, h), 0, [x,y,x+w-1,y+h-1].pack('S4')) # -1 is necessary because the last row/col is included
  end
  def cls(clearAttr=true)
    FillConsoleOutputCharacter.call_r(@hConOut, VK_SPACE, @conSize, 0, $bufDWORD)
    FillConsoleOutputAttribute.call_r(@hConOut, STYLE_NORMAL, @conSize, 0, $bufDWORD) if clearAttr
    cursor(0, 0)
  end
  def cls_pos(x, y, len, clearAttr=true)
    FillConsoleOutputCharacter.call_r(@hConOut, VK_SPACE, len, packS2(x, y), $bufDWORD)
    FillConsoleOutputAttribute.call_r(@hConOut, STYLE_NORMAL, len, packS2(x, y), $bufDWORD) if clearAttr
    cursor(0, 0)
  end
  def cursor(x, y)
    SetConsoleCursorPosition.call_r(@hConOut, packS2(x, y))
  end
  def get_cursor()
    buf = "\0"*22
    GetConsoleScreenBufferInfo.call_r(@hConOut, buf)
    return buf.unpack('SSSSSssssSS')[2, 2]
  end
  def show_cursor(visible, size=100)
    visible = (visible ? 1 : 0) unless visible.is_a?(Integer)
    SetConsoleCursorInfo.call_r(@hConOut, [size, visible].pack('L2'))
  end
  def attr(attribute)
    SetConsoleTextAttribute.call_r(@hConOut, attribute)
  end
  def fprint(attribute, s, *argv)
    attr(attribute)
    self.print(s, *argv)
    attr(STYLE_NORMAL)
  end
  def print_posA(x, y, s, *argv) # low-level print, matching WriteConsoleOutputAttribute
    s = strf(s, *argv)
    WriteConsoleOutputCharacter.call_r(@hConOut, s, s.size, packS2(x, y), $bufDWORD)
  end
  def print_posW(x, y, s, *argv)
    s = strf(s, *argv).unpack('U*').pack('S*')
    WriteConsoleOutputCharacterW.call_r(@hConOut, s, s.size >> 1, packS2(x, y), $bufDWORD)
  end
  def attr_pos(x, y, attribute, len)
    FillConsoleOutputAttribute.call(@hConOut, attribute, len, packS2(x, y), $bufDWORD)
  end
  def pause(prompt=nil)
    self.print(prompt) if prompt
    show_cursor(true)
    while !(get_input[0]['char'])
    end
  end
  def choice(choices, allowESC=true) # String or Array; should be all capitalized
    i = -1
    loop do
      c = get_input[0]['char']
      next if c.nil?
      if allowESC and c == VK_ESCAPE
        i = -1; break
      end
      i = choices.index(c.chr.upcase)
      break unless i.nil?
      beep(MB_ICONERROR)
    end
    beep(); return i
  end
  def get_num(digits) #TODO: support of arrow key
    digitCount = 0
    str = ''
    x, y = get_cursor()
    while digitCount < digits
      print_posA(x, y, ' ') # clear the original text at the cursor pos
      for c in get_input
        ord = c['char']
        next if ord.nil?
        break unless digitCount < digits
        char = ord.chr
        count = c['repeat']
        case ord
        when VK_ESCAPE # esc
          return -1
        when 0x30..0x39 # num
          count = digits - digitCount if count > digits - digitCount
          str += char*count
          self.printA char*count
          x += count
          digitCount += count
        when VK_BACK # backspace
          next if digitCount.zero?
          count = digitCount if count > digitCount
          x -= count
          cursor(x, y) # move cursor
          print_posA(x, y, ' '*count) # clear deleted text
          digitCount -= count
          str = str[0, digitCount]
        when VK_RETURN, VK_SPACE # space/enter
          return str.to_i
        else
          beep(MB_ICONERROR)
        end
      end
    end
    return str.to_i
  ensure # always beep
    beep()
    #self.puts # new line
  end
  def beep(msg=MB_ICONASTERISK)
    MessageBeep.call(msg)
  end

  private
  def packS2(s1, s2)
    return s1 | (s2 << 16)
  end
  def strf(s, *argv)
    s = s.inspect unless s.is_a?(String)
    return s % argv
  end
  def get_input(timeout=-1)
    case MsgWaitForMultipleObjects.call_r(2, $bufHWait, 0, timeout, QS_HOTKEY)
    when 0 # TSW has quitted
      raise TSWQuitedError
    when 1 # console input
    when 2 # main thread loop messages (hotkeys)
      while !PeekMessage.call($buf, 0, 0, 0, 1).zero?
# TODO
      end
      return EMPTY_EVENT_ARRAY
    when WAIT_TIMEOUT
      raise STDINTimeoutError
    end

    PeekConsoleInput.call_r(@hConIn, $buf, BUFFER_EVENT_SIZE, $bufDWORD)
    eventCount = $bufDWORD.unpack('L')[0]
    return EMPTY_EVENT_ARRAY if eventCount.zero?
    FlushConsoleInputBuffer.call(@hConIn) # discard excess input
    res = Array.new(eventCount) { Hash.new }
    for i in 0...eventCount
      event = $buf[20*i, 20].unpack('S2LS4L') # eventtype align keydown? repeat# vkey scancode chr controlkey
      next if event[0] != KEY_EVENT
      next if event[2].zero? # ignore keyup
      next if event[6] > 127 # allow ascii only
      res[i]['repeat'] = event[3]
      res[i]['vKey'] = event[4]
      res[i]['char'] = event[6]
      res[i]['ctrl'] = event[7]
    end
    return res
  end
end
