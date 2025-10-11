#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# main repo: https://github.com/Z-H-Sun/tswMP.git

UpdateWindow = API.new('UpdateWindow', 'L', 'I', 'user32')
FillRect = API.new('FillRect', 'LSL', 'I', 'user32')
DrawText = API.new('DrawTextA', 'LSIPI', 'I', 'user32')
DrawTextW = API.new('DrawTextW', 'LSIPI', 'I', 'user32')
TextOut = API.new('TextOutA', 'LIISI', 'I', 'gdi32')
TextOutW = API.new('TextOutW', 'LIISI', 'I', 'gdi32')
Polyline = API.new('Polyline', 'LSI', 'I', 'gdi32')
PatBlt = API.new('PatBlt', 'LIIIII', 'I', 'gdi32')
BitBlt = API.new('BitBlt', 'LIIIILIII', 'I', 'gdi32')
StretchBlt = API.new('StretchBlt', 'LIIIILIIIII', 'I', 'gdi32')
SetStretchBltMode = API.new('SetStretchBltMode', 'LI', 'I', 'gdi32')
SetDIBits = API.new('SetDIBits', 'LLIIPPI', 'I', 'gdi32')
InvalidateRect = API.new('InvalidateRect', 'LPI', 'I', 'user32')
GetFocus = API.new('GetFocus', 'V', 'L', 'user32')
GetCursorPos = API.new('GetCursorPos', 'P', 'L', 'user32')
ScreenToClient = API.new('ScreenToClient', 'LP', 'L', 'user32')
CreateCompatibleBitmap = API.new('CreateCompatibleBitmap', 'LII', 'L', 'gdi32')
CreateCompatibleDC = API.new('CreateCompatibleDC', 'L', 'L', 'gdi32')
DeleteDC = API.new('DeleteDC', 'L', 'L', 'gdi32')
CreatePen = API.new('CreatePen', 'IIL', 'L', 'gdi32')
GetStockObject = API.new('GetStockObject', 'I', 'L', 'gdi32')
DeleteObject = API.new('DeleteObject', 'L', 'L', 'gdi32')
SelectObject = API.new('SelectObject', 'LL', 'L', 'gdi32')
SetDCBrushColor = API.new('SetDCBrushColor', 'LI', 'I', 'gdi32')
SetTextColor = API.new('SetTextColor', 'LI', 'I', 'gdi32')
SetBkColor = API.new('SetBkColor', 'LI', 'I', 'gdi32')
SetBkMode = API.new('SetBkMode', 'LI', 'I', 'gdi32')
SetROP2 = API.new('SetROP2', 'LI', 'I', 'gdi32')

HC_ACTION = 0
DC_BRUSH = 18
DC_PEN = 19
DT_CENTER = 1
DT_VCENTER = 4
DT_SINGLELINE = 0x20
DT_CENTERBOTH = DT_CENTER | DT_VCENTER | DT_SINGLELINE
NONANTIALIASED_QUALITY = 3
SYSTEM_FONT = 13

COLORONCOLOR = 3
R2_XORPEN = 7
R2_COPYPEN = 13
R2_WHITE = 16
# Ternary Raster Operations
RASTER_S = 0xCC0020
RASTER_SPo = 0xFC008A
RASTER_DPo = 0xFA0089
RASTER_DPx = 0x5A0049

HIGHLIGHT_COLOR = [0x22AA22, 0x60A0C0, 0x2222FF, 0xC07F40, 0x889988, 0x666666, 0xFFFFFF] # OK, suspicious, no-go, item, polyline, background, foreground text (note: not RGB, but rather BGR)

OFFSET_IMAGE6 = 0x254 # orb of hero
OFFSET_MEMO123 = [0x3c8, 0x3cc, 0x3d0] # HP/ATK/DEF
TIMER1_ADDR = 0x43120 + BASE_ADDRESS
TIMER2_ADDR = 0x5265c + BASE_ADDRESS
MOVE_ADDR = [0x84c58+BASE_ADDRESS, 0x84c04+BASE_ADDRESS, 0x84bb0+BASE_ADDRESS, 0x84b5c+BASE_ADDRESS] # down/right/left/up
LAST_I_ADDR = 0x48c580
EVENT_SEQ_INDEX_ADDR = 0x8c5ac + BASE_ADDRESS
POINTER_ANSI_STR_ADDR = 0x8c5d4 + BASE_ADDRESS
ORB_FLIGHT_RULE_MSG_ID = 0x14 # you must be near the stairs to fly
ORB_FLIGHT_RULE_BYTES = ["\x0F\x85\xA2\0\0\0", "\x90"*6] # 0: original bytes (JNZ); 1: bypass OrbOfFly restriction (NOP)
CONSUMABLES = {'position' => [0, 1, 2, 4, 5, 6, 7, 8, 9, 11, 12, 13],
  'key' => ['H'.ord, 'N'.ord, [VK_LEFT,VK_DOWN, VK_RIGHT,VK_UP], 'W'.ord, 'P'.ord, 'B'.ord, 'J'.ord, 'U'.ord, 'D'.ord, 'I'.ord, 'K'.ord, 'Q'.ord],
  'event_addr' => [0x80f60+BASE_ADDRESS, 0x8198c+BASE_ADDRESS, [0x81e80+BASE_ADDRESS, 0x81f59+BASE_ADDRESS, 0x4ed1c+BASE_ADDRESS, 0x4ed94+BASE_ADDRESS, 0x4eaf4+BASE_ADDRESS], 0x8201c+BASE_ADDRESS, 0x82128+BASE_ADDRESS, 0x82234+BASE_ADDRESS, 0x82340+BASE_ADDRESS, 0x8244c+BASE_ADDRESS, 0x82558+BASE_ADDRESS, 0x82664+BASE_ADDRESS, 0x82770+BASE_ADDRESS, 0x8287c+BASE_ADDRESS, 0x50ba0+BASE_ADDRESS]} # imgXXwork; the last is Button38Click (Button_Use)

