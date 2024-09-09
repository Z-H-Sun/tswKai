#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: tswMPExt_*.asm

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
