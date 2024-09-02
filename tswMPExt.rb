#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: tswMPExt_*.asm

require 'tswMPDat' # given the huge size of opcodes, it is stored in binary format in this separate file

module MPExt
  @_tswMP_overlay_enabled = 0x4ba1b5
  @_always_show_overlay = 0x4ba1b7
  @_sub_ini = 0x4ba558
  @_sub_res = 0x4ba668
  @_sub_fin = 0x4ba6bc

  module_function
  def init
    MP_PATCH_BYTES_1.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}

    callFunc(@_sub_fin) # this is just to guarantee no GDI leak, in case the previous run of tswKai3 failed to clean up on exit
    if $MPshowMapDmg and $MPnewMode
      WriteProcessMemory.call_r($hPrc, @_always_show_overlay, $MPshowMapDmg == 1 ? "\1" : "\0", 1, 0)
      callFunc(@_sub_ini)
    else
      WriteProcessMemory.call_r($hPrc, @_tswMP_overlay_enabled, "\0", 1, 0)
    end

    MP_PATCH_BYTES_2.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}
  end
  def changeState
    if !$MPshowMapDmg # s=1 (checked) --> s=0 (unchecked)
      WriteProcessMemory.call_r($hPrc, @_always_show_overlay, "\0", 1, 0)
      callFunc(@_sub_res)
    elsif $MPshowMapDmg == 1 # s=2 (intermediate) --> s=1 (checked)
      WriteProcessMemory.call_r($hPrc, @_always_show_overlay, "\1", 1, 0)
    else # s=0 (unchecked) --> s=2 (intermediate)
      callFunc(@_sub_ini)
    end
  end
  def finalize
    callFunc(@_sub_res) if $MPshowMapDmg and ($MPnewMode == true) # do nothing if $MPnewMode==1
  end
end