require 'connectivity'
require 'monsters'
require 'tswMPExt'

MP_MODIFIER = 0 # hotkey and modifier for quit and keyboard re-hook
MP_HOTKEY = 118 # F7
MP_KEY1 = VK_LWIN
MP_KEY2 = VK_TAB # hotkeys for teleportation and using items
$MPshowMapDmg = true # whether to enable enhanced damage display
$MPnewMode = true # show damage display all the time, not just when WIN/TAB is being held down

$hGUIFont = CreateFontIndirect.call_r(DAMAGE_DISPLAY_FONT.pack(LOGFONT_STRUCT))
$hSysFont = GetStockObject.call_r(SYSTEM_FONT)
$hBr = GetStockObject.call_r(DC_BRUSH)
$hPen0 = GetStockObject.call_r(DC_PEN)
$hPen = CreatePen.call_r(0, 3, HIGHLIGHT_COLOR[4])
$hPen2 = CreatePen.call_r(0, 3, HIGHLIGHT_COLOR[-2])

# https://github.com/ffi/ffi/issues/283#issuecomment-24902987
# https://github.com/undees/yesbut/blob/master/2008-11-13/hook.rb
module HookProcAPI
# This module provides low-level keyboard and mouse hook management and other tswMP-related (teleportation, item usage, and on-map damage display) functions.

# Instance Variables:
# - @hkhook, @hmhook [Numeric (pointer)]: Handles for keyboard and mouse hooks; nil if not hooked.
# - @itemAvail [Array of Integer]: Array of available item indices.
# - @winDown [nil or false or Integer]: State of MP_KEY1(by default, left WIN)/MP_KEY2(by default, TAB) keys [`nil` if not pressed, `false` if pressed but within an event (so no need to respond), `0`-`2` if pressed and active (0=both MP_KEY1 and MP_KEY2 pressed, so in sticky mode; 1=MP_KEY1 pressed, 2=MP_KEY2 pressed)].
# - @lastIsInEvent [Boolean]: Whether `isInEvent` returned true (you were during an event when `isInEvent` was checked last time).
# - @x_pos, @y_pos [Integer; -1-10]: Current cell coordinate (`0`-`10`) defined by the most recent mouse position on map; `-1` if out of range.
# - @access [Integer or nil]: Accessibility of destination tile: `0` if the destination is directly accessible; a nonzero integer if a step is required (+1, -1, +11, or -11, indicating the direction); or `nil` if the destination is inaccessible or an error occurs.
# - @flying [Integer or nil]: State for OrbOfFlight usage: `nil` if not currently using; otherwise, you are using OrbOfFlight: `0` if used normally; `2` if you cheated (you don't have access to a stair).
# - @error [Exception or nil]: Stores exception from hook callback. `nil` if no exception.
# - @lastArrow [Integer]: Last arrow key pressed. -1: none; 0: left/down; 1: right/up.
# - @lastDraw: Whether highlight/polyline was previously drawn.

