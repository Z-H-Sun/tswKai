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
    APP_TARGET_NAME = 'ħ��'
    APP_TARGET_ERROR_STR = "�����ݵ�ħ��������Ϸ���ⲻ����\n\n"
    APP_TARGET_45F_ERROR_STR = "�����ݵ�ħ�����򣺵� %d ���ı��� 45 ������̨�ʣ�\n\n"
    APP_TARGET_2ND_ERROR_STR = "�����ݵ�ħ�����򣺵� %d ���ı��� ħ���˺���ʾ��\n\n"
    DIALOG_FILTER_STR = "��Ϸ�浵 (*.dat)\0*.dat\0��ʱ�浵 (*.tmp)\0*.tmp\0�����ļ�\0*.*\0\0"
    TITLE_LOAD_STR = '�������ļ�'
    TITLE_SAVE_STR = '�浵���ļ�'
    MSG_SAVE_UNSUCC = '��ǰ��Ϸδ�浵 - autoID.tmp'
    MSG_LOAD = 'ռλ��  ��ʱ�浵 - autoID.tmp'
    MSG_LOAD_SUCC = '�Ѷ�ȡ��'
    MSG_LOAD_UNSUCC = '�����ڴ�'
    INPUTBOX_LOADTEMP_PROMPTS = ['��ȡ��ʱ�浵 ', '��ȡ֮ǰ/֮���N���ڵ� (N=0~9):


�����ʽΪ -N �� +N �����գ�����N=0��', '����ֵ��Ч��']

    ERR_MSG = ['����֧�ֵ�ϵͳ�� Ruby �汾������ 32 λ�� 64 λ����',
'����Ϊ��ݼ� `MP_KEY1` ��ֵ��',
'�޷���ħ�����̽��д򿪣���ȡ��д�룯�����ڴ棯��ͬ������������ pID=%p �Ľ����Ƿ�Ϊ���������е�ħ�� V1.2 ��Ϸ������鵱ǰ�û��Ƿ�ӵ�����Ȩ�ޡ�',
'�޷�ע���ݼ� %s�����п�������Ϊ��ǰ��ݼ��ѱ���������ռ�ã�������һ�� %s �������������С��볢�Թر������Ա����ͻ�����ߣ��ڡ��߼����á��У����ֶ��� `%s_MODIFIER` �� `%s_HOTKEY` ������ֵ������ļ� \'%s\'����',
'�ڶ��ļ� \'%s\' ���� \'%s\' ����ʱ�����˴������в���Ϊ \'%s\'������ֵΪ %s����
������������û�ȡ������һ��������������Ϊϵͳ�޷��ҵ���Ӧ�ļ���ִ����ز�����',
'�޷��Կ���̨���ж���д�����������ǰ���������ڿ���̨��ϵͳ�� Ruby �У������Ƿ��󽫱�׼���룯��׼����ض����˴����ļ���',
'�������󣬱�Ǹ�޷��ṩ������Ϣ��������ԵĻ����뵽 GitHub �������߷�����',
'������룺0x%04x��`%s`@%s ����ֵΪ %d��%s%s %s ��ֹͣ�������������£�

����ԭ��="%s"����������="%s"���������=[%s]']
  end
end
