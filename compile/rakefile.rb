#!/usr/bin/env ruby
# Author: Z.Sun
# Prerequisites: devkit; rake; git; autoconf; make; bison; sed; windres; gcc

require 'devkit'
require 'rake'

CC = ENV['CC'] || RbConfig::CONFIG['CC'] || 'gcc' # this must be a 32bit GCC!
EXERB_CFLAGS = '-std=gnu99 -Os -g0 -s -mwindows -DNDEBUG -DRUBY_EXPORT -DHAVE_STATIC_ZLIB  -Wl,--stack=0x02000000,--wrap=rb_require_safe,--wrap=rb_require'

# ================ Ruby
RUBY_CFLAGS = '-std=gnu99 -Os -g0 -DNDEBUG -DRUBY_EXPORT -DFD_SETSIZE=256'
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
    sh 'sh ./configure' unless File.exists?('Makefile')
    sh 'make'
    mv 'libz.a', '../../compile'
    cp 'zconf.h', '../../compile'
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
  if File.exist?('libz.a') and File.exist?('zconf.h')
    puts 'Zlib static library already exists; skipped.'
  else
    puts 'Start compiling Zlib...'
    Rake::Task['libz.a'].invoke
  end
  e_path = '../vendor/exerb-mingw/src/exerb'
  cp 'config.h', e_path
  sh 'sed -i \'s/^\s*Init_Exe/void Init_api();\nInit_api();\nInit_Exe/g\' '+e_path+'/exerb.c' # patch exerb.c to initialize win32/api extension
  load('mkexa.rb' ,wrap=true)
  sh "windres resource.rc res.o"
  sh "#{CC} -Wall #{EXERB_CFLAGS} -I../vendor/ruby -I../vendor/ruby/missing -I../vendor/ruby/win32 -I../vendor/zlib -I. -L. -o ../tswKai3.exe #{e_path}/gui.c res.o #{e_path}/exerb.c #{e_path}/module.c #{e_path}/utility.c #{e_path}/patch.c ../vendor/exerb-mingw/vendor/zlib.c  ../vendor/win32/api.c -lruby187 -lz #{RUBY_LIBS}"
  sh "strip -R .reloc ../tswKai3.exe"
  puts 'Generated ../tswKai3.exe successfully.'
end

if __FILE__ == $0
  Rake::Task['default'].invoke
  system('pause'); exit
end

require 'rake/clean'
CLEAN.include('*.a')
CLEAN.include('*.exa')
CLEAN.include('zconf.h')
CLEAN.include('res.*')
CLEAN.include('../tmp')
CLOBBER.include('../*.exe')
CLOBBER.include('../vendor/ruby')
CLOBBER.include('../vendor/zlib')
CLOBBER.include('../vendor/exerb-mingw')
CLOBBER.include('../win32')