# Methods:
# - handleHookExceptions: Raises stored exception from hook callback; called after hook processing is complete.
# - finally {<block code>}: A wrapper for a code block to allow using `break` to exit from the block.
# - getFocusClassName [String]: Returns class name of the currently focused window.
# - isButtonFocused [Boolean]: Checks if the currently focused control in TSW is a button (TButton).
# - isSLActive [Boolean]: Checks if tswSL v2 is active (only used for compatibility with old version tswSL v2).
# - isInEvent [Boolean]: Determines if currently during an event. Extra treatments are done when event status changes: if an event just started, item bar highlights are cleared and message bar is updated; if an event just ended, item bar and map teleportation overlay are redrawn.
# - initHDC: Initializes device context (DC) with appropriate settings for drawing.
# - disposeHDC: Releases device context (DC) resources.
# - abandon: Cancels current teleportation and/or item (e.g., OrbOfFlight) operations and cleans up.
# - recalcStatus: Reads hero and map status from memory and updates them.
# - drawMapDmg(init [Boolean]): After an event is over, updates game map and, if the legacy on-map damage drawing mode is used, draws map damage overlay (on-map damage drawing will be automatically updated in the new drawing mode). The parameter `init` is only used for re-checking the map, and indicates whether all properties of monsters and magic attacks should be recalculated.
# - drawDmg(x, y [Integer], dmg [String], cri [nil or false or String], danger [Boolean]): Draws damage text on map (this method is only used in the legacy on-map damage drawing mode). `cri` is `nil` if no further critical value; `false` if magic attack; or a string if normal critical value. `danger` indicates whether the damage is may cause death.
# - drawItemsBar: Highlights items and labels their corresponding hotkeys. Also draws the last cell in the item bar for the tswExt console.
# - _msHook(nCode, wParam, lParam): Mouse hook callback; for teleportation (mouse click) and connectivity preview (mouse move). Return value dictates whether to block the mouse input.
# - _keyHook(nCode, wParam, lParam): Keyboard hook callback; for item usage and tswMP function activation (including the sticky mode). Return value dictates whether to block the keyboard input.
# - hookK: Installs keyboard hook.
# - unhookK: Removes keyboard hook.
# - rehookK: Reinstalls keyboard hook.
# - hookM: Installs mouse hook.
# - unhookM(stopClipCursor=true): Removes mouse hook and takes further actions (e.g., stopping cursor clipping if `stopClipCursor` is true; undo polyline and highlight drawing; restoring TSW UI, etc.).
# - noHighlightRect: Clears item/message bar/sticky mode drawings.

  SetWindowsHookEx = API.new('SetWindowsHookEx', 'IKII', 'I', 'user32')
  UnhookWindowsHookEx = API.new('UnhookWindowsHookEx', 'I', 'I', 'user32')
  CallNextHookEx = API.new('CallNextHookEx', 'ILLL', 'I', 'user32')
  GetClassName = API.new('GetClassName', 'LPL', 'I', 'user32')
  ClipCursor = API.new('ClipCursor', 'S', 'I', 'user32')
  RtlMoveMemory = API.new('RtlMoveMemory', 'PLI', 'V', 'kernel32')
  BeginPath = API.new('BeginPath', 'L', 'L', 'gdi32')
  EndPath = API.new('EndPath', 'L', 'L', 'gdi32')
  StrokePath = API.new('StrokePath', 'L', 'L', 'gdi32')

  WH_KEYBOARD_LL = 13
  WH_MOUSE_LL = 14
  @hkhook = nil
  @hmhook = nil
  @itemAvail = [] # the items you have
  @winDown = nil # whether [WIN] pressed and thus active (nil=WIN key not pressed; false=do not respond (because in event) though WIN key is pressed; 0-2=active; 0=both WIN and TAB keys pressed and thus in sticky mode)
  @lastIsInEvent = false
  @x_pos = @y_pos = -1
  @access = nil # the destination is accessible?
  @flying = nil # currently using OrbOfFly; active
  @error = nil # exception within hook callback function
  @lastArrow = 0 # which arrowkey pressed previously? -1: none; 0: left; 1: right
  @lastDraw = false # highlight and connecting polyline drawn before

  module_function
  def handleHookExceptions() # exception should not be raised until callback returned
    return if @error.nil?
    raise_r @error
  end
  def finally # code block wrapper
    yield
  end
  def getFocusClassName()
    len = GetClassName.call(GetFocus.call(), $buf, 256)
    return $buf[0, len]
  end
  def isButtonFocused()
    return getFocusClassName == 'TButton'
  end
  def isSLActive() # this is to make compatible with old versions of tswSL (or else ESC won't function in tswSL v2 if MP_KEY is ESC)
    case getFocusClassName
    when /^ComboBox$/i, /^ComboLBox$/i, /^Edit$/i
      return true
    end
    return false
  end
  def isInEvent()
    result = ((isButtonFocused and !@flying) or (readMemoryDWORD(EVENT_SEQ_INDEX_ADDR) > 0))
    if result
      return true if @lastIsInEvent
      @lastIsInEvent = true # if @lastIsInEvent is false
      @x_pos = @y_pos = -1 # reset pos
      InvalidateRect.call($hWnd, $itemsRect, 0) # clear item bar highlights
      initHDC unless $hDC # it is possible that hDC is not assigned yet
      showMsg(1, 0, @winDown == 0 ? $str::STRINGS[65][1] : '')
    elsif @lastIsInEvent # result is false and @lastIsInEvent is true
      if @hmhook # just waited an event over; redraw items bar and map damage
        callFunc(TIMER2_ADDR) # immediately call TIMER2TIMER. Normally, the timer2 will wait 300 msec, then run once (i.e. will disable itself after the first run), where it will call `TTSW10.itemlive (which ends the in-event status)`. This will enforce redrawing the window, which will mess up with our drawing. So we will call it by ourselves without the 300 ms delay; then begin drawing
        InvalidateRect.call($hWnd, $itemsRect, 0) # redraw item bar
        UpdateWindow.call($hWnd) # update immediately to clear the invalidated rect
        recalcStatus
        drawItemsBar # before this, UpdateWindow must be called; otherwise, the TSW's own redrawing process (caused by `itemlive`) may clear the drawing here
        @lastIsInEvent = false
        _msHook(nil, WM_MOUSEMOVE, 0) # continue teleportation
      else
        @lastIsInEvent = false
        InvalidateRect.call($hWnd, $msgRect, 0) # clear message bar
      end
    end
    return result
  end
  def initHDC()
    $hDC = GetDC.call_r($hWnd)
    SelectObject.call_r($hDC, $hBr) # hDC returned by GetDC above will, every time, reset to default DC parameters, so need to set them accordingly
    SelectObject.call_r($hDC, $hPen)
    SetROP2.call_r($hDC, R2_XORPEN)
    SetBkColor.call_r1($hDC, HIGHLIGHT_COLOR[-2])
    SetBkMode.call_r($hDC, 1) # transparent
    SetTextColor.call_r1($hDC, HIGHLIGHT_COLOR.last)
    SetStretchBltMode.call_r($hDC, COLORONCOLOR)
  end
  def disposeHDC()
    @winDown = nil # nil=WIN key not pressed
    return unless $hDC
    SelectObject.call($hDC, $hPen0) # might be an overkill, but just to guarantee no GDI leak
    ReleaseDC.call($hWnd, $hDC)
    $hDC = nil # hDC already released; no longer valid
  end
  def abandon()
    if @flying # special case; need to do more treatments when orb of flight was being used
      callFunc_noRaise(CONSUMABLES['event_addr'][2][4]) # click OK if using OrbOfFlight (if TSW has already quitted, ignore error)
      ClipCursor.call(nil)
      noHighlightRect()
    else unhookM() end
    disposeHDC
    @lastIsInEvent = false
    @flying = nil
  end
  def recalcStatus()
    ReadProcessMemory.call_r($hPrc, STATUS_ADDR, $buf, STATUS_LEN << 2, 0)
    $heroStatus = $buf.unpack(STATUS_TYPE)
    ReadProcessMemory.call_r($hPrc, ITEM_ADDR, $buf, ITEM_LEN << 2, 0)
    $heroItems = $buf.unpack(ITEM_TYPE)
    hero = [$heroStatus[STATUS_INDEX[0]], $heroStatus[STATUS_INDEX[1]], $heroStatus[STATUS_INDEX[2]]] # hp/atk/def
    floor = $heroStatus[STATUS_INDEX[4]]
    mFac = readMemoryDWORD(MONSTER_STATUS_FACTOR_ADDR) + 1
    if mFac != 1
      if $hWndMemo.empty? # $hWndMemo not yet defined
        OFFSET_MEMO123.each {|i| $hWndMemo.push(readMemoryDWORD(readMemoryDWORD($TTSW+i)+OFFSET_HWND))}
      end # these can't be immediately assigned upon TSW initialization; see `init`
      for i in 0..2
        SendMessage.call($hWndMemo[i], WM_SETTEXT, 0, '%d.%02d' % (hero[i]*100/mFac).divmod(100))
      end
    end
    Monsters.heroHP = hero[0]
    Monsters.heroATK = hero[1]
    Monsters.heroDEF = hero[2]
    Monsters.statusFactor = mFac
    Monsters.heroOrb = ($MPshowMapDmg == 1) || ($MPshowMapDmg && ($heroItems[ITEM_INDEX[2]]==1))
    Monsters.cross = ($heroItems[ITEM_INDEX[5]]==1)
    Monsters.dragonSlayer = ($heroItems[ITEM_INDEX[12]]==1)
    Monsters.luckyGold = ($heroItems[ITEM_INDEX[16]]==1)

    Monsters.check_mag = readMemoryDWORD(SACREDSHIELD_ADDR).zero?
    ReadProcessMemory.call_r($hPrc, MAP_ADDR+floor*123+2, $buf, 121, 0)
    $mapTiles = $buf.unpack(MAP_TYPE)
    ReadProcessMemory.call_r($hPrc, MONSTER_STATUS_ADDR, $buf, MONSTER_STATUS_LEN << 2, 0)
    $monStatus = $buf.unpack(MONSTER_STATUS_TYPE)
    drawMapDmg(true) # reinit after an event happens
    Connectivity.floodfill($heroStatus[STATUS_INDEX[6]], $heroStatus[STATUS_INDEX[7]]) # x, y
  end
  def drawMapDmg(init)
    callFunc(DRAW_HERO_2_ADDR) # update game map drawing after an event is over
    if $MPnewMode
      Monsters.checkMap(init)
      return
    end
    WriteProcessMemory.call_r($hPrc, TIMER1_ADDR, "\xc3", 1, 0) # TIMER1TIMER ret (disable; freeze)
    SelectObject.call_r($hDC, $hGUIFont)
    SelectObject.call_r($hDC, $hPen2)
    SetROP2.call_r($hDC, R2_COPYPEN)
    Monsters.checkMap(init)
    SetROP2.call_r($hDC, R2_XORPEN)
    SelectObject.call_r($hDC, $hPen)
    SelectObject.call_r($hDC, $hSysFont)
  end
  def drawDmg(x, y, dmg, cri, danger)
    if danger
      SetTextColor.call_r1($hDC, HIGHLIGHT_COLOR[2])
      SetROP2.call_r($hDC, R2_WHITE)
    end
    BeginPath.call_r($hDC)
    if cri == false # magic attack
      x = $MAP_LEFT+$TILE_SIZE*x
      y = $MAP_TOP+$TILE_SIZE*y
      rect = [x, y, x+$TILE_SIZE, y+$TILE_SIZE].pack('l4')
      DrawText.call_r($hDC, dmg, -1, rect, DT_CENTERBOTH)
    else
      x = $MAP_LEFT+$TILE_SIZE*x + 1
      y = $MAP_TOP+$TILE_SIZE*(y+1) - 15
      dmg_u = Str.utf8toWChar(dmg)
      dmg_s = Str.strlen()
      TextOutW.call_r($hDC, x, y, dmg_u, dmg_s)
      TextOut.call_r($hDC, x, y-12, cri, cri.size) if cri
    end
    EndPath.call_r($hDC)
    StrokePath.call_r($hDC)
