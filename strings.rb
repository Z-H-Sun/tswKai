# encoding: ASCII-8Bit
# Author: Z.Sun
# CHN strings encoding is UTF-8

require 'stringsGBK'
GetUserDefaultUILanguage = API.new('GetUserDefaultUILanguage', 'V', 'L', 'kernel32')
LANG_NEUTRAL = 0
LANG_ENGLISH = 9
LANG_CHINESE = 4
SUBLANG_DEFAULT = 1
SUBLANG_CHINESE_SIMPLIFIED = 2

# initialize according to user or system language
# will be later changed according to TSW language
$isCHN = ((GetUserDefaultUILanguage.call() & 0x3FF) == LANG_CHINESE) # id = (lang_id << 10) | sublang_id
$str = $isCHN ? Str::StrCN : Str::StrEN

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
APP_NAME+': Use arrow keys to fly up/down; release the %s key to confirm.',
APP_NAME+': YOU HAVE CHEATED AT THE GAME!',
APP_NAME+': Started. Found TSW running - pID=%d; hWnd=0x%08X',
APP_NAME+': Could not use %s!', # 10
APP_NAME+' is running. Here is a summary of the usage:

When the %s hotkey is down:
1) Move the mouse and then click to teleport in the map
   (Right click = cheat);
2) Press a specified alphabet key to use an item or any
   arrow keys to use Orb of Flight (Up arrow = cheat).

When holding the hotkey, you can also see:
* the next critical value and damage of each monster and
* other useful data (if you hover the mouse on a monster)
on the map and in the status bar if you have Orb of Hero.

Use hotkeys to enhance the Load/Save function:
* %-13s	= Load data from any file;
* %-13s	= Save data to any file;
* %-13s	= Rewind to the prev snapshot;
* %-13s	= Fast-forward to next snapshot.

In addition, you can:
Press %s once	= Open config dialog;
Press %s twice	= Open cheat console;
Press %-9s	= Switch to TSW or config / cheat window;
Double press %s	= Re-register hotkeys if they stop working;
Hold %-10s	= Quit tswKai3.',
'Re-registered %s hotkeys.',
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
and you can press %s or %s to show it again later.',
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

APP_NAME+' is already running with pID=%s.',
APP_NAME+' Cheat Console - pID=%p', # 30
APP_NAME+' Config (Static)',
APP_NAME+' Config (Dynamic) - pID=%p',
'Show only one-turn battle animation
This can also bypass the 2500-round limit bug',
'Fix 47F Magician_A movement bug
Rectify their behavior in first/last row/col',
'Fix 45F Merchant bug in the backside tower
Add 88000 instead of 2000 HP (>=2nd round)', # 35
'Fix 50F Zeno status bug in the backside tower
44 mistakenly multiplied twice (>=3rd round)',
'Increase the margins of the dialog window',

'Display
damage',
'Auto save
snapshots',
'Enhance
BGM play', # 40

'This TSW\'s binary data associated with this configuration
does not seem right. Continue anyway?',
'This is not a compatible TSW game: The number of text
content entries differs by %d from expected.',
'This is not a compatible TSW game: Not a "rev" version.
It is recommended to visit the author\'s GitHub page to
download and update to the rev version TSW.

If you choose to continue, though the backside tower 45F
Merchant bug could be somewhat fixed so that you can get
88000 HP from him, the displayed value in the dialog will
still be 2000 HP. Continue anyway?',

'The TSW executable to patch can\'t be found or accessed.',
'The TSW executable to patch can\'t be accessed.

Possibilities include: The file is in-use, read-only, or
in a privileged folder. If it is the last case, do you
want to try again as Administrator?', # 45
'Do you want to statically patch this TSW executable?

Unlike the dynamic config of this app, which takes effect
only during runtime, this action makes permanent changes.
Please backup this executable before continuing.',
'The TSW executable has been successfully static-patched.

Do you want to run it now? If you choose "No," this app
will hibernate until another TSW game is run; choosing
"Cancel" will end this app.',
'Can\'t run the specified TSW executable, as another TSW
process has already been running (pID = %d).',

