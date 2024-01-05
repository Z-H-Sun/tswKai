#!/usr/bin/env ruby
# Author: Z.Sun
# Load or add/update the manifest resource in the designated executable file
# If things don't work out, try `updateExe` instead

$: << '..'
require 'win32/api'
include Win32
module Win32
  class API
    unless defined?(self.last_error) # low version win32/api support
      def self.last_error; API.new('GetLastError', 'V', 'I', 'kernel32').call(); end
    end
    def call_r(*argv) # provide more info if a win32api returns null
      r = call(*argv)
      return r unless r.zero?
      err = API.last_error
      if err == ERROR_RESOURCE_TYPE_NOT_FOUND and function_name == 'FindResource'
        STDERR.puts('* Warning: No manifest resource found in this file.')
        exit
      end
      STDERR.puts('* Error: Err 0x%04X when calling `%s`@%s, which returns NULL.
  Possible reasons:
  - The input filename contains ".." (to indicate a relative path) or forward slashes (/, as path separators); they should be avoided.
  - You are using a 64-bit Ruby to load a 32-bit executable, or the other way around.
  - The executable you are using is currently in use (e.g., running).
  - The executable does not have the MANIFEST resource.

  Prototype="%s"; ReturnType="%s"; ARGV=%p' % [err, effective_function_name, dll_name, prototype.join(''), return_type, argv])
      exit(1)
    end
  end
end

LANG_NEUTRAL = 0
SUBLANG_DEFAULT = 1
ID_MANIFEST = 1
RT_MANIFEST = 24
ERROR_RESOURCE_TYPE_NOT_FOUND = 0x715
DEFAULT_LANG_ID = LANG_NEUTRAL | (SUBLANG_DEFAULT << 10) # MAKELANGID
LoadLibrary = API.new('LoadLibrary', 'S', 'L', 'kernel32')
FreeLibrary = API.new('FreeLibrary', 'L', 'L', 'kernel32')
BeginUpdateResource = API.new('BeginUpdateResource', 'SI', 'L', 'kernel32')
EndUpdateResource = API.new('EndUpdateResource', 'LI', 'L', 'kernel32')
UpdateResource = API.new('UpdateResource', 'LIIIPI', 'I', 'kernel32')
FindResource = API.new('FindResource', 'LII', 'L', 'kernel32')
LoadResource = API.new('LoadResource', 'LL', 'L', 'kernel32')
LockResource = API.new('LockResource', 'L', 'L', 'kernel32')
SizeofResource = API.new('SizeofResource', 'LL', 'I', 'kernel32')
RtlMoveMemory = API.new('RtlMoveMemory', 'PLI', 'V', 'kernel32')

buf = "\0" * 1048576 # this size (1 MB) should be large enough

unless $*[0]
  puts "Usage: #{File.basename($0)} <exe filename> [<manifest filename>]

- Use an absolute path for the <exe filename>.
- If the manifest filename is provided, the <exe>'s manifest resource will be replaced by the contents of <manifest>.
Otherwise, its contents will be read and printed, and you can use `> 1.manifest` to redirect the contents to a file."
  exit
end

mode = $*[1] ? 1 : 0 # write; load
if mode.zero?
  hMod = LoadLibrary.call_r($*[0])
  STDERR.puts '* Successfully loads %s (@%d).' % [$*[0], hMod]
  hRes = FindResource.call_r(hMod, ID_MANIFEST, RT_MANIFEST)
  STDERR.puts '* Successfully finds a manifest resource (@%d).' % hRes
  hGlb = LoadResource.call_r(hMod, hRes)
  lenRes = SizeofResource.call_r(hMod, hRes)
  lpRes = LockResource.call_r(hGlb)
  STDERR.puts '* Successfully loads the resource with a length of %d (@%d).' % [lenRes, lpRes]
  RtlMoveMemory.call(buf, lpRes, lenRes)
  STDERR.puts '* Successfully obtained the data.'
  puts buf[0, lenRes]
  FreeLibrary.call_r(hMod)
else
  d = open($*[1], 'rb') {|f| f.read}
  hUpdt = BeginUpdateResource.call_r($*[0], 0)
  UpdateResource.call_r(hUpdt, RT_MANIFEST, ID_MANIFEST, LANG_NEUTRAL, d, d.size)
  EndUpdateResource.call_r(hUpdt, 0)

  hUpdt = BeginUpdateResource.call($*[0], 0) # this needs to be a separate loop, otherwise might fail (see https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-updateresourcea#remarks)
  UpdateResource.call(hUpdt, RT_MANIFEST, ID_MANIFEST, DEFAULT_LANG_ID, nil, 0) # delete the manifest resource with the 0400 (Process Default Lang) lang ID, if exist, for the compiled tswKai3.exe
  EndUpdateResource.call(hUpdt, 0)

  STDERR.puts '* Successfully replaced the manifest resource.'
end