# StrokeAndFillPath won't work well here because the inside of the path will also be framed (The pen will draw along the center of the frame. Why is there PS_INSIDEFRAME but no PS_OUTSIDE_FRAME? GDI+ can solve this very easily by pen.SetAlignment), making the texts difficult to read.
# So FillPath or another TextOut must be called afterwards to overlay on top of the inside stroke
# SaveDC and RestoreDC can be used to solve the issue that StrokePath or FillPath will discard the active path afterwards (not used here)
# refer to: https://github.com/tpn/windows-graphics-programming-src/blob/master/Chapt_15/Text/TextDemo.cpp#L1858
    if cri == false
      DrawText.call_r($hDC, dmg, -1, rect, DT_CENTERBOTH)
    else
      TextOut.call_r($hDC, x, y-12, cri, cri.size) if cri
      TextOutW.call_r($hDC, x, y, dmg_u, dmg_s)
    end
    if danger
      SetTextColor.call_r1($hDC, HIGHLIGHT_COLOR.last)
      SetROP2.call_r($hDC, R2_COPYPEN)
    end
  end
  def drawItemsBar()
    @lastDraw = false
    @itemAvail = []
    drawTxt($msgRect2, 64) if @winDown == 0 # sticky mode
    SetBkMode.call_r($hDC, 2) # opaque
    SetDCBrushColor.call_r1($hDC, HIGHLIGHT_COLOR[3])
    for i in 0..11 # check what items you have
      j = CONSUMABLES['position'][i]
      count = $heroItems[ITEM_INDEX[2+j]] # note the first 2 are sword and shield
      if i == 6 # space wing
        next if count < 1
      else # otherwise can't have more than 1
        next if count != 1
      end
      @itemAvail << i
      y, x = j.divmod(3)
      x = x * $TILE_SIZE + $ITEMSBAR_LEFT
      y = y * $TILE_SIZE + $ITEMSBAR_TOP
      if i == 2
        DrawTextW.call_r($hDC, "\xBC\x25\n\0\xB2\x25", 3, $OrbFlyRect.last, 0) # U+25BC/25B2 = down/up triangle
      else
        kName = Str.utf8toWChar(getKeyName(0, CONSUMABLES['key'][i]))
        TextOutW.call_r($hDC, x, y, kName, Str.strlen())
      end
      PatBlt.call_r($hDC, x, y, $TILE_SIZE, $TILE_SIZE, RASTER_DPo)
    end
    SetBkMode.call_r($hDC, 1) # transparent

  # start drawing the last cell (for tswExt)
    x = $ITEMSBAR_LEFT + ($TILE_SIZE << 1)
    y = $ITEMSBAR_TOP + ($TILE_SIZE << 2)
    StretchBlt.call_r($hDC, x, y, $TILE_SIZE, $TILE_SIZE, $hMemDC, 0, 0, 40, 40, RASTER_SPo)
    kName = Str.utf8toWChar(getKeyName(0, EXT_KEY))
    TextOutW.call_r($hDC, x, y, kName, Str.strlen())
  end
  def _msHook(nCode, wParam, lParam)
    block = false # block input?
    finally do
      break if nCode != HC_ACTION and !nCode.nil? # do not process
      break if @lastIsInEvent and @winDown != 0 # during sticky mode, do not stop mouse hook
      case wParam
      when WM_LBUTTONDOWN, WM_RBUTTONDOWN # mouse click; teleportation
        break if @x_pos < 0 or @y_pos < 0 or isInEvent
        block = true
        cheat = (wParam == WM_RBUTTONDOWN)
        x, y = @x_pos, @y_pos
        if cheat
          cheat = (@access != 0)
          showMsgTxtbox(cheat ? 8 : -1)
        else
          case @access
          when nil
            break
          when -11 # go down
            y -= 1; operation = MOVE_ADDR[0]
          when -1 # go right
            x -= 1; operation = MOVE_ADDR[1]
          when 1 # go left
            x += 1; operation = MOVE_ADDR[2]
          when 11 # go up
            y += 1; operation = MOVE_ADDR[3]
          when 0
          else # undefined (unlikely)
            break
          end
          showMsgTxtbox(-1)
        end
        EnableWindow.call($hWndText, 0)

        if $MPnewMode
          callFunc(EPL_ADDR) if @lastDraw # undo the last drawing
        else
          WriteProcessMemory.call_r($hPrc, TIMER1_ADDR, "\x53", 1, 0) # TIMER1TIMER push ebx (re-enable)
        end

        writeMemoryDWORD(STATUS_ADDR + (STATUS_INDEX[6] << 2), x)
        writeMemoryDWORD(STATUS_ADDR + (STATUS_INDEX[7] << 2), y)

        if (facing = Connectivity.facing) then writeMemoryDWORD(HERO_FACE_ADDR, facing) end # update player's facing direction

        writeMemoryDWORD(LAST_I_ADDR, $heroStatus[STATUS_INDEX[6]] + $heroStatus[STATUS_INDEX[7]]*11) # previous position of player (11*old_y+old_x); this is also used to tell `ERASE_AND_DRAW_HERO_ADDR` which tile to redraw (i.e., erase previous hero overlay)
        callFunc(ERASE_AND_DRAW_HERO_ADDR) # redraw hero overlay on the game map
        $heroStatus[STATUS_INDEX[6]] = x # update old_x and old_y
        $heroStatus[STATUS_INDEX[7]] = y

        checkTSWsize()

        @lastDraw = false
        unless cheat or @access.zero? # need to move 1 step
          callFunc(operation) # move to the destination and trigger the event
          break if isInEvent()
        end
        # directly teleport to destination or somehow no event is triggered (e.g. ATK too low)
        break unless @hmhook # stop drawing if WIN key is already released while this hooked function is still running
        drawMapDmg(false) # since the map has already refreshed, the damage values on the map should be redrawn
        showMsg(cheat ? 2 : 0, 5, x, y, @itemAvail.empty? ? $str::STRINGS[-1] : $str::STRINGS[6])
        $mapTiles.map! {|i| if i.zero? then 6 elsif i < 0 then -i else i end} # revert previous graph coloring
        Connectivity.floodfill(x, y) # if event is not triggered, then the current coordinate is (x, y) not (@x_pos, @y_pos)!
        break
      when WM_MOUSEMOVE
      else
        break
      end
