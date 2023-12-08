# encoding: ASCII-8Bit
# CHN strings encoding is UTF-8

require 'stringsGBK'

$isCHN = false
$str = Str::StrEN

module Str
  @strlen = 0
  module StrEN
    LONGNAMES = ['Life Pt (HP)', 'Offense(ATK)', 'Defense(DEF)', 'Gold Count', 'CurrentFloor', 'HighestFloor', 'X Coordinate', 'Y Coordinate', '(Yellow) Key', 'Blue Key', 'Red  Key', 'Altar Visits',
'Weapon(Sword)', 'Shield Level', 'OrbOfHero', 'OrbOfWisdom', 'OrbOfFlight', 'Cross', 'Elixir', 'Mattock', 'DestructBall', 'WarpWing', 'AscentWing', 'DescentWing', 'DragonSlayer', 'SnowCrystal', 'MagicKey', 'SuperMattock', 'LuckyGold']
    STRINGS = [
APP_NAME+': Please wait for game event to complete...', # 0
APP_NAME+': Click the mouse to teleport to (%X,%X)%s',
APP_NAME+': Move the mouse to choose a destination to teleport.',
APP_NAME+': (%X,%X) is inaccessible. Move the mouse to choose a different destination.',
APP_NAME+': Press an alphabet/arrow key to use the corresponding item.',
APP_NAME+': Teleported to (%X,%X). Move the mouse to continue teleporting%s', # 5
', or press a key to use an item.',
APP_NAME+': Use arrow keys to fly up/down; release the [WIN] or [TAB] key to confirm.',
APP_NAME+': YOU HAVE CHEATED AT THE GAME!',
APP_NAME+': Started. Found TSW running - pID=%d; hWnd=0x%08X',
APP_NAME+': Could not use %s!', # 10
APP_NAME+' is running. Here is a summary of the usage:

When the [WIN] or [TAB] hotkey is down:
1) Move the mouse and then click to teleport in the map
   (Right click = cheat);
2) Press a specified alphabet key to use an item or any
   arrow keys to use Orb of Flight (Up arrow = cheat).

When holding the hotkey, you can also see:
* the next critical value and damage of each monster and
* other useful data (if you hover the mouse on a monster)
on the map and in the status bar if you have Orb of Hero.

Use hotkeys to enhance the Load/Save function:
* Ctrl+L       	= Load data from any file;
* Ctrl+S       	= Save data to any file;
* Bksp         	= Rewind to the prev snapshot;
* Shift+Bksp   	= Fast-forward to next snapshot.

In addition, you can:
Press F8 once  	= Open cheat console;
Double press F7	= Re-register hotkeys if they stop working;
Hold F7        	= Quit tswKai3.',
'Re-registered [WIN] and [TAB] hotkeys.',
APP_NAME+' has stopped.',
'DMG:%s = %s * %sRND | %dG%s',
' | PrevCRI:%s', # 15
' | NextCRI:%s',

'You just obtained Sacred Shield. Do you want to arm it
to screen you from the magic attacks of wizards?',
'You have Sacred Shield but just switched to a lower level
shield. Do you want to disarm Sacred Shield, though you will
no longer be able to resist the magic attacks from wizards?',
'Refresh List   Press ESC to leave',

'-- tswKai3 --  
Waiting for   
TSW to start ', # 20
'Do you want to stop waiting for the TSW game to start?

Choose "Yes" to quit this app; "Cancel" to do nothing;
"No" to continue waiting but hide this status window,
and you can press F7 or F8 to show it again later.',
'The TSW game process has ended. Do you want to put this
app to hibernate and wait for the next TSW game?',

'The path for the mp3 BGM files is %s.
The BGM enhancement function will be turned off.',
'The game\'s data storage path is %s.
A settings dialog box will pop up shortly; please set a
new path there. Continue?',
'too short (< 2 bytes)', # 25
'too long (> 240 bytes)',
'invalid',
'The game now has an active popup child window;
please close it and then try again.',

'', APP_NAME+' Cheat Console - pID=%d', # 30