'Inf', # -2
'.' # -1
    ]
    VKEYNAMES = [ # Virtual key codes
'[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', 'Bksp', 'Tab', '[?]', '[?]', 'Clear', 'Enter', '[?]', '[?]',
'Shift', 'Ctrl', 'Alt', 'Pause', 'CapsLock', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', 'ESC', '[?]', '[?]', '[?]', '[?]',
'Space', 'PageUp', 'PageDn', 'End', 'Home', 'Left', 'Up', 'Right', 'Down', 'Select', 'Print', 'Execute', 'PrintScr', 'Ins', 'Del', 'Help',
'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]',
'[?]', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'L_Win', 'R_Win', 'App', '[?]', 'Sleep',
'Num0', 'Num1', 'Num2', 'Num3', 'Num4', 'Num5', 'Num6', 'Num7', 'Num8', 'Num9', 'Num*', 'Num+', '[?]', 'Num-', 'Num.', 'Num/',
'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'F13', 'F14', 'F15', 'F16',
'F17', 'F18', 'F19', 'F20', 'F21', 'F22', 'F23', 'F24', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]',
'NumLock', 'ScrollLock', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]',
'L_Shift', 'R_Shift', 'L_Ctrl', 'R_Ctrl', 'L_Alt', 'R_Alt', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', 'VolumeMute', 'VolumeDown', 'VolumeUp',
'NextTrack', 'PrevTrack', 'MediaStop', 'MediaPlay', 'LaunchMail', 'LaunchMedia', '[?]', '[?]', '[?]', '[?]', ';', '=', ',', '-', '.', '/',
'`', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]',
'[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[?]', '[', '\\', ']', '\'', '[?]'
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
APP_NAME+': 使用方向键上 / 下楼，最后松开 %s 键确认。',
APP_NAME+': 已 作 弊 ！',
APP_NAME+': 已启动。发现运行中的 TSW - pID=%d; hWnd=0x%08X',
APP_NAME+': 无法使用%s！', # 10
APP_NAME+' 已开启，以下为使用方法摘要。

当按下 %s 快捷键时：
1) 单击鼠标可传送到地图上的新位置（右键＝作弊）；
2) 按下特定字母键可使用对应的宝物；或按下任一
   方向键，可以使用飞翔灵球（▲ 上方向键＝作弊）。

若拥有勇者灵球，在快捷键按下时还可在地图上显示：
* 当前地图中所有怪物的下一临界及总伤害；以及
* 将鼠标移到某个怪物上时，在右下状态栏显示怪物的
  基本属性，并在底部状态栏显示其他重要数据。

使用以下快捷键增强存档和读档的游戏体验：
* %-15s	＝读档自任意文件；
* %-15s	＝存档至任意文件；
* %-15s	＝回退到上一节点；
* %-15s	＝快进到下一节点。

此外，还可以:
按一次 %-8s	＝打开设置对话框；
按两次 %-8s	＝打开作弊控制台；
按下 %-10s	＝切换到魔塔游戏或上述窗口；
双击 %-10s	＝当快捷键失效时重置快捷键；
长按 %-10s	＝退出本程序。',
'已重置 %s 快捷键。',
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
之后可按 %s 或 %s 快捷键重新显示。',
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

APP_NAME+' 不可重复运行，已在进程 pID=%s 中打开。',
APP_NAME+' 作弊控制台 - pID=%p', # 30

APP_NAME+' 设置（静态）',
APP_NAME+' 设置（动态）- pID=%p',
'对战只显示一回合战斗动画以节省时间
(这也能解决2500回合战斗上限的溢出Bug)',
'修正47层「魔術士A」魔法回退路线Bug
(指其在首行/首列/末行/末列的后撤行为)',
'修正45层里侧塔「商人」的加血点数Bug
(二周目以上属性加点应×44: 2000→88000)', # 35
'修正50层里侧塔「芝诺」的属性Bug
(三周目以上有时芝诺属性会错误地多×44)',
'增加对话窗格内部文字边距，不至于太挤',

'在地图上
显示伤害',
'重要节点
自动存档',
'背景音乐
播放增强', # 40