#     buf = "\0"*24
#     RtlMoveMemory.call(buf, lParam, 24)
#     buf = buf.unpack('L*')
      # the point returned in lparam is DPI-aware, useless here
      # https://docs.microsoft.com/zh-cn/windows/win32/api/winuser/ns-winuser-msllhookstruct#members
#     mouse move
      GetCursorPos.call_r($buf)
      sx, sy = $buf.unpack('ll')
      ScreenToClient.call_r($hWnd, $buf)
      x, y = $buf.unpack('ll')
      dx = sx - x; dy = sy - y
      checkTSWsize()
      left = $MAP_LEFT + dx; top = $MAP_TOP + dy; size = $TILE_SIZE * 11
      ClipCursor.call([left, top, left+size, top+size].pack('l4')) # confine cursor pos within map

      x_pos = ((x - $MAP_LEFT) / $TILE_SIZE).floor
      y_pos = ((y - $MAP_TOP) / $TILE_SIZE).floor

      break if x_pos == @x_pos and y_pos == @y_pos # same pos
      if !nCode.nil? then break if isInEvent end # don't check this on init

      if @lastDraw # undo the last drawing
        if $MPnewMode
          callFunc(EPL_ADDR)
        else
          r = Connectivity.route
          s = r.size >> 1
          Polyline.call_r($hDC, r.pack('l*'), s) if s > 1 # the trick is to XOR twice to restore the previous pixels
          BitBlt.call_r($hDC, r[0]-($TILE_SIZE >> 1), r[1]-($TILE_SIZE >> 1), $TILE_SIZE, $TILE_SIZE, $hMemDC, 0, 40, RASTER_S) if !s.zero? # read bitmap from memory DC (this `if` statement should be always true, but just be cautious to avoid error)
        end
        @lastDraw = false
      end

      if x_pos < 0 or x_pos > 10 or y_pos < 0 or y_pos > 10 # outside
        if @itemAvail.empty? then showMsg(1, 2) else showMsg(3, 4) end
        @x_pos = @y_pos = -1 # cancel preview
        break
      end

      @x_pos = x_pos; @y_pos = y_pos

