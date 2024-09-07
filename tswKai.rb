#!/usr/bin/env ruby
# Author: Z.Sun
# encoding: ASCII-8Bit

require 'console'

DISP_ADDR = 0x4cb34 + BASE_ADDRESS # TTSW10.disp
KEY_DISP_ADDR = 0x4bed8 + BASE_ADDRESS # TTSW10.keydisplay
ITEM_DISP_ADDR = 0x4ccd8 + BASE_ADDRESS # TTSW10.itemdisp
FUTURE_STATUS_FACTOR_ADDR = 0x5342a + BASE_ADDRESS # this value + 1 is the factor to multiply in the backside tower (note: different from MONSTER_STATUS_FACTOR_ADDR, which indicates the current factor)

KAI_OPTIONS = ['L', 'O', 'N', 'G', 'F', 'H', 'X', 'Y', 'K', 'U', 'R', 'V', 'S', 'I', 'Z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E']

CON_MODIFIER = 0 # hotkey and modifier for showing configs
CON_HOTKEY = 119 # F8
$_TSWKAI = true # module tswKai is imported

def reeval()
  ReadProcessMemory.call_r($hPrc, STATUS_ADDR, $buf, STATUS_LEN << 2, 0)
  $heroStatus = $buf.unpack(STATUS_TYPE)
  ReadProcessMemory.call_r($hPrc, ITEM_ADDR, $buf, ITEM_LEN << 2, 0)
  $heroItems = $buf.unpack(ITEM_TYPE)
  for i in 0..14
    $console.print_posA(22, i, '%11d', i < 12 ? $heroStatus[STATUS_INDEX[i]] : $heroItems[ITEM_INDEX[i-12]]) if i != 14 # left column

    itemVal = $heroItems[ITEM_INDEX[i+2]] # right column
    if i == 7
      itemVal = itemVal > 99 ? '>99' : ('%3d' % itemVal)
    else
      if itemVal == 0 then itemVal = '  0' elsif itemVal == 1 then itemVal = '  1' else itemVal = 'N/A' end
    end
    $console.print_posA(56, i, itemVal)
  end
  factor = readMemoryDWORD(MONSTER_STATUS_FACTOR_ADDR)
  factor = readMemoryDWORD(FUTURE_STATUS_FACTOR_ADDR) if factor.zero?
  $console.print_posA(22, 14, '%11d', factor+1) # back tower factor
end

def cheaterMain()
  reeval
  $console.show_cursor(false)
  if $nxtInd # pressed arrow key to navigate to a different item
    c = $nxtInd
    $nxtInd = nil
  else # normal cases
    $console.print_pos(0, 15, $str::STRINGS[19][0]) # tooltip #1
    c = $curInd = $console.choice(KAI_OPTIONS)
    reeval
  end
  return nil if c == -1 # ENTER/SPACE/ESC
  if c <= 14 # status or sword/shield
    i, x, y, w, r, p = c, 0, c, 33, 13, 24
  else # item
    i, x, y, w, r, p = c-1, 36, c-15, 23, 49, 57
  end
  drawShortcutKeys(FOREGROUND_INTENSITY) # dim display of shortcut keys
  $console.print_pos(0, 15, $str::STRINGS[19][1]) # tooltip #2
  $console.attr_pos(x, y, STYLE_INVERT, w) # highlight
  $console.cursor(p, y)
  $console.show_cursor(true)
  case i
  when 0..3, 8..10
    $console.print_posA(r, y, '[0, 10^9): ')
    v = $console.get_num(9)
    a = i > 3 ? KEY_DISP_ADDR : DISP_ADDR
  when 4..5
    $console.print_posA(r, y, '[0, 50]:   ')
    v = $console.get_num(2)
    v = 50 if v > 50
    a = REFRESH_XYPOS_ADDR
  when 6..7
    $console.print_posA(r, y, '[0, A]:    ')
    v = $console.choice('0123456789A')
    a = ERASE_AND_DRAW_HERO_ADDR
  when 12..13
    $console.print_posA(r, y, '[0, 5]:    ')
    v = $console.choice('012345')
    a = ITEM_DISP_ADDR
  when 21
    $console.print_posA(r, y, '[0,99]: ')
    v = $console.get_num(2)
    a = ITEM_DISP_ADDR
  when 11
    $console.print_posA(r, y, '[0, 9999]: ')
    v = $console.get_num(4)
  else
    if c == 14 # back tower factor
      $console.print_posA(r, y, '[2, 9999]: ')
      v = $console.get_num(4)
      unless v < 0 # not ESC; note here, v should -= 1
        if v < 2 then v = 1 else v -= 1 end
      end
    else
      $console.print_posA(r, y, '[0, 1]: ')
      v = $console.choice('01')
      a = ITEM_DISP_ADDR
    end
  end

  $console.cls_pos(r, y, w-13, false) # clear tips
  $console.attr_pos(x, y, STYLE_NORMAL, w) # cancel highlights
  drawShortcutKeys() # restore display of shortcut keys
  return true if v < 0 # ESC

  if c == 14 # back tower factor
    return true unless Mod.replace45FmerchantDialog(v)
    return true unless Mod.replace2ndMagicianDialog(v) # if failed, no need to proceed
    writeMemoryDWORD(FUTURE_STATUS_FACTOR_ADDR, v)
    writeMemoryDWORD(MONSTER_STATUS_FACTOR_ADDR, v) unless readMemoryDWORD(MONSTER_STATUS_FACTOR_ADDR).zero? # already in back side tower
    return true
  end

  writeMemoryDWORD(i < 12 ? STATUS_ADDR+(STATUS_INDEX[i] << 2) : ITEM_ADDR+(ITEM_INDEX[i-12] << 2), v)
  if i == 5 or i == 11 # highest floor / altar visits
    return true
  elsif i == 6 or i == 7 # X / Y position
    writeMemoryDWORD(LAST_I_ADDR, $heroStatus[STATUS_INDEX[6]] + $heroStatus[STATUS_INDEX[7]]*11) # previous position of player (11*old_y+old_x); this is also used to tell `ERASE_AND_DRAW_HERO_ADDR` which tile to redraw (i.e., erase previous hero overlay)
  end

  callFunc(a) # refresh status display
  if i > 13 # enable mouse click for choosing items
    callFunc(ITEM_LIVE_ADDR)
  elsif i == 13 # shield
    if v == 5
      return true unless readMemoryDWORD(SACREDSHIELD_ADDR).zero?
      $console.print_posA(32, 13, v)
      return true if msgboxTxt(17, MB_YESNO | MB_ICONQUESTION) == IDNO
      writeMemoryDWORD(SACREDSHIELD_ADDR, 1)
    else
      return true if readMemoryDWORD(SACREDSHIELD_ADDR).zero?
      $console.print_posA(32, 13, v)
      return true if msgboxTxt(18, MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2) == IDNO
      writeMemoryDWORD(SACREDSHIELD_ADDR, 0)
    end
  elsif i == 4 # floor
    callFunc(DRAW_HERO_ADDR) # redraw hero overlay immediately; otherwise, there will be a short period of time with no hero overlay
    callFunc(DISP_ADDR)
    bgmID = readMemoryDWORD(BGM_ID_ADDR)
    return true if bgmID.zero? # disabled BGM
    callFunc(BGM_CHECK_ADDR)
    return true if bgmID == readMemoryDWORD(BGM_ID_ADDR) # disregard same BGM
    $console.print_posA(31, 4, '%2d', v)
    callFunc(BGM_PLAY_ADDR) # caution: changing BGM will cause game and this thread to freeze for a while if BGM is not taken over by tswBGM (i.e. using TSW's own BGM treatment)
  end
  return true