'当前魔塔中此设置相关二进制数据不正确。仍然继续？',
'不兼容的魔塔程序：文本条目数与正常值相差 %d。',
'不兼容的魔塔程序：不是 rev（修正）版魔塔。
推荐前往作者 GitHub 页面下载更新 rev 版魔塔。

若选择继续，虽然还是可以让里侧塔的 45 层商人卖
88000 HP，但对话中将依旧显示加 2000 HP。仍然继续？',

'欲修正的魔塔程序文件不存在或无法访问。',
'欲修正的魔塔程序文件无法访问。这有可能是因为其
正在使用中，或因其为只读文件，或因其在需管理员
权限的系统目录下，等等。

若原因为后者，是否尝试以管理员权限打开重试？', # 45
'是否确认以“静态模式”修正该魔塔程序文件？

与本程序“动态模式”的设置不同的是，后者只在运行时
生效，而本操作的更改是永久性的。因此，请在点“是”
确认前做好文件的备份。',
'当前魔塔程序文件已成功静态修正。是否立即运行它？

按“否”后，本程序将休眠并等待其他魔塔游戏启动；而
按“取消”则将退出本程序。',
'无法启动当前魔塔程序，因为另一个魔塔进程已正在
运行中 (pID = %d)。',

'∞', # -2
'。' # -1
    ]
    VKEYNAMES = [ # 虚拟键码
'〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '退格', 'TAB', '〿', '〿', 'CLEAR', '回车', '〿', '〿',
'Shift', 'Ctrl', 'Alt', 'PAUSE', '大写锁定', '〿', '〿', '〿', '〿', '〿', '〿', 'ESC', '〿', '〿', '〿', '〿',
'空格', '上翻页', '下翻页', 'END', 'HOME', '◀', '▲', '▶', '▼', '选择', '打印', '执行', '截屏', '插入', '删除', '帮助',
'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '〿', '〿', '〿', '〿', '〿', '〿',
'〿', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '左WIN', '右WIN', '弹出菜单', '〿', '睡眠',
'小键盘0', '小键盘1', '小键盘2', '小键盘3', '小键盘4', '小键盘5', '小键盘6', '小键盘7', '小键盘8', '小键盘9', '小键盘*', '小键盘+', '〿', '小键盘-', '小键盘.', '小键盘/',
'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'F13', 'F14', 'F15', 'F16',
'F17', 'F18', 'F19', 'F20', 'F21', 'F22', 'F23', 'F24', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿',
'数字锁定', '滚动锁定', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿',
'左Shift', '右Shift', '左Ctrl', '右Ctrl', '左Alt', '右Alt', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '静音', '调低音量', '调高音量',
'下一曲', '上一曲', '停止播放', '播放/暂停', '启动邮件', '启动音乐', '〿', '〿', '〿', '〿', ';', '=', ',', '-', '.', '/',
'`', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿',
'〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '〿', '[', '\\', ']', '\'', '〿'
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
  def isCHN(static=nil) # `static`, if any, should be an IO object
    isCHN = nil
    if $isCHN == 1 # always use Chinese
      $str = Str::StrCN; isCHN = true
    elsif $isCHN == nil # always use English
      $str = Str::StrEN; isCHN = false
    end
    if static
      static.seek(OFFSET_TTSW10_TITLE_STR+BASE_ADDRESS_STATIC)
      title = static.read(32) || 'NULL'
      $isRev = title.include?(REV_VER_WATERMARK)
    else
      ReadProcessMemory.call_r($hPrc, OFFSET_TTSW10_TITLE_STR+BASE_ADDRESS, $buf, 32, 0)
      title = $buf[0, 32]
    end
    if title.include?(APP_TARGET_VERSION)
      if title.include?(StrEN::APP_TARGET_NAME)
        return isCHN unless isCHN.nil?
        $str = Str::StrEN
        return ($isCHN = false)
      elsif title.include?(StrCN::APP_TARGET_NAME)
        return isCHN unless isCHN.nil?
        $str = Str::StrCN
        return ($isCHN = true)
      end
    end
    API.msgbox($str::APP_TARGET_ERROR_STR+title, MB_ICONERROR)
    return nil
  end
end
