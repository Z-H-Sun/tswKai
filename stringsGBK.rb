# encoding: ASCII-8Bit
# Author: Z.Sun
# CHN strings encoding is GBK

module Str
  OFFSET_TTSW10_TITLE_STR = 0x88E74
  APP_TARGET_VERSION = '1.2'
  module StrEN
    APP_TARGET_NAME = 'Tower of the Sorcerer'
    APP_TARGET_ERROR_STR = "This is not a compatible TSW game: Wrong title:\n\n"
    APP_TARGET_45F_ERROR_STR = "This is not a compatible TSW game: The %d-th entry of text\ncontents should have been 45F Merchant's dialog but is now:\n\n"
    DIALOG_FILTER_STR = "Game Data (*.dat)\0*.dat\0Temp Data (*.tmp)\0*.tmp\0All Files\0*.*\0\0"
    TITLE_LOAD_STR = 'Load Data'
    TITLE_SAVE_STR = 'Save Data'
    MSG_SAVE_UNSUCC = 'Game not saved - autoID.tmp'
    MSG_LOAD = 'PLCHLDR tempdata - autoID.tmp'
    MSG_LOAD_SUCC = 'Loaded: '
    MSG_LOAD_UNSUCC = 'No such '
  end
  module StrCN
    APP_TARGET_NAME = '魔塔'
    APP_TARGET_ERROR_STR = "不兼容的魔塔程序：游戏标题不符：\n\n"
    APP_TARGET_45F_ERROR_STR = "不兼容的魔塔程序：第 %d 条文本非 45 层商人台词：\n\n"
    DIALOG_FILTER_STR = "游戏存档 (*.dat)\0*.dat\0临时存档 (*.tmp)\0*.tmp\0所有文件\0*.*\0\0"
    TITLE_LOAD_STR = '读档自文件'
    TITLE_SAVE_STR = '存档至文件'
    MSG_SAVE_UNSUCC = '当前游戏未存档 - autoID.tmp'
    MSG_LOAD = '占位符  临时存档 - autoID.tmp'
    MSG_LOAD_SUCC = '已读取自'
    MSG_LOAD_UNSUCC = '不存在此'
  end
end
