#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# generate Ruby script archive for Exerb
# See also: {exerb}/archive.rb; {exerb}/name_table.rb; {exerb}/file_table.rb
# where {exerb} = https://github.com/Z-H-Sun/exerb-mingw/blob/master/lib/exerb

require 'zlib'
ZLIB_COMPRESS_LEVEL = 9 # 0 means no compression; otherwise 1-9 (higher = smaller size)

FILEINPUTPATH = '../' # change rb path here
FILEOUTPUT = 'tswKai3.exa' # change output archive filename here
FILELIST = Dir.chdir('../') {|i| Dir['main.rbw'] + Dir['*.rb'] } # main.rbw must be placed first
# %w(main.rbw common.rb connectivity.rb console.rb gui.rb monsters.rb strings.rb stringsGBK.rb tswBGM.rb tswKai.rb tswMP.rb tswMod.rb tswModStatic.rb tswSL.rb)

PATCH_FILE_IGNORE = [] # no need to patch these files file
PATCH_PATTERN = {/require.+win32.api.*$/ => '', # need to remove this `require` as win32/api has been hard-compiled in our executable
  /^ *#+.*$/ => '', / *# +.*$/ => '', /^ +/ => ''} # no need to include annoations / indentations

@alignedLen = 0
def alignment16(bin)
  s = bin.size
  remainder = alignment16_remainder_len(s)
  @alignedLen = s+remainder
  return bin << "\0" * remainder
end
def alignment16_remainder_len(len)
  return 15-((len-1) & 0xF) # (len % 16).zero? 0 : (16 - (len%16))
end
def get_file_data(filename, fileIO)
  unless PATCH_FILE_IGNORE.include?(filename) # start patching
    d = ''
    fileIO.each_line do |l|
      PATCH_PATTERN.each do |k|
        l.sub!(k[0], k[1])
      end
      d << l
    end
  else # directly read
    d = fileIO.read
  end
  return Zlib::Deflate.deflate(d, ZLIB_COMPRESS_LEVEL)
end

name_table_entry_header = ''
name_table_name_index = 0
name_table_name_offset = 0
FILELIST.each {|fn| name_table_entry_header << [(name_table_name_index+=1), name_table_name_offset].pack('SL') # index(S), offset_name_table_entry(L)
  name_table_name_offset += fn.size+1}
alignment16(name_table_entry_header)
name_table_entry_offset = 0x10+@alignedLen
name_table_header = ["NT\0\1", FILELIST.size, 0x10, name_table_entry_offset, # signature(a4), num_header(S), offset_header(L), offset_name(L)
  0].pack('a4SLLS')
name_table_entry = FILELIST.join("\0")
alignment16(name_table_entry)
file_table_offset = 0x20+name_table_entry_offset+@alignedLen
archive_header = ["EXERB\0\0\4", 0, 0x20, file_table_offset, # signature(a8), kcode(L), offset_name_table(L), offset_file_table(L)
  0, 0].pack('a8LLLLQ')

file_table_entry = ''
file_table_entry_header = ''
file_table_file_index = 0
file_table_file_offset = 0
FILELIST.each {|fn| open(FILEINPUTPATH+fn, 'rb') {|f| d = get_file_data(fn, f)
  file_table_entry_header << [(file_table_file_index+=1), file_table_file_offset, d.size, 1, 1].pack('SLLCC') # index(S), offset_file_table_entry(L), size_file(L), flag_file(C), flag_zipd(C) [FLAG_TYPE_RUBY_SCRIPT=1; FLAS_ZLIB_COMPRESSED=1]
  file_table_entry << alignment16(d)
  file_table_file_offset += @alignedLen}}
alignment16(file_table_entry_header)
file_table_entry_offset = 0x10+@alignedLen
file_table_header = ["FT\0\4", FILELIST.size, 0x10, file_table_entry_offset, # signature(a4), num_header(S), offset_header(L), offset_file(L)
  0].pack('a4SLLS')

$EXA_DATA = archive_header + name_table_header + name_table_entry_header + name_table_entry + file_table_header + file_table_entry_header + file_table_entry

if __FILE__ == $0 or $WRITE_EXA
  f_out = open(FILEOUTPUT, 'wb')
  f_out.write($EXA_DATA)
  f_out.close
end
