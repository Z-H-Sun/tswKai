#!/usr/bin/env ruby
# Author: Z.Sun

require 'devkit'
require 'rake'

module FuncTest # to avoid namespace polution for Ruby < 2
  require 'mkmf'
  $strncpy_s = '-DHAVE_STRNCPY_S' if have_func('strncpy_s')
end

open('api.def', 'w') {|f| f.write 'EXPORTS
Init_api
'}

CFG = RbConfig::CONFIG
cc = CFG['CC']
cflags = '-Os'
incflags = CFG['rubyhdrdir'] ? "-I#{CFG['rubyhdrdir']}/#{CFG['arch']} -I#{CFG['rubyhdrdir']}" : "-I#{CFG['archdir']}"
ldflags = "-L#{CFG['libdir']}"
cppflags = CFG['CPPFLAGS']
librubyarg = CFG['LIBRUBYARG_SHARED']
libs = CFG['LIBS']

sh "#{cc} #{cflags} #{incflags} #{ldflags} #{$strncpy_s} #{cppflags} -fno-omit-frame-pointer -shared -s -o api.so api.c -Wl,--enable-auto-image-base,--enable-auto-import api.def #{librubyarg} #{libs}"
system "pause"
