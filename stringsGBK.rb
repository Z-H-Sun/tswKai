# encoding: ASCII-8Bit
# CHN strings encoding is GBK

module Str
  TTSW10_TITLE_STR_ADDR = 0x88E74 + BASE_ADDRESS
  APP_TARGET_VERSION = '1.2'
  module StrEN
    APP_TARGET_NAME = 'Tower of the Sorcerer'
    DIALOG_FILTER_STR = "Game Data (*.dat)\0*.dat\0Temp Data (*.tmp)\0*.tmp\0All Files\0*.*\0\0"
    TITLE_LOAD_STR = 'Load Data'
    TITLE_SAVE_STR = 'Save Data'
    MSG_SAVE_UNSUCC = 'Game not saved - autoID.tmp'
    MSG_LOAD = 'PLCHLDR tempdata - autoID.tmp'
    MSG_LOAD_SUCC = 'Loaded: '
    MSG_LOAD_UNSUCC = 'No such '
  end
  module StrCN
    APP_TARGET_NAME = 'ħ��'
    DIALOG_FILTER_STR = "��Ϸ�浵 (*.dat)\0*.dat\0��ʱ�浵 (*.tmp)\0*.tmp\0�����ļ�\0*.*\0\0"
    TITLE_LOAD_STR = '�������ļ�'
    TITLE_SAVE_STR = '�浵���ļ�'
    MSG_SAVE_UNSUCC = '��ǰ��Ϸδ�浵 - autoID.tmp'
    MSG_LOAD = 'ռλ��  ��ʱ�浵 - autoID.tmp'
    MSG_LOAD_SUCC = '�Ѷ�ȡ��'
    MSG_LOAD_UNSUCC = '�����ڴ�'
  end
end
