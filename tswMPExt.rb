#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: tswMPExt_*.asm

# the first half of this script file deals with tswExt functions
EXT_KEY = VK_RETURN # shortcut key for tswExt

module Math
  module_function
  unless defined?(cbrt) # low version Math.cbrt support (Ruby <= 1.9.0.1)
    def cbrt(x) # in this script, we will make sure that the argument x always >= 0, so no need to consider about cases when x < 0
    # if x >= 0
        return x**0.3333333333333333
    # else # pow(x,1.0/3) will return a complex number (or even NaN in Ruby 1.8) when x<0
    #   return -(-x)**0.3333333333333333
    # end
    end
  end
end

module Ext
  open('tswMPExt.bmp', 'rb') do |f| # temporary treatments here; in the future, the contents of EXT_BMP will be incorporated into tswMPDat.rb
    f.seek(14) # skip BMP file header
    EXT_BMP = [f.read(64), # first 40 bytes are BITMAPINFOHEADER, followed by 6*4 bytes of color table (6 RGBA colors in total)
      f.read(800)] # then, 40*40 pixel data, each pixel taking up 4 bits (half byte)
  end

  EXT_WPARAM = 2 # signature for the WM_APP message (so we can know the Msg means to open the tswExt console)
  EXT_OPTIONS = '012345' # items 0-5
  EXT_OPTIONS_LEN = EXT_OPTIONS.size
  EXT_DESCR_LINE = EXT_OPTIONS_LEN+4 # start showing descriptions for the selected item from Line 9
  EXT_DESCR_SIZE = (::Console::CONSOLE_HEIGHT-EXT_DESCR_LINE)*::Console::CONSOLE_WIDTH # space for descripions
  @need_init = true
  @curInd = 0 # current item index
  @nxtInd = nil # next item index (nil=not currently selected)

  module_function
  def need_init; @need_init = true; end

  def ExtMain()
    $console.show_cursor(false)
    if @nxtInd # pressed arrow key to navigate to a different item
      c = @nxtInd
      @nxtInd = nil
    else # normal cases
      c = @curInd = $console.choice(EXT_OPTIONS, false)
    end
    return nil if c == -1 # ENTER/SPACE/ESC

    $console.SE.selection()
    c += 1
    for i in 1..EXT_OPTIONS_LEN
      if i == c
        $console.attr_pos(5, i, STYLE_INVERT, 54) # highlight
      else
        $console.attr_pos(5, i, FOREGROUND_INTENSITY, 54) # dim display of other items
      end
    end
    $console.cls_pos(0, EXT_DESCR_LINE, EXT_DESCR_SIZE)

    $console.cursor(1, EXT_DESCR_LINE+1)
    $console.pause('TODO') # TODO

    (1..EXT_OPTIONS_LEN).each {|i| $console.attr_pos(5, i, STYLE_NORMAL, 54)} # cancel both highlight and dim display
    printDefaultDescr()
    return true
  rescue TSWKaiError => e
    if e.is_a?(::Console::STDINCancelError) # pressed arrow key to go to another item
      if c # an item already highlighted, then go to a different item
        case e.arrow
        when VK_UP, VK_LEFT
          @curInd = (c-2) % EXT_OPTIONS_LEN
        when VK_DOWN, VK_RIGHT
          @curInd = c % EXT_OPTIONS_LEN
        end
      end # otherwise, highlight the last chosen item
      @nxtInd = @curInd
      return true
    elsif c # TSW quitted; the choice has been made and is currently inputting values
      (1..EXT_OPTIONS_LEN).each {|i| $console.attr_pos(5, i, STYLE_NORMAL, 54)} # cancel both highlight and dim display
      printDefaultDescr()
    end
    return ! e.is_a?(TSWQuitedError) # stop if TSW has quitted
  end

  def initInterface()
    $console.resize() # in case the windows size is changed
    $console.cls()
    $str::STRINGS[51].each_with_index {|x, i| $console.print_pos(1, i+1, x)} # \r\n does not seem to be properly treated as line breaks using `WriteConsoleOutputCharacter`, so have to do this line by line
    $console.p_rect(2, 1, 1, EXT_OPTIONS_LEN, EXT_OPTIONS, STYLE_B_YELLOW_U)
    $console.cls_pos(0, EXT_OPTIONS_LEN+1, ::Console::CONSOLE_WIDTH, false, 95) # '_'.ord
    $console.cursor(1, EXT_OPTIONS_LEN+3)
    $console.fprint(STYLE_B_YELLOW_U, $str::STRINGS[52][0])
    printDefaultDescr()
  end

  def printDefaultDescr()
    $console.cls_pos(0, EXT_DESCR_LINE, EXT_DESCR_SIZE)
    $console.cursor(1, EXT_DESCR_LINE+1)
    $console.print($str::STRINGS[52][1])
    $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[52][2])
  end

  def main()
    @curInd = 0
    @nxtInd = nil
    $console = ::Console.new if $console.nil?
    Kai.need_init() # since the console is used here in tswExt, the interface of tswKai needs redrawing in the future
    if $console.switchLang() or @need_init # if language has been changed, or the console interface has been used in tswExt module, need to redraw the whole interface
      @need_init = false
      initInterface()
    end
    $console.setConWinProp(false)
    return if $console.show(true).nil? # fail

    $console.SE.selection()
    res = nil
    loop { break unless (res=ExtMain()) }
    $console.show(false) if res.nil? # ESC pressed
    # otherwise, if res==false (TSW quitted), the remainder will be processed in the main loop
  end
end

# ====================================================================================
# the second half of this script file deals with permanent on-map damage display, etc.
require 'tswMPDat' # given the huge size of opcodes, it is stored in binary format in this separate file

DRAW_HERO_ADDR = 0x4808b4
DRAW_HERO_2_ADDR = 0x480908
ERASE_AND_DRAW_HERO_ADDR = 0x480834

DPL_ADDR = 0x4bac68
EPL_ADDR = 0x4bad0c
POLYLINE_COUNT_ADDR = 0x489de5
POLYLINE_VERTICES_ADDR = 0x489e00

module MPExt
  @_tswMPExt_enabled = 0x4ba1b5
  @_always_show_overlay = 0x4ba1b7
  @_sub_ini = 0x4ba558
  @_sub_res = 0x4ba668
  @_sub_fin = 0x4ba6bc

  module_function
  def init
    MP_PATCH_BYTES_1.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}

    callFunc(@_sub_fin) # this is just to guarantee no GDI leak, in case the previous run of tswKai3 failed to clean up on exit
    if $MPnewMode
      changeState()
      callFunc(@_sub_ini)
    else
      WriteProcessMemory.call_r($hPrc, @_tswMPExt_enabled, "\0", 1, 0)
    end

    MP_PATCH_BYTES_2.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}
    MP_PATCH_BYTES_3.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}
  end
  def changeState
    WriteProcessMemory.call_r($hPrc, @_always_show_overlay, $MPshowMapDmg ? ($MPshowMapDmg == 1 ? "\1" : "\0") : "\xFF", 1, 0)
  end
  def finalize
    callFunc(@_sub_res) if ($MPnewMode == true) # do nothing if $MPnewMode==1
  end
end
