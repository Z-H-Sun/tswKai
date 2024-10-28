#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# ref: https://github.com/luislavena/win32console

$CONenableSoundEffect = true

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
COMMON_LVB_GRID_HORIZONTAL = 0x400
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
ENABLE_LVB_GRID_WORLDWIDE = 16 # this supposedly solve the COMMON_LVB_* issue mentioned above, even on a non-DBCS code page (https://learn.microsoft.com/en-us/windows/console/getconsolemode); however, this does not seem to work in my tests on Windows 7 (en-US locale)
CP_GB2312 = 936
KEY_EVENT = 1

GetConsoleWindow = API.new('GetConsoleWindow', 'V', 'L', 'kernel32')
GetSystemMenu = API.new('GetSystemMenu', 'LL', 'L', 'user32')
DeleteMenu = API.new('DeleteMenu', 'LLL', 'L', 'user32')

GetStdHandle = API.new('GetStdHandle', 'I', 'L', 'kernel32')
AllocConsole = API.new('AllocConsole', 'V', 'L', 'kernel32')
FreeConsole = API.new('FreeConsole', 'V', 'L', 'kernel32')
GetLargestConsoleWindowSize = API.new('GetLargestConsoleWindowSize', 'L', 'I', 'kernel32')
SetConsoleScreenBufferSize = API.new('SetConsoleScreenBufferSize', 'LL', 'L', 'kernel32')
SetConsoleWindowInfo = API.new('SetConsoleWindowInfo', 'LLS', 'L', 'kernel32')
SetConsoleCtrlHandler = API.new('SetConsoleCtrlHandler', 'PL', 'L', 'kernel32')
SetConsoleTitle = API.new('SetConsoleTitleA', 'S', 'L', 'kernel32')
SetConsoleTitleW = API.new('SetConsoleTitleW', 'S', 'L', 'kernel32')
SetConsoleMode = API.new('SetConsoleMode','LL','L','kernel32')
SetConsoleOutputCP = API.new('SetConsoleOutputCP', 'I', 'I', 'kernel32')
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

ShowScrollBar = API.new('ShowScrollBar', 'LII', 'L', 'user32')
SB_BOTH = 3

class TSWQuitedError < TSWKaiError
end