# it is possible that when [WIN] key is released (and thus `unhookM` is called), `_msHook` is still running; in this case, do not do the following things:
      @access = Connectivity.main(x_pos, y_pos)
      break unless @hmhook
      if @access
        colorIndex = @access.zero? ? 0 : 1
        showMsg(4, 1, x_pos, y_pos, @itemAvail.empty? ? $str::STRINGS[-1] : $str::STRINGS[6])
      else
        colorIndex = 2
        if @itemAvail.empty?
          showMsg(1, 3, x_pos, y_pos)
        else
          showMsg(3, 4)
        end
      end

      break unless @hmhook
      r = Connectivity.route
      s = r.size >> 1
      if $MPnewMode
        s = 1 if s > 63 # unlikely, if the polyline contains >= 64 vertices, there will be no enough room to hold the data in memory, in which case the polyline will simply not drawn to avoid error
        WriteProcessMemory.call_r($hPrc, POLYLINE_COUNT_ADDR, ((s-1) | (colorIndex << 6)).chr, 1, 0)
        WriteProcessMemory.call_r($hPrc, POLYLINE_VERTICES_ADDR, r.pack('l*'), s << 3, 0)
        callFunc(DPL_ADDR)
      else
        x_left = r[0] - ($TILE_SIZE >> 1)
        y_top = r[1] - ($TILE_SIZE >> 1)
        BitBlt.call_r($hMemDC, 0, 40, $TILE_SIZE, $TILE_SIZE, $hDC, x_left, y_top, RASTER_S) # store the current bitmap for future redraw
        SetDCBrushColor.call_r1($hDC, HIGHLIGHT_COLOR[colorIndex])
        PatBlt.call_r($hDC, x_left, y_top, $TILE_SIZE, $TILE_SIZE, RASTER_DPo)
        Polyline.call_r($hDC, r.pack('l*'), s) if s > 1
      end
      @lastDraw = true

      id = Connectivity.destTile
      break unless @hmhook and Monsters.heroOrb and (m = Monsters.getMonsterID(id))
      writeMemoryDWORD(CUR_MONSTER_ID_ADDR, m)
      callFunc(SHOW_MONSTER_STATUS_ADDR)
      data = Monsters.monsters[m]
      if data.nil? # unlikely, but let's add this new item into database
        data = Monsters.getStatus(m)
        Monsters.monsters[m] = data
      end
      showMsgTxtbox(14, *Monsters.detail((m == 18 && id != 104), *data))
      EnableWindow.call($hWndText, 1) # now you can use mouse to select / scroll status bar textbox and view more info (I've made changes to the TSW.exe executable such that once the text changes, TEdit8 will be disabled again: TEdit8: OnChange = DisTEdit8 = mov eax, [eax+1c8]; call 413544)
    end
    return 1 if block or nCode.nil? # upon pressing [WIN] without mouse move
    return CallNextHookEx.call(@hmhook, nCode, wParam, lParam)
  # no need to "rescue" here since the exceptions could be handled in _keyHook
  end
  def _keyHook(nCode, wParam, lParam)
    # 'ILL': If the prototype is set as 'LLP', the size of the pointer could not be correctly assigned
    # Therefore, the address of the pointer is retrieved instead, and RtlMoveMemory is used to get the pointer data
    block = false # block input?
    finally do
      break if nCode != HC_ACTION # do not process

      hWnd = GetForegroundWindow.call
      if hWnd != $hWnd # TSW is not active
        abandon() if @winDown or @flying
        break
      end

      RtlMoveMemory.call($buf, lParam, 20)
      key = $buf.unpack('L')[0]
      if key == MP_KEY1 or key == MP_KEY2
        if key == VK_ESCAPE then break if isSLActive end
        alphabet = false # alphabet key pressed?
        arrow = false # arrow key pressed?
        @winDown = false if @winDown == nil # WIN key is pressed, but whether to respond will depend on whether not in-event
        curWinDown = (key == MP_KEY1 ? 1 : 2) # currently WIN key or TAB key pressed; if the other key pressed next time, activate sticky mode
      else
        break if wParam != WM_KEYDOWN and wParam != WM_SYSKEYDOWN
        if key == (SL_HOTKEYS[2] & 0xFF) and @winDown != nil # as long as WIN key is pressed, trigger "load specific temp data" function whether or not in-event
          abandon()
          callFunc_noBlock(Ext::LOAD_TEMP_ANY_ADDR)
          block = true; break
        end
        break unless @winDown
        if (alphabet = CONSUMABLES['key'].index(key)) # which item chosen?
          unless @itemAvail.include?(alphabet) # you must have that item
            abandon(); break
          end
        elsif (arrow = CONSUMABLES['key'][2].index(key)) # up/downstairs?
          unless @itemAvail.include?(2) # you must have orb of flight
            block = true # do not respond to arrow keys which may cause conflicts (because events can be triggered)
            abandon(); break
          end
        elsif key == EXT_KEY
          abandon()
          PostMessage.call(0, WM_APP, Ext::EXT_WPARAM, 0) unless isInEvent # this msg will be handled in main.rbw, and tswExt console interface will show up. This action must be postponed and should not be done within the hook callback function to avoid significant system performance degradation
          block = true; break
        else abandon(); break # if any non-functional key is pressed (same above), cancel this operation immediately; this is to avoid potential conflicts in certain scenarios (e.g., when you press Enter after talking to an NPC (in this case, because another key is pressed, the previous hotkey won't generate any more KeyDown events); switching to a different window; etc.)
        end
      end

      block = true
      if wParam == WM_KEYDOWN
        break if isInEvent # when holding [WIN] key, this (i.e. `isInEvent`) will automatically be called every ~50 msec (keyboard repeat delay)
        if alphabet and !@flying
          abandon()
          callFunc(CONSUMABLES['event_addr'][alphabet]) # imgXXwork = click that item
          if isButtonFocused # can use item successfully (so the don't-use button is focused now)
            callFunc(CONSUMABLES['event_addr'][12]) if alphabet > 2 # buttonUseClick = click 'Use' (excluding OrbOfHero/Wisdom)
          else
            showMsgTxtbox(10, $str::LONGNAMES[14+alphabet].gsub(' ', ''))
          end

        elsif arrow
          if @flying # already flying: arrow keys=up/downstaris
            arrow >>= 1
            callFunc(CONSUMABLES['event_addr'][2][arrow+2]) # click Down/Up
            showMsgTxtbox(8) if @flying == 2
            if @lastArrow != arrow
              InvalidateRect.call($hWnd, $OrbFlyRect[@lastArrow], 0)
              UpdateWindow.call($hWnd) if @lastArrow < 0 # update immediately to clear the invalidated rect
              DrawTextW.call_r($hDC, ["\xBC\x25", "\xB2\x25"][arrow], 1, $OrbFlyRect[arrow], arrow << 1) # before this, UpdateWindow must be called; otherwise, the TSW's own redrawing process (caused by `InvalidateRect` above) may clear the drawing here
              PatBlt.call_r($hDC, (4+arrow)*$TILE_SIZE/2+$ITEMSBAR_LEFT, $ITEMSBAR_TOP, $TILE_SIZE/2, $TILE_SIZE, RASTER_DPo)
              @lastArrow = arrow
            end
          else
            unhookM(false) # do not stop ClipCursor yet
            WriteProcessMemory.call_r($hPrc, CONSUMABLES['event_addr'][2][1], ORB_FLIGHT_RULE_BYTES[1], 6, 0) if arrow == 3 # bypass OrbOfFlight restriction (JNZ->NOP)
            callFunc(CONSUMABLES['event_addr'][2][0]) # Image4Click (OrbOfFlight)
            WriteProcessMemory.call_r($hPrc, CONSUMABLES['event_addr'][2][1], ORB_FLIGHT_RULE_BYTES[0], 6, 0) if arrow == 3 # restore (JNZ)
            if arrow == 3 and $mapTiles # up arrow; bypass OrbOfFlight restriction
              arrow = 0 if $mapTiles.include?(-11) or $mapTiles.include?(-12) # you can access stairs, then it's not considered as cheating
            end
            if isButtonFocused # can use OrbOfFly successfully (so the up/down/ok button is focused now)
              @flying = (arrow == 3 ? 2 : 0) # cheat or not
              showMsgTxtbox(8) if @flying == 2
              @lastArrow = -1
              UpdateWindow.call($hWnd) # update immediately to clear the invalidated rect
              showMsg(@flying, 7, $str::STRINGS[65][@winDown == 0 ? 2 : 3], $MPhookKeyName)
              SetBkMode.call_r($hDC, 2) # opaque
              DrawTextW.call_r($hDC, "\xBC\x25\n\0\xB2\x25", 3, $OrbFlyRect.last, 0) # U+25BC/25B2 = down/up triangle
              PatBlt.call_r($hDC, 2*$TILE_SIZE+$ITEMSBAR_LEFT, $ITEMSBAR_TOP, $TILE_SIZE, $TILE_SIZE, RASTER_DPo) # before this, UpdateWindow must be called; otherwise, the TSW's own redrawing process (caused by `InvalidateRect` above) may clear the drawing here
            else
              disposeHDC
              ClipCursor.call(nil)
              showMsgTxtbox(10, $str::LONGNAMES[16].gsub(' ', '')) if readMemoryDWORD(TEDIT8_MSGID_ADDR) != ORB_FLIGHT_RULE_MSG_ID # otherwise, it's because "you must be near the stairs to fly!"
            end
          end
        elsif !@winDown # only trigger at the first time
          @winDown = curWinDown || 1 # true (`curWinDown`` is used for sticky mode judgements) [it is not likely to be undefined, but just to be cautious and set a default value of 1 here]
          initHDC unless $hDC # this statement is always valid, but just to be cautious and check if $hDC already initialized
          checkTSWsize
          recalcStatus
          drawItemsBar
          hookM
          _msHook(nil, WM_MOUSEMOVE, 0) # do this subroutine once even without mouse move
        elsif @winDown == 0 then @winDown = curWinDown; InvalidateRect.call($hWnd, $msgRect2, 0) # if hotkey is pressed again during sticky mode, then quit sticky mode and clear sticky key prompt
        elsif @winDown != curWinDown then @winDown = 0; drawTxt($msgRect2, 64) # if both hotkeys (WIN / TAB) pressed, turn on sticky mode
        end
      elsif wParam == WM_KEYUP # (alphabet == false; arrow == false)
        block = false # if somehow [WIN] key down signal is not intercepted, then do not block (otherwise [WIN] key will always be down)
        abandon() if @winDown != 0 or @flying # do not abandon if in sticky mode and not flying
      end
    end
    return 1 if block # block input
    return CallNextHookEx.call(@hkhook, nCode, wParam, lParam)
  rescue Exception => @error
    PostMessage.call(0, WM_APP, 0, 0)
    return CallNextHookEx.call(@hkhook, nCode, wParam, lParam)
  end
  MouseProc = API::Callback.new('ILL', 'L', &method(:_msHook))
  KeyboardProc = API::Callback.new('ILL', 'L', &method(:_keyHook))

  def hookK
    return false if @hkhook
    @hkhook = SetWindowsHookEx.call_r(WH_KEYBOARD_LL, KeyboardProc, $hMod, 0)
    return true
  end
  def unhookK
    return false unless @hkhook
    UnhookWindowsHookEx.call(@hkhook)
    @hkhook = nil
  end
  def rehookK
    unhookK
    abandon
    hookK
  end
  def hookM
    return false if @hmhook
    @hmhook = SetWindowsHookEx.call_r(WH_MOUSE_LL, MouseProc, $hMod, 0)
    return true
  end
  def unhookM(stopClipCursor=true)
    unless @hmhook then noHighlightRect() if @lastIsInEvent; return false end # redraw $msgRect and $itemsRect when necessary
    UnhookWindowsHookEx.call(@hmhook || 0)
    @hmhook = nil

    ClipCursor.call(nil) if stopClipCursor # do not confine cursor range
    if $MPnewMode
      if @lastDraw
        return true unless callFunc_noRaise(EPL_ADDR) # undo the last drawing
      end
    else
      return true if WriteProcessMemory.call($hPrc || 0, TIMER1_ADDR, "\x53", 1, 0).zero? # TIMER1TIMER push ebx (restore; re-enable)
    end
    # if TSW has already quitted, the above WriteProcessMemory/callFunc_noRaise call return 0/false, then no need to do anything below
    @x_pos = @y_pos = -1
    noHighlightRect()
    ReadProcessMemory.call($hPrc || 0, MONSTER_STATUS_FACTOR_ADDR, $bufDWORD, 4, 0) # 0 or 43
    return true if $bufDWORD.unpack('l')[0].zero? or !$hWndMemo or $hWndMemo.empty?
    return true if ReadProcessMemory.call($hPrc || 0, STATUS_ADDR, $buf, STATUS_LEN << 2, 0).zero? # refresh, in case the values have changed
    $heroStatus = $buf.unpack(STATUS_TYPE)
    SendMessage.call($hWndMemo[0], WM_SETTEXT, 0, $heroStatus[STATUS_INDEX[0]].to_s)
    SendMessage.call($hWndMemo[1], WM_SETTEXT, 0, $heroStatus[STATUS_INDEX[1]].to_s)
    SendMessage.call($hWndMemo[2], WM_SETTEXT, 0, $heroStatus[STATUS_INDEX[2]].to_s)
    return true
  end
  def noHighlightRect()
    InvalidateRect.call($hWnd, $itemsRect, 0) # redraw item bar
    InvalidateRect.call($hWnd, $msgRect, 0) # clear message bar
    InvalidateRect.call($hWnd, $msgRect2, 0) # clear sticky mode prompt
  end