rescue TSWKaiError => e
  if c # the choice has been made and is currently inputting values
    $console.cls_pos(r, y, w-13, false) # clear tips
    $console.attr_pos(x, y, STYLE_NORMAL, w) # cancel highlights
  end
  if e.is_a?(Console::STDINCancelError) # pressed arrow key to go to another item
    if c # an item already highlighted, then go to a different item
      case e.arrow
      when VK_UP
        if c == 0 then $curInd = 29 else $curInd -= 1 end
      when VK_DOWN
        if c == 29 then $curInd = 0 else $curInd += 1 end
      when VK_LEFT
        if c > 14 then $curInd -= 15 elsif c == 0 then $curInd = 29 else $curInd +=14 end
      when VK_RIGHT
        if c < 15 then $curInd += 15 elsif c == 29 then $curInd = 0 else $curInd -=14 end
      end
    end # otherwise, highlight the last chosen item
    $nxtInd = $curInd
    return true
  end
  drawShortcutKeys() # restore display of shortcut keys
  return ! e.is_a?(TSWQuitedError) # stop if TSW has quitted
end

def initCheaterInterface() # print table headers
  $console.resize() # in case the windows size is changed
  $console.cls()
  $str::LONGNAMES[0, 15].each_with_index {|x, i| $console.print_pos(0, i, x)} # \r\n does not seem to be properly treated as line breaks using `WriteConsoleOutputCharacter`, so have to do this line by line
  $console.p_rect(34, 0, 1, 15, '|'*15, STYLE_NORMAL)
  $str::LONGNAMES[15, 15].each_with_index {|x, i| $console.print_pos(36, i, x)}

  $console.attr_pos(0, 15, STYLE_NORMAL | COMMON_LVB_GRID_HORIZONTAL, 60)
end

def drawShortcutKeys(style=STYLE_B_YELLOW_U)
  $console.p_rect(13, 0, 1, 15, $_KAI_OPTIONS_STR_1, style)
  $console.p_rect(49, 0, 1, 15, $_KAI_OPTIONS_STR_2, style)
end

def KaiMain()
  $curInd = 0 # current item index
  $nxtInd = nil # next item index (nil=not currently selected)

  $console = Console.new if $console.nil?
  initCheaterInterface() if $console.switchLang()
  if $console.need_init # chances are that KAI_OPTIONS have changed since options loaded last time
    $console.need_init = false
    $_KAI_OPTIONS_STR_1 = KAI_OPTIONS[0, 15].join
    $_KAI_OPTIONS_STR_2 = KAI_OPTIONS[15, 15].join
    drawShortcutKeys()
  end

  $console.setConWinProp()
  return if $console.show(true).nil? # fail
  res = nil
  loop { break unless (res=cheaterMain) }
  $console.show(false) if res.nil? # ESC pressed
  # otherwise, if res==false (TSW quitted), the remainder will be processed in the main loop
end