class Console
  class STDINTimeoutError < TSWKaiError
  end
  class STDINCancelError < TSWKaiError # arrow key pressed
    attr_reader :arrow
    def initialize(msg) # raise(STDINCancelError, <arrow>)
      @arrow = msg
      super(nil)
    end
  end

  class SoundEffect
    MidiOutOpen = API.new('midiOutOpen', 'PILLI', 'I', 'winmm')
    MidiOutSetVolume = API.new('midiOutSetVolume', 'LI', 'I', 'winmm')
    MidiOutShortMsg = API.new('midiOutShortMsg', 'LI', 'I', 'winmm')
    MidiOutReset = API.new('midiOutReset', 'L', 'I', 'winmm')
    MidiOutClose = API.new('midiOutClose', 'L', 'I', 'winmm')

    CALLBACK_NULL = 0
    # https://midi.org/summary-of-midi-1-0-messages
    MIDI_STATUS_NOTE_OFF = 0b1000
    MIDI_STATUS_NOTE_ON = 0b1001
    MIDI_STATUS_CONTROL_CHANGE = 0b1011
    MIDI_STATUS_PROGRAM_CHANGE = 0b1100
    # https://midi.org/midi-1-0-control-change-messages
    MIDI_CONTROL_CHANNEL_VOLUME = 7 # this sets the MSB (coarse adjustment); the controller number for volume LSB (fine adjustment) is 39, but is usually ignored (as 128 different values for volume, 0-0x7F, is enough; 128^2 choices are really unnecessary)
    MIDI_CONTROL_ALL_SOUNDS_OFF = 120
    # https://web.archive.org/web/20230716043455/https://www.midi.org/specifications-old/item/gm-level-1-sound-set
    # https://en.wikipedia.org/wiki/General_MIDI
    MIDI_PROGRAM_SEASHORE = 122
    MIDI_PROGRAM_BREATHNOISE = 121
    MIDI_PROGRAM_GUNSHOT = 127
    MIDI_PITCH_TAMBOURINE = 54
    MIDI_PITCH_CRASHCYMBAL2 = 57
    MIDI_PITCH_SHORTGUIRO = 73

    MIDI_DEVICE_ID = 0 # typically, Windows default MIDI synth (Microsoft GS Wavetable Synth)
    MIDI_GLOBAL_VOLUME = -1  # 0xFFFF means largest possible volume for left/right channel; MAKELONG(0xFFFF, 0xFFFF) = 0xFFFFFFFF = (DWORD)-1
    MIDI_CHANNEL_VOLUME = 0x7F # 0-0x7F for each MIDI channel
    @hMIDIout = nil
    def initialize()
      return unless MidiOutOpen.call($buf, MIDI_DEVICE_ID, 0, 0, CALLBACK_NULL).zero? # MMSYSERR_NOERROR = 0; otherwise, failed
      @hMIDIout = $buf.unpack(HANDLE_STRUCT)[0]

      # maximize volume
      MidiOutSetVolume.call(@hMIDIout, MIDI_GLOBAL_VOLUME)
      sendMIDImsg(0, MIDI_STATUS_CONTROL_CHANGE, MIDI_CONTROL_CHANNEL_VOLUME, MIDI_CHANNEL_VOLUME)
      sendMIDImsg(0, MIDI_STATUS_PROGRAM_CHANGE, MIDI_PROGRAM_BREATHNOISE)
      sendMIDImsg(1, MIDI_STATUS_CONTROL_CHANGE, MIDI_CONTROL_CHANNEL_VOLUME, MIDI_CHANNEL_VOLUME)
      sendMIDImsg(1, MIDI_STATUS_PROGRAM_CHANGE, MIDI_PROGRAM_GUNSHOT)
      sendMIDImsg(2, MIDI_STATUS_CONTROL_CHANGE, MIDI_CONTROL_CHANNEL_VOLUME, MIDI_CHANNEL_VOLUME)
      sendMIDImsg(2, MIDI_STATUS_PROGRAM_CHANGE, MIDI_PROGRAM_SEASHORE)
    end
    def dispose()
      return unless @hMIDIout
      MidiOutReset.call(@hMIDIout)
      MidiOutClose.call(@hMIDIout)
    end

    def selection() # selection sound effect (mimic using "breath noise")
      return unless @hMIDIout and $CONenableSoundEffect
      sendMIDImsg(0, MIDI_STATUS_CONTROL_CHANGE, MIDI_CONTROL_ALL_SOUNDS_OFF) # mute previous SE
      sendMIDImsg(0, MIDI_STATUS_NOTE_ON, 0x60, 0x7F) # byte1=pitch; byte2=volume
      sendMIDImsg(0, MIDI_STATUS_NOTE_ON, 0x40, 0x7F)
      sendMIDImsg(0, MIDI_STATUS_NOTE_ON, 0x20, 0x7F)
    end
    def cancellation() # cancellation sound effect (mimic using "short guiro")
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_SHORTGUIRO, 0x6A) if @hMIDIout and $CONenableSoundEffect # channel 9 is reserved for percussion instruments
    end
    def explosion() # explosion sound effect (mimic using "gun shot")
      return unless @hMIDIout and $CONenableSoundEffect
      sendMIDImsg(1, MIDI_STATUS_CONTROL_CHANGE, MIDI_CONTROL_ALL_SOUNDS_OFF)
      sendMIDImsg(1, MIDI_STATUS_NOTE_ON, 0x35, 0x48)
      sendMIDImsg(1, MIDI_STATUS_NOTE_ON, 0x30, 0x64)
      sendMIDImsg(1, MIDI_STATUS_NOTE_ON, 0x20, 0x7F)
    ensure
      sleep(1)
    end
    def deletion() # deletion sound effect (mimic using "sea shore")
      return sleep(1) unless @hMIDIout and $CONenableSoundEffect
      sendMIDImsg(2, MIDI_STATUS_NOTE_ON, 0x60, 0x7F); sleep(1)
      sendMIDImsg(2, MIDI_STATUS_CONTROL_CHANGE, MIDI_CONTROL_ALL_SOUNDS_OFF)
    end
    def transaction() # transaction sound effect (mimic using "tambourine")
      return sleep(1.5) unless @hMIDIout and $CONenableSoundEffect
      sendMIDImsg(9, MIDI_STATUS_CONTROL_CHANGE, MIDI_CONTROL_ALL_SOUNDS_OFF)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.15)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.10)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.05)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.05)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.05)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_CRASHCYMBAL2, 0x60)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.03)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.02)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(0.01)
      sendMIDImsg(9, MIDI_STATUS_NOTE_ON, MIDI_PITCH_TAMBOURINE, 0x7F); sleep(1)
    end

    private
    def sendMIDImsg(channel, status, byte1, byte2=0)
      MidiOutShortMsg.call(@hMIDIout, channel | (status << 4) | (byte1 << 8) | (byte2 << 16))
    end
  end

  attr_reader :hConIn
  attr_reader :hConOut
  attr_reader :hConWin
  attr_reader :conWidth
  attr_reader :conHeight
  attr_reader :SE
  attr_accessor :need_free
  attr_accessor :active
  EMPTY_EVENT_ARRAY = [{}]
  BUFFER_EVENT_SIZE = 16
  BUFFER_SIZE = 20*BUFFER_EVENT_SIZE # enough in this application
  CONSOLE_WIDTH = 60
  CONSOLE_HEIGHT = 16
  def initialize(conWidth=CONSOLE_WIDTH, conHeight=CONSOLE_HEIGHT)
    if (@hConWin = GetConsoleWindow.call).zero?
      AllocConsole.call_r
      @hConWin = GetConsoleWindow.call
    end
    @hConIn = GetStdHandle.call_r(STD_INPUT_HANDLE)
    @hConOut = GetStdHandle.call_r(STD_OUTPUT_HANDLE)
    $bufHWait[POINTER_SIZE, POINTER_SIZE] = [@hConIn].pack(HANDLE_STRUCT) # $bufHWait: [0] is $hPrc; [1] is @hConIn

    @conWidth, @conHeight = conWidth, conHeight
    @conSize = @conWidth*@conHeight
    @active = false
    @lastIsCHN = nil # depending on whether the language is changed, the interface may need reloading
    @need_free = true

    SetConsoleMode.call(@hConOut, ENABLE_PROCESSED_OUTPUT|ENABLE_WRAP_AT_EOL_OUTPUT|ENABLE_VIRTUAL_TERMINAL_PROCESSING|ENABLE_LVB_GRID_WORLDWIDE) # Virtual Terminal mode is important for modern console (https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences)
    SetConsoleOutputCP.call(CP_GB2312) # specify code page 936 to make sure correct display of Chinese characters, as well as underlines (as mentioned above on line 34, underlines won't show in latin code pages, so this is beneficial even for pure English interface)
    SetConsoleCtrlHandler.call_r(nil, 1) # depress Ctrl-C [Ideally, Ctrl-Break and Close signals should also be handled by passing a callback function address here rather than NULL; however, there is a bug with win32/api that will lead to stack overflow (cause not yet clear). As a result, I will leave NULL here, but do some monkey patching in the C code of win32/api extension so as to implement the callback function there; see vendor/win32/api.c]

    @SE = SoundEffect.new()
    # remember to call self.resize and self.setConWinProp somewhere later
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
  def setConWinProp(isKai)
    title($str::STRINGS[isKai ? 30 : 50], $pID)
    ShowScrollBar.call_r(@hConWin, SB_BOTH, 0) # sometimes, even if window size == buffer size, scroll bars will unexpectedly show up, blocking part of texts, which is very annoying
    stl = GetWindowLong.call(@hConWin, GWL_STYLE)
    exstl = GetWindowLong.call(@hConWin, GWL_EXSTYLE)
    hConMenu = GetSystemMenu.call(@hConWin, 0)
    DeleteMenu.call(hConMenu, SC_CLOSE, 0) # disable close (For Windows XP and 7, graying out the close sysmenu of a console window by using EnableMenuItem can be counteracted by the system! DeleteMenu is safer)
    SetWindowLong.call(@hConWin, GWL_HWNDOWNER, $hWndTApp) # make TSW the owner of the console window so the console can be hidden from the taskbar (caveat: XP won't work for console win)