end

def checkTSWrects()
# Calculates and sets TSW UI-related global variables:
# - $ITEMSBAR_LEFT/TOP: Left/Top position of the items bar.
# - $itemsRect: Rectangle for the items bar (packed as 'l4' String).
# - $TILE_SIZE: Width/height of a tile cell.
# - $OrbFlyRect: Array of rectangles (packed as 'l4' String) for orb fly areas [left half (0), right half (1), and full size (2 or -1)].
# - $msgRect: Rectangle for the message prompt area (packed as 'l4' String).
# - $msgRect2: Rectangle for the sticky mode prompt area (packed as 'l4' String).
  $ITEMSBAR_LEFT = readMemoryDWORD($IMAGE6+OFFSET_CTL_LEFT)
  $ITEMSBAR_TOP = readMemoryDWORD($IMAGE6+OFFSET_CTL_TOP)
  $TILE_SIZE = readMemoryDWORD($IMAGE6+OFFSET_CTL_WIDTH)

  x1 = 2*$TILE_SIZE + $ITEMSBAR_LEFT
  x2 = x1 + $TILE_SIZE/2
  x3 = x1 + $TILE_SIZE
  y1 = $ITEMSBAR_TOP+$TILE_SIZE

  $itemsRect = [$ITEMSBAR_LEFT, $ITEMSBAR_TOP, x3, $ITEMSBAR_TOP+$TILE_SIZE*5].pack('l4')
  $OrbFlyRect = [[x1, $ITEMSBAR_TOP, x2, y1].pack('l4'), [x2, $ITEMSBAR_TOP, x3, y1].pack('l4'), [x1, $ITEMSBAR_TOP, x3, y1].pack('l4')] # left(0), right(1), none(-1)
  $msgRect = [0, $H-$MAP_TOP*2, $W-2, $H-$MAP_TOP].pack('l4') # for `showMsg` prompt
  $msgRect2 = [0, 0, $W-2, $MAP_TOP].pack('l4') # for sticky mode prompt
