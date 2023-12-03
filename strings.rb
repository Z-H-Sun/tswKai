# encoding: ASCII-8Bit
# CHN strings encoding is UTF-8

require './stringsGBK'

$isCHN = false
$str = Str::StrEN

module Str
  TTSW10_TITLE_STR_ADDR = 0x88E74 + BASE_ADDRESS
  APP_VERSION = '1.2'
  @strlen = 0
  module StrEN
    LONGNAMES = ['Life Pt (HP)', 'Offense(ATK)', 'Defense(DEF)', 'Gold Count', 'CurrentFloor', 'HighestFloor', 'X Coordinate', 'Y Coordinate', '(Yellow) Key', 'Blue Key', 'Red  Key', 'Altar Visits',
'Weapon(Sword)', 'Shield Level', 'OrbOfHero', 'OrbOfWisdom', 'OrbOfFlight', 'Cross', 'Elixir', 'Mattock', 'DestructBall', 'WarpWing', 'AscentWing', 'DescentWing', 'DragonSlayer', 'SnowCrystal', 'MagicKey', 'SuperMattock', 'LuckyGold']
    STRINGS = [
'','','','','','','','','','','', # 10
'','','tswKai has stopped.','','','',
'You just obtained Sacred Shield. Do you want to arm it
to screen you from the magic attacks of wizards?',
'You have Sacred Shield but just switched to a lower level
shield. Do you want to disarm Sacred Shield, though you will
no longer be able to resist the magic attacks from wizards?',
'Refresh List   Press ESC to quit.',

'--- tswKai ---  
Waiting for   
TSW to start ', # 20
'Do you want to stop waiting for the TSW game to start?

Choose "Yes" to quit this app; "Cancel" to do nothing;
"No" to continue waiting but hide this status window.',
'The TSW game process has ended. Do you want to put this
app to hibernate and wait for the next TSW game?',

'','','','','','','',
'tswKai Cheat Console - pID=%d', # 30

'.' # -1
    ]
  end

  module StrCN
    LONGNAMES = ['生 命 力', '攻 击 力', '防 御 力', '金 币 数', '当 前 楼 层', '最 高 楼 层', 'Ｘ 坐 标', 'Ｙ 坐 标', '黄 钥 匙', '蓝 钥 匙', '红 钥 匙', '祭 坛 次 数',
'佩 剑 等 级', '盾 牌 等 级', '勇 者 灵 球', '智 慧 灵 球', '飞 翔 灵 球', '十 字 架', '万 灵 药', '魔    镐', '破 坏 爆 弹', '瞬 移 之 翼', '升 华 之 翼', '降 临 之 翼', '屠 龙 匕', '雪 之 结 晶', '魔 法 钥 匙', '超 级 魔 镐', '幸 运 金 币']
    STRINGS = [
'','','','','','','','','','','', # 10
'','','tswKai 已退出。','','','',
'获得了「神盾」。是否装备以免除魔法使的魔法攻击？',
'现有装备中存有「神盾」，但目前切换到了等级较低的
盾牌。是否解除「神盾」装备？
注意：这么做将丧失对魔法使的魔法攻击的免疫能力。',
'刷 新 列 表     请按 ESC 退出程序',

'--- tswKai ---  
正在等待魔塔
主进程启动…', # 20
'是否停止等待魔塔主程序 TSW 启动？

按“是”将退出本程序；按“取消”则继续待机；
按“否”也将继续等待，但会隐藏此状态窗口。',
'魔塔游戏进程已结束，是否休眠等待其下次运行？',

'','','','','','','',
'tswKai 作弊控制台 - pID=%d', # 30

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
    if title.include?(APP_VERSION)
      if title.include?(StrEN::APP_NAME)
        $str = Str::StrEN
        return ($isCHN = false)
      elsif title.include?(StrCN::APP_NAME)
        $str = Str::StrCN
        return ($isCHN = true)
      end
    end
    raise_r('This is not a compatible TSW game: '+title.rstrip)
  end
end