# note: this will be executed everytime the console window is shown, which can revert the effect of `SetWindowLong.call(@hConWin, GWL_HWNDOWNER, 0)` in Line 192
# also, I tried setting the owner window to $hWndDialogParent, but then the app will easily freeze, maybe because potential conflicts with the current message loop? So $hWndTApp is the next available convenient owner
    SetWindowLong.call(@hConWin, GWL_EXSTYLE, exstl & ~ WS_EX_APPWINDOW) # hide from taskbar for owned window (caveat: XP won't work for console win)
    SetWindowLong.call(@hConWin, GWL_STYLE, stl & ~ WS_ALLRESIZE) # disable resize/maximize/minimize (caveat: XP won't work for console win)
  end
  def resize(w=@conWidth, h=@conHeight) # the effect of this function is equivalent to `system("mode con: cols=#{w} lines=#{h}")`
# this implementation of this function is through reverse engineering Windows OS' `mode.com` and `ulib.dll`
# mode.com#main -> GetRequest -> ConLine -> ConRc -> MakeRequest --> ConHandler -> ConSetRolCol --> ulib.com#ChangeScreenSize
# see also: https://github.com/tongzx/nt5src/blob/master/Source/XPSP1/NT/base/fs/utils/ulib/src/screen.cxx#L211-L375
    GetConsoleScreenBufferInfo.call_r(@hConOut, $buf)
    b_w, b_h, c_x, c_y, a, w_l, w_t, w_r, w_b, max_w_w, max_w_h = $buf.unpack('s11')
    w_w = w_r - w_l + 1
    w_h = w_b - w_t + 1
    return 0 if w_w == w and w_h == h and b_w == w and b_h == h

    coord = GetLargestConsoleWindowSize.call(@hConOut)
    return if coord.zero? # for legacy console, this call (as well as SetConsoleWindowInfo/SetConsoleScreenBufferSize) may fail in the full screen mode, and GetLastError will return ERROR_FULLSCREEN_MODE, but there's nothing we can do about it
    max_s_w = coord & 0xFFFF
    max_s_h = coord >> 16 & 0xFFFF
    @conWidth = w; @conHeight = h # update class variables

    if (w < w_w) or (h < w_h) # If the desired window size is smaller than the current window size, we have to resize the current window first. (The buffer size cannot be smaller than the window size)
      max_w = [w, b_w, max_s_w].min
      max_h = [h, b_h, max_s_h].min # Set the window to a size that will fit in the current screen buffer and that is no bigger than the size to which we want to grow the screen buffer or the largest window size
      return if SetConsoleWindowInfo.call(@hConOut, 1, [0, 0, max_w-1, max_h-1].pack('S4')).zero? # -1 is necessary because the last row/col is included
    end
    return if SetConsoleScreenBufferSize.call(@hConOut, packS2(w, h)).zero?
    w = max_s_w if w > max_s_w
    h = max_s_h if h > max_s_h
    return !SetConsoleWindowInfo.call(@hConOut, 1, [0, 0, w-1, h-1].pack('S4')).zero?
  end
  def show(active, tswActive=true) # active=true/false : show/hide console window; tswActive: if TSW is still running, determining whether to do further operations
    return false if self === active
    if active
      if tswActive and API.focusTSW() != $hWnd # has popup child
        msgboxTxt(28, MB_ICONASTERISK); return nil # fail
      end
      HookProcAPI.unhookK # no need for tswMP hook now; especially, console loop can cause significant delay when working in combination with hook; will reinstall later
      @active = true
      ShowWindow.call(@hConWin, SW_RESTORE)
      SetForegroundWindow.call(@hConWin)
      return true unless tswActive
      IsWindow.call_r($hWnd)
      checkTSWsize()
      xy = [$MAP_LEFT, $MAP_TOP].pack('l2')
      ClientToScreen.call_r($hWnd, xy)
      x, y = xy.unpack('l2')
      SetWindowPos.call_r(@hConWin, 0, x, y, 0, 0, SWP_NOSIZE|SWP_FRAMECHANGED)
      EnableWindow.call($hWnd, 0) # disable TSW
      writeMemoryDWORD(Mod::MOD_FOCUS_HWND_ADDR, @hConWin) # tell TSW to set focus to this window when switched to or clicked on (see Entry #-1 of tswMod.asm)
    else
      writeMemoryDWORD(Mod::MOD_FOCUS_HWND_ADDR, 0) if tswActive # revert the above operation
      SetWindowLong.call(@hConWin, GWL_HWNDOWNER, 0) # apparently on Windows, it is not allowed to "steel focus" by `SetForegroundWindow` to self (the window will not be switched to but only flashed) although you can `SetForegroundWindow` to other windows. More specifically, the object of `SetForegroundWindow` should have a different owner window. Since previously, we set the owner window of the console window to be TSW's hWndTApp, we will not be able to successfully gain focus according to this theory; therefore, we should now detach the console window from hWndTApp
      @active = false
      EnableWindow.call($hWnd, 1) # re-enable TSW
      ShowWindow.call(@hConWin, SW_HIDE)
      return true unless tswActive
      IsWindow.call_r($hWnd)
