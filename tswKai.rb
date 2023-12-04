#!/usr/bin/env ruby
# encoding: ASCII-8Bit

require './console'

DISP_ADDR = 0x4cb34 + BASE_ADDRESS # TTSW10.disp
KEY_DISP_ADDR = 0x4bed8 + BASE_ADDRESS # TTSW10.keydisplay
ITEM_DISP_ADDR = 0x4ccd8 + BASE_ADDRESS # TTSW10.itemdisp

KAI_OPTIONS = ['L', 'O', 'N', 'G', 'F', 'H', 'X', 'Y', 'K', 'U', 'R', 'L', 'S', 'I',  'Z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E']

CON_MODIFIER = 0 # hotkey and modifier for showing configs
CON_HOTKEY = 119 # F8

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
end

def cheaterMain()
  reeval
  $console.show_cursor(false)
  c = $console.choice(KAI_OPTIONS)
  reeval
  return nil if c == -1 # ESC
  return true if c == 14 # 'Z'
  if c < 14 # status or sword/shield
    i, x, y, w, r, p = c, 0, c, 33, 13, 23
  else # item
    i, x, y, w, r, p = c-1, 36, c-15, 23, 49, 57
  end
  $console.attr_pos(x, y, STYLE_INVERT, w) # highlight
  $console.cursor(p, y)
  $console.show_cursor(true)
  case i
  when 0..3, 8..11
    $console.print_posA(r, y, '[0,2^31): ')
    v = $console.get_num(10)
    v = 0x7FFFFFFF unless v < 0 or (v >> 31).zero?
    a = i > 3 ? KEY_DISP_ADDR : DISP_ADDR
  when 4..5
    $console.print_posA(r, y, '[0,50]:')
    v = $console.get_num(2)
    v = 50 if v > 50
    a = REFRESH_XYPOS_ADDR
  when 6..7
    $console.print_posA(r, y, '[0, A]:')
    v = $console.choice('0123456789A')
    a = REFRESH_XYPOS_ADDR
  when 12..13
    $console.print_posA(r, y, '[0, 5]:')
    v = $console.choice('012345')
    a = ITEM_DISP_ADDR
  when 21
    $console.print_posA(r, y, '[0,99]: ')
    v = $console.get_num(2)
    a = ITEM_DISP_ADDR
  else
    $console.print_posA(r, y, '[0, 1]:  ')
    v = $console.choice('01')
    a = ITEM_DISP_ADDR
  end

  $console.cls_pos(r, y, w-13, false) # clear tips
  $console.attr_pos(x, y, STYLE_NORMAL, w) # cancel highlights
  $console.p_rect(r, y, 1, 1, KAI_OPTIONS[c], STYLE_B_YELLOW_U)
  return true if v < 0 # ESC

  writeMemoryDWORD(i < 12 ? STATUS_ADDR+(STATUS_INDEX[i] << 2) : ITEM_ADDR+(ITEM_INDEX[i-12] << 2), v)
  return true if i == 5 or i == 11 # highest floor / altar visits

  callFunc(a) # refresh status display
  callFunc(ITEM_LIVE_ADDR) if i > 13 # enable mouse click for choosing items
  if i == 13 # shield
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
    callFunc(DISP_ADDR)
    bgmID = readMemoryDWORD(BGM_ID_ADDR)
    return true if bgmID.zero? # disabled BGM
    callFunc(BGM_CHECK_ADDR)
    return true if bgmID == readMemoryDWORD(BGM_ID_ADDR) # disregard same BGM
    $console.print_posA(31, 4, '%2d', v)
    callFunc(BGM_PLAY_ADDR) # caution: changing BGM will cause game and this thread to freeze for a while if BGM is not taken over by tswBGM (i.e. using TSW's own BGM treatment)
  end
  return true
rescue TSWKaiError
  if c # the choice has been made and is currently inputting values
    $console.cls_pos(r, y, w-13, false) # clear tips
    $console.attr_pos(x, y, STYLE_NORMAL, w) # cancel highlights
    $console.p_rect(r, y, 1, 1, KAI_OPTIONS[c], STYLE_B_YELLOW_U)
  end
  return ! $!.is_a?(TSWQuitedError) # stop if TSW has quitted
end

def initCheaterInterface() # print table headers
  $console.cls()
  $console.print_pos(0, 14, $str::STRINGS[19])
  $console.attr_pos(21, 14, STYLE_INVERT, 3)
  $str::LONGNAMES[0, 14].each_with_index {|x, i| $console.print_pos(0, i, x)} # \r\n does not seem to be properly treated as line breaks using `WriteConsoleOutputCharacter`, so have to do this line by line
  $console.p_rect(13, 0, 1, 15, KAI_OPTIONS[0, 15].join, STYLE_B_YELLOW_U)

  $console.p_rect(34, 0, 1, 15, '|'*15, STYLE_NORMAL)

  $str::LONGNAMES[14, 15].each_with_index {|x, i| $console.print_pos(36, i, x)}
  $console.p_rect(49, 0, 1, 15, KAI_OPTIONS[15, 15].join, STYLE_B_YELLOW_U)
end

def KaiMain()
  $console = Console.new if $console.nil?
  initCheaterInterface() if $console.switchLang()
  $console.setConWinProp()
  return if $console.show(true).nil? # fail
  res = nil
  loop { break unless (res=cheaterMain) }
  $console.show(false) if res.nil? # ESC pressed
  # otherwise, if res==false (TSW quitted), the remainder will be processed in the main loop
end
