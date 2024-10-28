#!/usr/bin/env ruby
# Author: Z.Sun
# Prerequisites: devkit; rake; git; autoconf; make; bison; windres; gcc

require 'devkit'
require 'rake'

# If you are using a 64bit Ruby, it is critical that you sepecify the below two parameters. Ex: rake M32DIR=C:\msys64\mingw32\bin M32CC=gcc
CC = ENV['M32CC'] || RbConfig::CONFIG['CC'] || 'gcc' # this must be a 32bit GCC!
MINGW32_PATH = ENV['M32DIR'] # the entire toolchain must be 32bit! Should specify path to these binary executables here, especially for 64bit Ruby, since `devkit` package will prepend 64bit ruby devkit path
ENV['PATH'] = MINGW32_PATH+';'+ENV['PATH'] if MINGW32_PATH
EXERB_CFLAGS = '-std=gnu99 -Os -g0 -s -mwindows -fcommon -DNDEBUG -DHAVE_STATIC_ZLIB  -Wl,--stack=0x02000000,--wrap=rb_require_safe,--wrap=rb_require,--wrap=Init_ExerbRuntime,--wrap=exerb_main' # -fcommon switch should be on for gcc > 10 (because variables `rb_load_path`, `rb_progname`, and `rb_argv0` in 'exerb.c' will conflict with those defined in Ruby static library); see https://stackoverflow.com/a/67272728/11979352

# ================ Ruby
RUBY_CFLAGS = '-std=gnu99 -Os -g0 -DNDEBUG -DRUBY_EXPORT -DFD_SETSIZE=256 -DIN_WINPTHREAD -w -fpermissive -fgnu89-inline' # defining `IN_WINPTHREAD` is because `clock_gettime` is not yet supported in this version of mingw-w64, so do not include 'pthread_time.h' (see https://bugs.launchpad.net/epics-base/+bug/1492884); the `-fpermissive`` switch is added because high version gcc will by default turn the following warnings into error: implicit-function-declaration, incompatible-pointer-types, and implicit-int, which can be turned off by multiple `-Wno-error=XXX`` individually (see https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html); the `-fgnu89-inline` switch is added to avoid high version gcc throwing "undefined reference to `rb_reserved_word'" error in 'parse.c' and 'lex.c' (see https://stackoverflow.com/a/12747536 and also https://github.com/ruby/all-ruby/pull/9)
RUBY_C_IGNORE = %w(./main.c win32/winmain.c ./parse.c ./lex.c ./dmydln.c)
RUBY_C_NEEDED = %w(missing/crypt.c)
RUBY_O_LIST = ['../../tmp/parse.o'] # this will be prepended later
RUBY_LIBS = '' # this will be prepended later

def compile_c(target, source)
  file(target => source) { sh "#{CC} #{RUBY_CFLAGS} -I. -I./missing -I./win32 -c -o #{target} #{source}" }
end
def get_ruby_libs(makefile)
  open(makefile, 'rb').each_line { |l|
    next unless l[/^\s*(EXT|)LIBS\s*=\s*(.*)/] # LIBS=... or EXTLIBS=...
    $2.split().each {|i| RUBY_LIBS << ' '+i unless i[0, 1]=='$'} # do not include $(...)
  }
  puts 'For Ruby compilation: LIBS =' + RUBY_LIBS
end

directory '../tmp'
file '../vendor/ruby' do # 1.8.7; the latest version w/o encoding
  cd('../vendor') { sh 'git clone https://github.com/ruby/ruby.git -b ruby_1_8_7 --depth=1' }
end
file '../vendor/ruby/config.h' => '../vendor/ruby' do
  if File.exist?('../vendor/ruby/config.h') and File.exist?('../vendor/ruby/Makefile')
    puts 'For Ruby compilation: config.h and Makefile already exists; skipped.'
    next
  end
  cp_r('ruby_configure.sh', File.expand_path('../vendor/ruby'))
  cd('../vendor/ruby') { sh 'sh ./ruby_configure.sh' }