# previously was `API.focusTSW()`, now replaced by the two lines below
      ShowWindow.call($hWndTApp, SW_SHOW)
      SetForegroundWindow.call($hWnd)
# but that wouldn't work properly, because the `GetLastActivePopup` call would return @hConWin, not $hWnd
      HookProcAPI.hookK() # reenable tswMP hook
    end
    return true
  end
  def titleA(title, *argv)
    SetConsoleTitle.call_r(title % argv)
  end
  def titleW(title, *argv)
    SetConsoleTitleW.call_r(Str.utf8toWChar(title % argv))
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
  def p_rect(x, y, w, h, str, attr) # `attr` can be a WORD array specifying the attribute for each char in `str`; it can also be a single WORD value, indicating each char has the same attribute
    bytes = str.unpack('C*') # each byte will be converted to a WORD later (ASCII to UTF-16)
    attr = Array.new(bytes.size, attr) unless attr.is_a?(Array)
    buf = bytes.zip(attr).flatten.pack('S*')
    WriteConsoleOutput.call_r(@hConOut, buf, packS2(w, h), 0, [x,y,x+w-1,y+h-1].pack('S4')) # -1 is necessary because the last row/col is included
  end
  def cls(clearAttr=true)
    FillConsoleOutputCharacter.call_r(@hConOut, VK_SPACE, @conSize, 0, $bufDWORD)
    FillConsoleOutputAttribute.call_r(@hConOut, STYLE_NORMAL, @conSize, 0, $bufDWORD) if clearAttr
    cursor(0, 0)
  end
  def cls_pos(x, y, len, clearAttr=true, char=VK_SPACE)
    FillConsoleOutputCharacter.call_r(@hConOut, char, len, packS2(x, y), $bufDWORD)
    FillConsoleOutputAttribute.call_r(@hConOut, STYLE_NORMAL, len, packS2(x, y), $bufDWORD) if clearAttr
  end
  def cursor(x, y)
    SetConsoleCursorPosition.call_r(@hConOut, packS2(x, y))
  end
  def get_cursor()
    GetConsoleScreenBufferInfo.call_r(@hConOut, $buf)
    return $buf.unpack('SSSSSssssSS')[2, 2]
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
    FillConsoleOutputAttribute.call_r(@hConOut, attribute, len, packS2(x, y), $bufDWORD)
  end
  def pause(prompt=nil)
    self.print(prompt) if prompt
    show_cursor(true)
    while !(c=get_input[0]['char'])
    end
    return c
  end
  def choice(choices, beepOnEnd=true, allowESC=true) # String or Array; should be all capitalized
    i = -1
    loop do
      c = get_input[0]['char']
      next if c.nil?
      if allowESC and (c == VK_ESCAPE or c == VK_RETURN or c == VK_SPACE) then $console.SE.cancellation(); return -1 end
      i = choices.index(c.chr.upcase)
      break unless i.nil?
      beep(MB_ICONERROR)
    end
    beep() if beepOnEnd
    return i
  end
  def choice_num(start, last, beepOnEnd=true) # allow numberic input between `start` and `last` (included) (if `last` >= 10, will allow input of 'Aa'-'Ff')
    i = -1
    loop do
      c = get_input[0]['char']
      next if c.nil?
      if c == VK_ESCAPE or c == VK_RETURN or c == VK_SPACE then $console.SE.cancellation(); return -1 end
      i = c-0x30
      if last > 9
        if i > 48 then i -= 39 # 'a', 'b', ...
        elsif i > 16 then i -= 7 end # 'A', 'B', ...
      end
      break if i>=start and i<=last
      beep(MB_ICONERROR)
    end
    beep() if beepOnEnd
    return i
  end
  def get_num(digits, beepOnEnd=true)
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
          $console.SE.cancellation()
          return -1
        when 0x30..0x39 # num
          count = digits - digitCount if count > digits - digitCount
          char *= count if count > 1
          str << char
          self.printA char
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
          if str.empty? then $console.SE.cancellation(); return -1 end # empty input; cancel
          beep() if beepOnEnd
          return str.to_i
        else
          beep(MB_ICONERROR)
        end
      end
    end
    beep() if beepOnEnd
    return str.to_i
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
  def get_input(timeout=-1) # -1 means no timeout
    case MsgWaitForMultipleObjects.call_r(2, $bufHWait, 0, timeout, QS_HOTKEY | QS_POSTMESSAGE)
    when 0 # TSW has quitted
      raise TSWQuitedError
    when 1 # console input
    when 2 # main thread loop messages (hotkeys)
      checkMsg(2)
      return EMPTY_EVENT_ARRAY
    when WAIT_TIMEOUT
      raise STDINTimeoutError
    end

    resize() # in case the windows size is changed
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
      raise(STDINCancelError, event[4]) if event[4] >= VK_LEFT and event[4] <= VK_DOWN # arrow key

      res[i]['repeat'] = event[3]
      res[i]['vKey'] = event[4]
      res[i]['char'] = event[6]
      res[i]['ctrl'] = event[7]
    end
    return res
  end
end