end

# Drawing functions below. In most cases, call aliases `drawTxt`, `showMsg` and `showMsgTxtbox`, unless there is a special need to specify which of the "A" or "W" version should be used
# `drawTxt`: draws the specified, formatted texts in the message prompt region; `showMsg`: in addition to above, also draws a solid-color background behind the text; `showMsgTxtbox`: shows texts in the status bar textbox
# @param textIndex [Integer] is the index of the text in `$str::STRINGS`; see 'strings.rb' for details
# @param colorIndex [Integer] is the index of the color in `HIGHLIGHT_COLOR`
def drawTxtA(msgRect, textIndex, *argv); DrawText.call_r($hDC, Str::StrEN::STRINGS[textIndex] % argv, -1, msgRect, DT_CENTERBOTH); end
def drawTxtW(msgRect, textIndex, *argv); DrawTextW.call_r($hDC, Str.utf8toWChar(Str::StrCN::STRINGS[textIndex] % argv), -1, msgRect, DT_CENTERBOTH); end
def showMsg(colorIndex, textIndex, *argv)
  SetDCBrushColor.call_r1($hDC, HIGHLIGHT_COLOR[colorIndex])
  FillRect.call_r($hDC, $msgRect, $hBr)
  drawTxt($msgRect, textIndex, *argv)
end
def showMsgTxtboxA(textIndex, *argv)
  SendMessage.call($hWndText, WM_SETTEXT, 0, textIndex < 0 ? '' : Str::StrEN::STRINGS[textIndex] % argv)
end
def showMsgTxtboxW(textIndex, *argv)
  SendMessageW.call($hWndText, WM_SETTEXT, 0, textIndex < 0 ? "\0\0" : Str.utf8toWChar(Str::StrCN::STRINGS[textIndex] % argv))
end

def getHookKeyName()
# sets the string describing the shortcut keys for activating tswMP
  raise_r($str::ERR_MSG[1]) if MP_KEY1.zero?
  $MPhookKeyName = '[' + getKeyName(0, MP_KEY1) + ']'
  $MPhookKeyName << ' / [' + getKeyName(0, MP_KEY2) + ']' unless MP_KEY2.zero?
end
