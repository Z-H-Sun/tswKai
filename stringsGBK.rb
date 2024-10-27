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
    APP_TARGET_2ND_ERROR_STR = "This is not a compatible TSW game: The %d-th entry of text\ncontents should have been magic attack prompt but is now:\n\n"
    DIALOG_FILTER_STR = "Game Data (*.dat)\0*.dat\0Temp Data (*.tmp)\0*.tmp\0All Files\0*.*\0\0"
    TITLE_LOAD_STR = 'Load Data'
    TITLE_SAVE_STR = 'Save Data'
    MSG_SAVE_UNSUCC = 'Game not saved - autoID.tmp'
    MSG_LOAD = 'PLCHLDR tempdata - autoID.tmp'
    MSG_LOAD_SUCC = 'Loaded: '
    MSG_LOAD_UNSUCC = 'No such '
    INPUTBOX_LOADTEMP_PROMPTS = ['Load Temp Data', 'Load the prev/next N-th (0-9) snapshot:


Format: -N / +N / blank (N=0)', 'Invalid input!']

    ERR_MSG = ['Unsupported system or Ruby version (neither 32-bit or 64-bit).',
'The hotkey `MP_KEY1` must be set.',
'Cannot open / read from / write to / alloc memory for / synchronize with the TSW process. Please check if TSW V1.2 is running with pID=%p and if you have proper permissions.',
'Cannot register hotkey %s. It might be currently occupied by other processes or another instance of %s. Please close them to avoid confliction. As an advanced option, you can manually assign `%s_MODIFIER` and `%s_HOTKEY` in \'%s\'.',
'Error executing file \'%s\' with the \'%s\' action and the parameters being \'%s\', returning code %s.
It might be because the user cancelled this action, or the system fails to find the specified file or execute the action.',
'Cannot read or write in a console. If you are running the app using a CLI Ruby, please check if you have redirected STDIN / STDOUT to a file.',
'This is a fatal error. That is all we know. Please open an issue on GitHub.',
'Err 0x%04x when calling `%s`@%s, which returns %d: %s%s %s has stopped. Details are as follows:

Prototype="%s", ReturnType="%s", ARGV=[%s]']
  end
  module StrCN
    APP_TARGET_NAME = '魔塔'
    APP_TARGET_ERROR_STR = "不兼容的魔塔程序：游戏标题不符：\n\n"
    APP_TARGET_45F_ERROR_STR = "不兼容的魔塔程序：第 %d 条文本非 45 层商人台词：\n\n"
    APP_TARGET_2ND_ERROR_STR = "不兼容的魔塔程序：第 %d 条文本非 魔法伤害提示：\n\n"
    DIALOG_FILTER_STR = "游戏存档 (*.dat)\0*.dat\0临时存档 (*.tmp)\0*.tmp\0所有文件\0*.*\0\0"
    TITLE_LOAD_STR = '读档自文件'
    TITLE_SAVE_STR = '存档至文件'
    MSG_SAVE_UNSUCC = '当前游戏未存档 - autoID.tmp'
    MSG_LOAD = '占位符  临时存档 - autoID.tmp'
    MSG_LOAD_SUCC = '已读取自'
    MSG_LOAD_UNSUCC = '不存在此'
    INPUTBOX_LOADTEMP_PROMPTS = ['读取临时存档 ', '读取之前/之后第N个节点 (N=0~9):


输入格式为 -N 或 +N 或留空（代表N=0）', '输入值无效！']

    ERR_MSG = ['不受支持的系统或 Ruby 版本（不是 32 位或 64 位）。',
'必须为快捷键 `MP_KEY1` 赋值。',
'无法对魔塔进程进行打开／读取／写入／分配内存／或同步操作。请检查 pID=%p 的进程是否为正在运行中的魔塔 V1.2 游戏，并检查当前用户是否拥有相关权限。',
'无法注册快捷键 %s。这有可能是因为当前快捷键已被其他程序占用，或者另一个 %s 程序正在运行中。请尝试关闭它们以避免冲突。或者，在「高级设置」中，可手动给 `%s_MODIFIER` 和 `%s_HOTKEY` 常量赋值（详见文件 \'%s\'）。',
'在对文件 \'%s\' 进行 \'%s\' 操作时引发了错误（其中参数为 \'%s\'，返回值为 %s）。
这可能是由于用户取消了这一操作，或者是因为系统无法找到相应文件或执行相关操作。',
'无法对控制台进行读／写操作。如果当前程序运行在控制台子系统的 Ruby 中，请检查是否误将标准输入／标准输出重定向到了磁盘文件。',
'致命错误，抱歉无法提供更多信息。如果可以的话，请到 GitHub 上向作者反馈。',
'错误代码：0x%04x。`%s`@%s 返回值为 %d：%s%s %s 已停止工作。详情如下：

函数原型="%s"；返回类型="%s"；传入参数=[%s]']
  end
end
