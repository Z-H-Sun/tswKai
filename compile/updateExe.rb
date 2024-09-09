#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# update resources in tswKai3.exe

BEGIN {
EXEFILE = '../tswKai3.exe' }
EXA = Exerb::Resource::RT_EXERB # set to `nil` if you don't want to update ruby scripts in tswKai3.exe [Note: this value was 100 for old exerb versions and has become 10 for recent versions. Choose the right one according to which version was used to create the `EXEFILE` executable file!]
ICOFILE = {'../1.ico' => # new icon to replace (set to `nil` if not needed)
  [[256, 256, 32], # width, height, color depth
    [48,  48, 32],
    [16,  16, 32]]}
MANFILE = '../tswKai3.exe.MANIFEST'
VER = [3, 2, 2, 0] # new version number to assign (set to `nil` if not needed)

BEGIN {
  begin
    $:.unshift '../vendor/exerb-mingw/lib' # prefer not using user-installation of exerb; might be outdated
    require 'rubygems'
    require 'exerb/executable'
    open(EXEFILE, 'r+').close
  rescue Exception
    puts 'Unable to find the exerb module or open tswKai3.exe for write.
Rerunning `rake` may solve this problem.'
    system('pause'); exit
  end
}

def make_version(v)
  [v[1], v[0], v[3], v[2]].pack('S4')
end

def make_icon(rsrc, id, ico, entries)
  group_icon = Exerb::Resource::GroupIcon.new
  index = id*100
  entries.each { |entry|
    icon = Exerb::Resource::Icon.read(ico, entry[0], entry[1], entry[2])
    rsrc.add(Exerb::Win32::Const::RT_ICON, index += 1, icon)
    group_icon.add(index, icon)
  }

  rsrc.add(Exerb::Win32::Const::RT_GROUP_ICON, id, group_icon)
end


executable = Exerb::Executable.read(EXEFILE)

if VER
  version_bin = executable.rsrc.entries[Exerb::Win32::Const::RT_VERSION][1][Exerb::Resource::DEFAULT_LANG_ID].data.pack
  base = version_bin.index([Exerb::Win32::Const::VS_FFI_SIGNATURE].pack('L'))
  version_bin[base+8, 8] = make_version(VER) # file version
  version_bin[base+16, 8] = make_version(VER) # product version
end
if ICOFILE
  executable.rsrc.remove(Exerb::Win32::Const::RT_ICON)
  executable.rsrc.remove(Exerb::Win32::Const::RT_GROUP_ICON)

  id = 0
  ICOFILE.each { |i| make_icon(executable.rsrc, id+=1, i[0], i[1]) }
end
if MANFILE
  RT_MANIFEST = 24
  executable.rsrc.add(RT_MANIFEST, 1, Exerb::Resource::Binary.new(open(MANFILE, 'rb') {|f| f.read}))
end
if EXA
  $:.unshift '.'
  require 'mkexa' # get exa data (stored in $EXA_DATA) from updated ruby scripts
  executable.rsrc.add(EXA, Exerb::Resource::ID_EXERB, Exerb::Resource::Binary.new($EXA_DATA))
end

executable.write(EXEFILE)
puts "Updated #{EXEFILE} successfully."
system('pause')