'Inf', # -2
'.' # -1
    ]
  end

  module StrCN
    LONGNAMES = ['生 命 力', '攻 击 力', '防 御 力', '金 币 数', '当 前 楼 层', '最 高 楼 层', 'Ｘ 坐 标', 'Ｙ 坐 标', '黄 钥 匙', '蓝 钥 匙', '红 钥 匙', '祭 坛 次 数',
'佩 剑 等 级', '盾 牌 等 级', '勇 者 灵 球', '智 慧 灵 球', '飞 翔 灵 球', '十 字 架', '万 灵 药', '魔    镐', '破 坏 爆 弹', '瞬 移 之 翼', '升 华 之 翼', '降 临 之 翼', '屠 龙 匕', '雪 之 结 晶', '魔 法 钥 匙', '超 级 魔 镐', '幸 运 金 币']
    STRINGS = [
APP_NAME+': 请等待游戏内部事件结束……', # 0
APP_NAME+': 单击鼠标传送至 (%X,%X)%s',
APP_NAME+': 移动鼠标选择一个传送的目的地。',
APP_NAME+': 无法前往 (%X,%X)，请移动鼠标另选一个目的地。',
APP_NAME+': 按下字母键 / 方向键使用相应的宝物。',
APP_NAME+': 已传送至 (%X,%X)。移动鼠标继续传送%s', # 5
'，或按下对应按键使用宝物。',
APP_NAME+': 使用方向键上 / 下楼，最后松开 [WIN] 或 [TAB] 键确认。',
APP_NAME+': 已 作 弊 ！',
APP_NAME+': 已启动。发现运行中的 TSW - pID=%d; hWnd=0x%08X',
APP_NAME+': 无法使用%s！', # 10
APP_NAME+' 已开启，以下为使用方法摘要。

当按下 [WIN] 或 [TAB] 快捷键时：
1) 单击鼠标可传送到地图上的新位置（右键＝作弊）；
2) 按下特定字母键可使用对应的宝物；或按下任一
   方向键，可以使用飞翔灵球（▲ 上方向键＝作弊）。

若拥有勇者灵球，在快捷键按下时还可在地图上显示：
* 当前地图中所有怪物的下一临界及总伤害；以及
* 将鼠标移到某个怪物上时，在右下状态栏显示怪物的
  基本属性，并在底部状态栏显示其他重要数据。

使用以下快捷键增强存档和读档的游戏体验：
* Ctrl+L       	＝读档自任意文件；
* Ctrl+S       	＝存档至任意文件；
* 退格         	＝回退到上一节点；
* Shift+退格   	＝快进到下一节点。

此外，还可以:
按一次 F8      	＝打开作弊控制台；
双击 F7        	＝当快捷键失效时重置快捷键；
长按 F7        	＝退出本程序。',
'已重置 [WIN] 及 [TAB] 快捷键。',
APP_NAME+' 已退出。',
'伤害：%s = %s × %s回合｜%d金币%s',
'｜上一临界：%s', # 15
'｜临界：%s',

'获得了「神盾」。是否装备以免除魔法使的魔法攻击？',
'现有装备中存有「神盾」，但目前切换到了等级较低的
盾牌。是否解除「神盾」装备？
注意：这么做将丧失对魔法使的魔法攻击的免疫能力。',
'刷 新 列 表     请按 ESC 返回游戏',

'-- tswKai3 --  
正在等待魔塔
主进程启动…', # 20
'是否停止等待魔塔主程序 TSW 启动？

按“是”将退出本程序；按“取消”则继续待机；
按“否”也将继续等待，但会隐藏此状态窗口，
之后可按 F7 或 F8 等快捷键重新显示。',
'魔塔游戏进程已结束，是否休眠等待其下次运行？',

'当前 MP3 背景音乐路径%s。
如果继续，则只能暂停背景音乐增强功能。',
'当前游戏的存档路径%s。
请在接下来的设置对话框中选定一个合适的新路径。',
'过短（< 2 字节）', # 25
'过长（> 240 字节）',
'无效或不存在',
'当前游戏界面存在活动的弹出式子窗口，
请将其关闭后再重试。',

'', APP_NAME+' 作弊控制台 - pID=%d', # 30

'∞', # -2
'。' # -1
    ]
  end

  module_function
  def utf8toWChar(string)
    arr = string.unpack('U*')
    @strlen = arr.size
    arr.push 0 # end by \0\0
    return arr.pack('S*')
  end
  def strlen() # last length
    @strlen
  end
  def isCHN()
    if $isCHN == 1 # always use Chinese
      $str = Str::StrCN; return true
    elsif $isCHN == nil # always use English
      $str = Str::StrEN; return false
    end
    ReadProcessMemory.call_r($hPrc, TTSW10_TITLE_STR_ADDR, $buf, 32, 0)
    title = $buf[0, 32]
    if title.include?(APP_TARGET_VERSION)
      if title.include?(StrEN::APP_TARGET_NAME)
        $str = Str::StrEN
        return ($isCHN = false)
      elsif title.include?(StrCN::APP_TARGET_NAME)
        $str = Str::StrCN
        return ($isCHN = true)
      end
    end
    raise_r('This is not a compatible TSW game: '+title.rstrip)
  end
end