end
task :compile_ruby
task :prep_ruby => ['../vendor/ruby/config.h', '../tmp'] do
  cd '../vendor/ruby'
  get_ruby_libs('Makefile')
  file('parse.c' => 'parse.y') { sh 'bison parse.y -o parse.c' }
  compile_c('../../tmp/parse.o', 'parse.c')
  c_list = Dir['{win32,.}/*.c'] - RUBY_C_IGNORE + RUBY_C_NEEDED
  c_list.each { |i|
    o = "../../tmp/#{File.basename(i)[0...-1]}o"
    compile_c(o, i)
    RUBY_O_LIST << o}
  task :compile_ruby => RUBY_O_LIST
end
file 'libruby187.a' => [:prep_ruby, :compile_ruby] do
  rm_f '../../compile/libruby187.a'
  sh 'ar q ../../compile/libruby187.a ' + RUBY_O_LIST.join(' ')
  cd '../../compile'
end

# ================ Zlib
file '../vendor/zlib' do # 1.3; latest version
  cd('../vendor') { sh 'git clone https://github.com/madler/zlib.git -b v1.3 --depth=1' }
end
file 'libz.a' => ['../vendor/zlib', '../tmp'] do
  cd('../vendor/zlib') do
    if File.exists?('configure.log') then puts 'For Zlib compilation: configured before; skipped.' else sh 'sh ./configure' end
    sh 'make'
    mv 'libz.a', '../../compile'
    sh 'make clean'
  end
end

# ================ Exerb
file '../vendor/exerb-mingw' do
  cd('../vendor') { sh 'git clone https://github.com/Z-H-Sun/exerb-mingw.git -b static_zlib_test --depth=1' }
end

desc "Compile"
task :default => '../vendor/exerb-mingw' do
  if File.exist?('libruby187.a') and File.exist?('../vendor/ruby/config.h') and File.exist?('../vendor/ruby/Makefile')
    get_ruby_libs('../vendor/ruby/Makefile')
    puts 'Ruby static library already exists; skipped.'
  else
    puts 'Start compiling Ruby...'
    Rake::Task['libruby187.a'].invoke
  end
  if File.exist?('libz.a')
    puts 'Zlib static library already exists; skipped.'
  else
    puts 'Start compiling Zlib...'
    Rake::Task['libz.a'].invoke
  end
  e_path = '../vendor/exerb-mingw/src/exerb'
  cp 'config.h', e_path
  $WRITE_EXA = true # see `mkexa.rb`; explicitly ask to output .exa file
  load('mkexa.rb', wrap=true)
  sh "windres resource.rc res.o"
  sh "#{CC} -Wall #{EXERB_CFLAGS} -I../vendor/ruby -I../vendor/ruby/missing -I../vendor/ruby/win32 -I../vendor/zlib -I. -L. -o ../tswKai3.exe #{e_path}/gui.c res.o #{e_path}/exerb.c #{e_path}/module.c #{e_path}/utility.c #{e_path}/patch.c ../vendor/exerb-mingw/vendor/zlib.c  ../vendor/win32/api.c -lruby187 -lz #{RUBY_LIBS}"
# sh "strip -R .reloc ../tswKai3.exe" # stop doing `strip` here because the reduced size of the executable is minimal, yet this can sometimes cause a severe bug: for tswKai3.exe compiled by high version gcc, this will cause error 0xc0000005 during startup
  puts 'Generated ../tswKai3.exe successfully.'
end

if __FILE__ == $0
  Rake::Task['default'].invoke
  system('pause'); exit
end

require 'rake/clean'
CLEAN.include('*.a')
CLEAN.include('*.exa')
CLEAN.include('res.*')
CLEAN.include('../tmp')
CLOBBER.include('../*.exe')
CLOBBER.include('../vendor/ruby')
CLOBBER.include('../vendor/zlib')
CLOBBER.include('../vendor/exerb-mingw')
CLOBBER.include('../win32')
