BASE_ADDRESS = 0x400000
AUTO_REFRESH_FLAG = 0x7d2dd + BASE_ADDRESS
OFFSETS = [0xb8688, 0xb868c, 0xb8690, 0xb8694, 0xb8698, 0xb869c, 0xb86a0, 0xb86a4,
           0xb86a8, 0xb86b0, 0xb86ac, 0xb86c4, 0xb86c8, 0xb86cc, 0xb86d0, 0xb86d4,
           0xb86d8, 0xb86dc, 0xb86e0, 0xb86e4, 0xb86e8, 0xb86ec, 0xb86f0, 0xb86f4,
           0xb86f8, 0xb86fc, 0xb8700, 0xb8704]
OPTIONS = ['L', 'O', 'N', 'G', 'F', 'H', 'X', 'Y', 'K', 'U', 'R', 'S', 'I', '0', '1',
           '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E']
LONGNAMES = ['"L"ife', '"O"ffense', 'Defe"n"se', '"G"old', '"F"loor', '"H"ighest',
             '"X"-pos', '"Y"-pos', 'Yel"K"ey', 'Bl"u"eKey', '"R"edKey', '"S"word',
             'Sh"i"eld', 'OrbHero   "0"', 'OrbWisdom "1"', 'OrbFly    "2"',
             'Cross     "3"', 'Elixir    "4"', 'Mattock   "5"', 'BombBall  "6"',
             'SpaceWing "7"', 'UpperWing "8"', 'LowerWing "9"', 'DragonSl  "A"',
             'SnowFlake "B"', 'MagicKey  "C"', 'SuperMatk "D"', 'LuckyGold "E"']
$values = Array.new(29){"\0"*4} # pointers of the variables
$bytesRead = '    ' # pointers of the number of read bytes
$handle = 0 # handle of the opened process

`mode con cols=70 lines=15`
`chcp 437`
`title tswKai - init`
require 'Win32API'
OpPrc = Win32API.new('kernel32', 'OpenProcess', 'lll', 'l')
RdPrc = Win32API.new('kernel32', 'ReadProcessMemory', 'llplp', 'l')
WtPrc = Win32API.new('kernel32', 'WriteProcessMemory', 'llplp', 'l')
ClHdl = Win32API.new('kernel32', 'CloseHandle', 'l', 'l')
LstErr = Win32API.new('kernel32', 'GetLastError', '', 'l')
SndMsg = Win32API.new('user32', 'SendMessage', 'lllp', 'l')
PROCESS_VM_WRITE = 0x20
PROCESS_VM_READ = 0x10
PROCESS_VM_OPERATION = 0x8

def getch(choice=nil) # user input
  if choice.nil?
    return `cmd /V /C "set /p var=&& echo !var!"`.chomp # STDIN.gets will not work after calling `choice`
  else
    return `choice /C #{choice} /N`.chomp
  end
rescue Interrupt # Ctrl-C
  return -1
end
def int(str)
  return str if str.is_a? Integer
  return str[0, 2] == '0x' ? str[2..-1].to_i(16) : str.to_i 
end
def reeval()
  system('cls')
  for i in 0..27
    print LONGNAMES[i].ljust(20).sub(/\"(.)\"/, "\e[4;1;33m\\1\e[0m")
    if RdPrc.call($handle, BASE_ADDRESS+OFFSETS[i], $values[i], 4, $bytesRead).zero? # read memory
      print "\e[1;31mErr 0x#{LstErr.call.to_s(16).rjust(4, '0')}\e[0m"
    else
      print $values[i].unpack('l')[0].to_s.rjust(10)
    end
    print (i%2).zero? ? ' '*12 : "\n" # format
  end
  print "Refresh   \e[4;1;33mZ\e[0m"+' '*16

end
def refresh() # main
  reeval
  if (c = getch(OPTIONS.join+'Z')).to_i < 0
    ClHdl.call($handle) # release resource
    print "\a"; system('pause'); exit
  end
  if c != 'Z'
    reeval
    c = OPTIONS.index(c)
    print "\e[#{c/2+1};#{c%2*41}H" # move cursor to pos
    print "\e[7m"
    print LONGNAMES[c].gsub('"', '').ljust(7)[0..8]
    print "(0-"
    oldVal = $values[c].unpack('l')[0].to_s.rjust(10) + "\e[0m" + "\b"*10
    case c
    when 0..3, 8..10
      print '2^31-1):' + oldVal
      v = int(getch)
      if v >= 2**31 then v = 2**31-1; print "\a" end
    when 4..5
      print '50):    ' + oldVal
      v = int(getch)
      if v > 50 then v = 50; print "\a" end
    when 6..7
      print 'A):     ' + oldVal
      v = getch('0123456789A').to_s.to_i(16)
    when 11..12
      print '5):     ' + oldVal
      v = getch('012345').to_i
    when 20
      print '3):   ' + oldVal
      v = getch('0123').to_i
    else
      print '1):   ' + oldVal
      v = getch('01').to_i
    end
    print "\a" # beep
    unless v < 0
      print "\e[#{c/2+1};#{c%2*40+19}H"
      if WtPrc.call($handle, BASE_ADDRESS+OFFSETS[c], [v].pack('l'), 4, $bytesRead).zero? # write memory
        print "\e[7;31mErr 0x#{LstErr.call.to_s(16).rjust(4, '0')}\e[0m"
        `pause`
      end
      unless $hwnd.zero? # TSW window is found
        RdPrc.call($handle, AUTO_REFRESH_FLAG, $values[28], 1, $bytesRead) # check tswMP flag
        SndMsg.call($hwnd, 0x111, 54, 0) if $values[28]=="\xc3\0\0\0" # refresh
      end
    end
  end
  print "\a"; refresh
end

$hwnd = Win32API.new('user32', 'FindWindow', 'pi', 'l').call('TTSW10', 0)
$pid = "\0\0\0\0"
Win32API.new('user32', 'GetWindowThreadProcessId', 'lp', 'l').call($hwnd, $pid)
$pid = $pid.unpack('L')[0]
if $pid.zero?
  system('title tswKai - err')
  print "\e[1;33mCan`t find a process of TSW\e[0m. Please manually enter its PID: "
  $pid = int(getch)
  if $pid <= 0 then system('pause'); exit end
  print "Please manually enter its hWnd (optional): "
  $hwnd = int(getch)
  $hwnd = 0 if $hwnd == -1
end
`title tswKai - PID=#{$pid}`
$handle = OpPrc.call(PROCESS_VM_WRITE | PROCESS_VM_READ | PROCESS_VM_OPERATION, 0, $pid) # open process
if $handle.zero?
  print "\e[1;31mCan`t open process #{$pid}: Err 0x#{LstErr.call.to_s(16)}.\e[0m "
  system('pause'); exit
end
refresh
