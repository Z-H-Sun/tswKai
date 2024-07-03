#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: tswBGM.asm

OFFSET_PARENT = 0x4 # similar to OFFSET_OWNER (0x20) but for TTimer that is not applicable
OFFSET_TTIMER_ENABLED = 0x20 # byte
OFFSET_TTIMER_INTERVAL = 0x24 # dword
OFFSET_TMEDIAPLAYER_PLAYSTATE = 0x1d5 # byte
OFFSET_TMEDIAPLAYER_DEVICEID = 0x1e6 # word
OFFSET_TMEDIAPLAYER5 = 0x2d8
OFFSET_TMEDIAPLAYER6 = 0x46c
OFFSET_TTIMER4 = 0x41c
OFFSET_TMENUITEM_BGMON1 = 0x330

BGM_SETTING_ADDR = 0x89ba2 + BASE_ADDRESS # byte
BGM_ID_ADDR = 0xb87f0 + BASE_ADDRESS
BGM_CHECK_ADDR = 0x7c8f8 + BASE_ADDRESS # TTSW10.soundcheck
BGM_PLAY_ADDR = 0x7c2bc + BASE_ADDRESS # TTSW10.soundplay
BGM_PLAY_OPEN_N_PLAY_ADDR = 0x7c6d3 + BASE_ADDRESS # place to jump to within TTSW10.soundplay
BGM_BASENAME_ADDR = 0x7c72a + BASE_ADDRESS # e.g. b_067xgw.mig
BGM_BASENAME_GAP = 0x1c # each separated by 0x1c bytes

TTIMER4_ONTIMER_ADDR = 0x82a98 + BASE_ADDRESS # TTSW10.timer4ontimer
TTIMER_SETENABLED_ADDR = 0x2c454 + BASE_ADDRESS # _Unit9.TTimer.SetEnabled
TMEDIAPLAYER_CLOSE_ADDR = 0x31188 + BASE_ADDRESS # _Unit10.TMediaPlayer.Close
TMENUITEM_SETCHECKED_ADDR = 0x102f0 + BASE_ADDRESS # Menus.TMenuItem.SetChecked
MCISENDCOMMAND_ADDR = 0x2f838 + BASE_ADDRESS # winmm.mciSendCommandA

BGM_DIRNAME = 'BGM' # the folder that contains the mp3 BGM files
BGM_FADE_STEPS = 10 # fade out BGM in 10 steps; 1 means no fading out effect
BGM_FADE_INTERVAL = 150 # each step takes 150 ms

$BGMtakeOver = true
$_TSWBGM = true # module tswBGM is imported

module BGM
  MCI_CLOSE = 0x804
  MCI_SETAUDIO = 0x873
  MCI_DGV_SETAUDIO_VOLUME = 0x4002
  MCI_DGV_SETAUDIO_ITEM = 0x800000
  MCI_DGV_SETAUDIO_VALUE = 0x1000000
  MCI_DGV_SETAUDIO_ITEM_VALUE = MCI_DGV_SETAUDIO_ITEM | MCI_DGV_SETAUDIO_VALUE

  BGM_CHECK_EXT = [ # floor; y,x of fairy; y,x,type to check (4=gate; 91=Zeno); boss battle BGM id; offset of jnz, jmp
 [10, 2, 5, 6, 5, 4, 15, 0x12, 0x5a], [20, 4, 5, 8, 5, 4, 16, 0x12, 0x43], [25, 6, 5, 9, 5, 4, 7, 0x12, 0x2c],
 [40, 5, 5, 7, 5, 4, 18, 0x12, 0x15], [49, 1, 5, 2, 5, 91, 19, -0x69, nil]]
  BGM_PHANTOMFLOOR = 'b_095xgw'
  BGM_PATCH_BYTES_0 = [ # address, len, original bytes, patched bytes
[0x4312cb, 65, "\x80\xBB\xE2\1\0\0\0\x74\x17\x80\xBB\xE0\1\0\0\0\x74\7\x83\x8B\xDC\1\0\0\2\xC6\x83\xE2\1\0\0\0\0\xBB\xE4\1\0\0\0\x74\x18\x83\x8B\xDC\1\0\0\4\x8B\x83\xF0\1\0\0\x89\x44\x24\4\xC6\x83\xE4\1\0\0\0", "\x8B\x43\4\x3B\x98\xD8\2\0\0\x74\x3D\x31\xD2\x89\x54\x24\4\5\x64\4\0\0\x3B\x18\x74\x1F\x3B\x58\xFC\xB2\4\x74\2\xB2\x40\xB8\x3B\xA1\x4B\0\x8A\x08\x39\x15\xAC\xC5\x48\0\x0F\x9F\0\x7F\x0C\x84\xC9\x75\x08\x83\x8B\xDC\1\0\0\4\x90"] # TMediaPlayer.Play
  ] # this list: always patch
  BGM_PATCH_BYTES = [ # address, len, original bytes, patched bytes[, variable to insert into patched bytes[, if `call relative`, an additional offset parameter is provided next]]
[TTIMER4_ONTIMER_ADDR, 1, "\xc3", "\xc3"], # temporarily disable TTimer4 (otherwise, there might be a relatively low chance, esp. for some PCs with rubbish performance, that the Timer4OnTimer event is running at the same time as tswBGM is patching the asm codes, thus confused and leading to heap corruption)

[0x430ef8, 9, 'Sequencer', 'MPEGVideo'], # lpstrDeviceType Sequencer=midi; MPEGVideo=mp3

[0x4508a9, 1, "\x75", "\x7B"], # TTSW10.itemlive redefine TTimer4.Enabled (jne -> jnp)
[0x4556be, 1, "\x75", "\x7B"], # TTSW10.syokidata2_1 redefine TTimer4.Enabled
[0x4556d2, 1, "\x85", "\x8B"], # TTSW10.syokidata2_2 redefine TTimer4.Enabled
[0x4558d9, 1, "\x85", "\x8B"], # TTSW10.syokidata2_3 redefine TTimer4.Enabled
[0x455af1, 1, "\x75", "\x7B"], # TTSW10.syokidata2_4 redefine TTimer4.Enabled
[0x455b40, 1, "\x75", "\x7B"], # TTSW10.syokidata2_5 redefine TTimer4.Enabled
[0x4637f5, 1, "\x75", "\x7B"], # TTSW10.GameStart1Click redefine TTimer4.Enabled
[0x47c2a3, 1, "\x75", "\x7B"], # TTSW10.BGMOn1Click redefine TTimer4.Enabled
[0x480efb, 1, "\x75", "\x7B"], # TTSW10.MouseControl1Click redefine TTimer4.Enabled

[0x48468e, 1, "\x85", "\x86"], # TTSW10.opening9 (ending scene) disregard BGMOn1.Checked
[0x46b640, 1, "\x74", "\xEB"], # TTSW10.moncheck for 49F (from battle with sorcerers); disregard stopping BGM (1,6,0)
[0x453463, 1, "\x74", "\xEB"], # TTSW10.stackwork for 11,7,0 (from opening2 (3f opening scene)); disregard playing BGM No.11 (will handle elsewhere)
[0x47ebda, 4, "\x76\x56\xF8\xFF", '%s', :@_sub_save_excludeBGM, 4], # TTSW10.savework do not save BGM_ID into data
[0x47ec67, 4, "\xE9\x55\xF8\xFF", '%s', :@_sub_save_excludeBGM, 4], # same above
[TTIMER_SETENABLED_ADDR, 5, "\x3A\x50\x20\x74\x08", "\xE8%s", :@_sub_resetTTimer4, 5], # _Unit9.TTimer.SetEnabled reset TTimer4 attributes for tswBGM
[BGM_CHECK_ADDR, 5, "\xA1\x98\x86\x4B\0", "\xE8%s", :@_sub_checkBGM_ext, 5], # TTSW10.soundcheck add more checks such as HP and boss battle
[0x45282a, 4, "\x8E\x9A\2\0", '%s', :@_sub_instruct_playBGM, 4], # TTSW10.stackwork for 1,5,0 -> with 1,5,bgmid; call sub_instruct_playBGM instead of sub_soundplay
[0x481f6f, 4, "\x15\xF2\xFA\xFF", '%s', :@_sub_checkOrbFlight, 4], # TTSW10.img4work; OrbOfFlight rather than always stopping BGM, check if it is necessary
[0x44edb9, 17, "\x74\x08\xFF\5\x98\x86\x4B\0\xEB\7\x83\5\x98\x86\x4B\0\2", "\xB8\x98\x86\x4B\0\x75\2\xFF\0\xFF\0\xE8%s\x90", :@_sub_checkOrbFlight, 16], # TTSW10.Button8Click (UP); check if need to stop BGM
[0x44ed39, 17, "\x74\x08\xFF\x0D\x98\x86\x4B\0\xEB\7\x83\x2D\x98\x86\x4B\0\2", "\xB8\x98\x86\x4B\0\x75\2\xFF\x08\xFF\x08\xE8%s\x90", :@_sub_checkOrbFlight, 16], # TTSW10.Button9Click (DOWN); check if need to stop BGM
[0x4618a1, 17, "\x74\x08\xFF\5\x98\x86\x4B\0\xEB\7\x83\5\x98\x86\x4B\0\2", "\xB8\x98\x86\x4B\0\x75\2\xFF\0\xFF\0\xE8%s\x90", :@_sub_checkOrbFlight, 16], # TTSW10.timer3ontimer (MouseDown on TButton8); check if need to stop BGM
[0x4618d9, 17, "\x74\x08\xFF\x0D\x98\x86\x4B\0\xEB\7\x83\x2D\x98\x86\x4B\0\2", "\xB8\x98\x86\x4B\0\x75\2\xFF\x08\xFF\x08\xE8%s\x90", :@_sub_checkOrbFlight, 16], # TTSW10.timer3ontimer (MouseDown on TButton9); check if need to stop BGM
[0x482abb, 15, "\x83\xE8\x08\x72\x0C\x83\xE8\7\x72\x19\x83\xE8\6\x72\x26", "\x80\x3D%s\0\x75\x0A\x68\x28\x2E\x48\0\xE9", :@_isInProlog], # TTSW10.timer4ontimer_1
[0x482aca, 25, "\xEB\x34\xBA\x5E\1\0\0\x8B\x83\x1C\4\0\0\xE8\x88\x99\xFA\xFF\xEB\x22\xBA\xFA\0\0\0", "%s\xBA\x5E\1\0\0\x83\xE8\x08\x72\x0B\x83\xE8\7\x72\2\xEB\x11\x83\xEA\x64\x90", :@_sub_timer4ontimer_real, 4], # TTSW10.timer4ontimer_2

[0x46f972, 1, "\0", "\x10"], # TTSW10.ichicheck for 20F (from battle with vampire); specify BGM id=16 (see sub_instruct_playBGM)
[0x476ead, 1, "\0", "\x13"], # TTSW10.ichicheck for 49F (from battle with sorcerers); specify BGM id=19 (see sub_instruct_playBGM)

[0x463e78, 2, "\xC7\5", "\xEB\x0F"], # TTSW10.mevent for 25F (from battle with archsorcerer); disregard playing BGM No.7 (will handle elsewhere)
[0x463f71, 2, "\xC7\5", "\xEB\x0F"], # TTSW10.mevent for 40F (from battle with knights); disregard playing BGM No.18 (will handle elsewhere)

[0x444d0e, 37, "\x83\x3D\xF0\x87\x4B\0\0\x74\x1E\x33\xD2\x8B\x45\xFC\x8B\x80\xB4\1\0\0\xE8\x2D\x77\xFE\xFF\x8B\x45\xFC\x8B\x80\xD8\2\0\0\xE8\x53\xC4", "\xEB\x25\x83\x3D\xF0\x87\x4B\0\0\x74\x15\xE8\xDA\x7B\3\0\x8B\x45\xFC\x8B\x80\x1C\4\0\0\xB2\6\xE8\x26\x77\xFE\xFF\xE9\x89\x42\0\0"], # TTSW10.handan for tileID=11/12 (stairs); soundcheck and soundplay
[0x445097, 4, "\x21\x3F\0\0", "\x75\xFC\xFF\xFF"], # TTSW10.handan for tileID=11/12 (stairs); jump to 444d0e

[0x430f83, 37, "\x89\x86\xDC\1\0\0\x80\xBE\xE2\1\0\0\0\x74\x1C\x80\xBE\xE0\1\0\0\0\x74\x0A\xC7\x86\xDC\1\0\0\2\0\0\0\xC6\x86\xE2", "\xB0\2\x89\x86\xDC\1\0\0\x8B\x46\4\x3B\xB0\xD8\2\0\0\x75\x22\xC7\x45\xF8%s\x66\x81\x8E\xDC\1\0\0\0\2\xEB\x10", :@_bgm_filename], # TMediaPlayer.Open
[TMEDIAPLAYER_CLOSE_ADDR, 64, "\x53\x56\x51\x8B\xD8\x66\x83\xBB\xE6\1\0\0\0\x0F\x84\xAD\0\0\0\x33\xC0\x89\x83\xDC\1\0\0\x80\xBB\xE2\1\0\0\0\x74\x1C\x80\xBB\xE0\1\0\0\0\x74\x0A\xC7\x83\xDC\1\0\0\2\0\0\0\xC6\x83\xE2\1\0\0\0\xEB\x0A", "\x8B\x50\4\x3B\x82\xD8\2\0\0\x75\x22\x8B\x82\x1C\4\0\0\xB2\6\xC6\5\xF0\x87\x4B\0\xFF\x80\x3D%s\0\x0F\x84\xA5\xB2\xFF\xFF\x53\xE9\x75\x26\3\0\x66\x83\xB8\xE6\1\0\0\0\x75\1\xC3\x53\x56\x51\x8B\xD8\x90\x90\x90", :@_isInProlog], # TMediaPlayer.Close
[0x431312, 15, "\0\x74\x18\x83\x8B\xDC\1\0\0\x08\x8B\x83\xEC\1\0", "\1\x75\x18\x81\x8B\xDC\1\0\0\0\0\1\0\xEB\x0C"], # TMediaPlayer.Play

[BGM_PLAY_ADDR, 13, "\x55\x8B\xEC\x6A\0\x53\x56\x57\x8B\xD8\x33\xC0\x55", "\x8B\x80\x1C\4\0\0\xB2\6\xE9\x8B\1\xFB\xFF"], # TTSW10.soundplay
[0x47c960, 20, "\xC7\5\xF0\x87\x4B\0\x09\0\0\0\xC3\xC7\5\xF0\x87\x4B\0\x0A\0\0", "\x83\xC0\6\x74\3\xB0\xF3\x90\4\x0C\x90\4\x0A\x0F\xB6\xC0\xA3\xF0\x87\x4B"], # TTSW10.soundcheck

[TTIMER4_ONTIMER_ADDR, 1, "\x55", "\x55"], # re-enable TTimer4 (see Line 51)

# battle w Skeletons
[0x46754c, 60, "\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\x0A\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2", "\x31\xD2\x83\x3D\xF0\x87\x4B\0\0\x74\x1D\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x0C\0\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\x0A\0"], # TTSW10.moncheck
[0x46f2e3, 60, "\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\x0A\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2", "\x31\xD2\x83\x3D\xF0\x87\x4B\0\0\x74\x1D\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x0F\0\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\x0A\0"], # TTSW10.ichicheck

# battle w Vampire
[0x4686ed, 67, "\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\x0A\0\x8B\3\x8D\4\x40", "\xC7\x44\x46\2\5\0\x0C\0\x31\xD2\xEB\4\x31\xD2\xEB\x1B\x83\3\2\x89\x54\x46\x12\x66\x89\x54\x46\x16\xC7\x44\x46\x18\1\0\5\0\x66\xC7\x44\x46\x1C\xFF\1\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\x0A\0\x15\0\xEB\x0C"], # TTSW10.moncheck

# battle w Archsorcerer
[0x468bb6, 60, "\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\6\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2", "\x31\xD2\x83\x3D\xF0\x87\x4B\0\0\x74\x1D\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x0C\0\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\6\0"], # TTSW10.moncheck
[0x4727df, 60, "\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\x0A\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2", "\x31\xD2\x83\x3D\xF0\x87\x4B\0\0\x74\x1D\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\7\0\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\x0A\0"], # TTSW10.ichicheck

# battle w Knights
[0x46ab26, 12, "\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0", "\xC7\x44\x46\2\5\0\x0C\0\x90\x90\x90\x90"], # TTSW10.moncheck
[0x473fb4, 60, "\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\6\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2", "\x31\xD2\x83\x3D\xF0\x87\x4B\0\0\x74\x1D\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0\6\0\x66\xC7\x44\x46\4\0\0\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\6\0"], # TTSW10.ichicheck
[0x475eaa, 60, "\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\x0A\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2", "\x31\xD2\x83\x3D\xF0\x87\x4B\0\0\x74\x1D\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x12\0\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\x0A\0"], # TTSW10.ichicheck

# battle w Sorcerers
[0x46bf97, 12, "\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0", "\xC7\x44\x46\2\5\0\x0C\0\x90\x90\x90\x90"], # TTSW10.moncheck

# 42F Zeno-GKnight event
[0x47600b, 60, "\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\1\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2", "\x31\xD2\x83\x3D\xF0\x87\x4B\0\0\x74\x1D\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x09\1\x83\3\2\x83\xC0\6\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\4\x46\1\0"], # TTSW10.ichicheck
[0x476853, 23, "\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0\x8B\3\x8D\4\x40", "\xC7\4\x46\0\0\0\0\x83\x3D\xF0\x87\x4B\0\0\x74\7\xC7\4\x46\1\0\6\0"], # TTSW10.ichicheck

# 50F 1st-round Zeno event
[0x446571, 60, "\x66\xC7\4\x46\0\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\4\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\x0B\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\x0C\0\x8B\3\x8D\4\x40", "\x83\x3D\xF0\x87\x4B\0\0\x74\x13\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x14\0\xFF\3\x83\xC0\3\xC7\4\x46\0\0\4\0\x66\xC7\x44\x46\4\0\0\xFF\3\x83\xC0\3\x66\xC7\4\x46\x0B\0\x66\xC7\x44\x46\2\x0C\0"], # TTSW10.handan
# 24F "gate of space and time"
[0x470e32, 23, "\x8B\3\x8D\4\x40\x66\xC7\4\x46\x0F\0\x8B\3\x8D\4\x40\x66\xC7\x44\x46\2\0\0", "\x8B\x14\x46\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x0A\1\x83\xC0\3\x89\x14\x46"], # TTSW10.ichicheck

# 50F >=2nd-round Zeno event
[0x46cac5, 61,
"\x8B\x03\x8D\x04\x40\x66\xC7\x44\x46\x02\x00\x00\x8B\x03\x8D\x04\x40\x66\xC7\x44\x46\x04\x00\x00\xFF\x03\x8B\x03\x8D\x04\x40\x66\xC7\x04\x46\x0A\x00\x8B\x03\x8D\x04\x40\x66\xC7\x44\x46\x02\x3E\x00\x8B\x03\x8D\x04\x40\x66\xC7\x44\x46\x04\x63\x00", "\x31\xD2\x89\x54\x46\x02\xFF\x03\x83\xC0\x03\xC7\x04\x46\x0A\x00\x3E\x00\x66\xC7\x44\x46\x04\x63\x00\x83\x3D\xF0\x87\x4B\x00\x00\x74\x1B\x83\x03\x02\x83\xC0\x06\x89\x54\x46\xFA\x66\x89\x54\x46\xFE\xC7\x04\x46\x01\x00\x06\x00\x66\x89\x54\x46\x04"], # TTSW10.moncheck

# 3F Zeno event
[0x46431d, 45, "\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x66\xC7\x44\x46\2\0\0\x66\xC7\x44\x46\4\0\0\xFF\3\x8B\3\x8D\4\x40\x66\xC7\4\x46\0\0\x66\xC7\x44\x46\2\0\0", "\x83\xC0\3\x83\x3D\xF0\x87\x4B\0\0\x74\x28\xC7\4\x46\1\0\5\0\x66\xC7\x44\x46\4\x0B\1\x83\3\2\x83\xC0\3\x31\xD2\x89\x14\x46\x89\x54\x46\4\x89\x54\x46\x08"], # TTSW10.opening2
# 2F Zeno event aftermath
[0x44dc78, 38, "\x33\xC0\xA3\xAC\xC5\x48\0\x8B\xC3\xE8\xB2\x4F\xFF\xFF\x33\xD2\x8B\x83\xCC\1\0\0\xE8\x6D\x58\xFC\xFF\x33\xD2\x8B\x83\xCC\1\0\0\xE8\x34\x59", "\xA3\xAC\xC5\x48\0\x8B\xC3\xE8\xB4\x4F\xFF\xFF\x8B\x15\xF0\x87\x4B\0\x85\xD2\x74\7\xB2\5\xE8%s\x8B\x83\xCC\1\0\0\xE8\x60\x58", :@_sub_instruct_playBGM_direct, 29] # TTSW10.Button1Click (OK)
]

  class << self
    attr_reader :bgm_path
    attr_reader :_bgm_filename
    attr_reader :_bgm_basename
  end
  module_function
  def init
    BGM_PATCH_BYTES_0.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[3], i[1], 0)} # must-do patches
    @bgm_path = $BGMpath
    bgm_basename = BGM_PHANTOMFLOOR + '.mp3'
    unless @bgm_path
      if File.exist?(BGM_DIRNAME+'/'+bgm_basename) # find in current dir
        @bgm_path = CUR_PATH
      else # find in app dir
        @bgm_path = APP_PATH
      end
      @bgm_path += '/'+BGM_DIRNAME
      @bgm_path.encode!('filesystem').force_encoding('ASCII-8Bit') if RUBY_HAVE_ENCODING # this is necessary for Ruby > 1.9
    end
    @bgm_path = @bgm_path[0, 2].gsub('/', "\\") + @bgm_path[2..-1].gsub(/[\/\\]+/, "\\").sub(/\\?$/, "\\") # normalize file path (changing / into \; reducing multiple consecutive slashes into 1; always add a tailing \); the first 2 chars might be \\ which should not be reduced
    bgm_filename = @bgm_path + bgm_basename
    bgm_filename_enc = bgm_filename.dup
    bgm_filename_enc.force_encoding('filesystem') if RUBY_HAVE_ENCODING # this is necessary for Ruby > 1.9
    bgmsize = bgm_filename.size
    return raiseInvalDir(26) if bgmsize > MAX_PATH-2 # MAX_PATH includes the tailing \0
    return raiseInvalDir(27) unless File.exist?(bgm_filename_enc)

    fadeStrength = 999 / BGM_FADE_STEPS + 1 # i.e. (1000.0 / BGM_FADE_STEPS).ceil

    # the first 0xa00 bytes are reserved for tswSL
    # these are all pointers to the corresponding variables:
    @_bgm_filename = $lpNewAddr + 0xa00
    @_bgm_basename = @_bgm_filename + bgmsize - 12
    @_bgm_phantomfloor = $lpNewAddr + 0xb04
    @_isInProlog = $lpNewAddr + 0xb0c
    @_last_bgmid = $lpNewAddr + 0xb10
    @_mci_params = $lpNewAddr + 0xb14
    @_mci_params_volume = @_mci_params + 8
    offset_sub_soundplay_real = 0xb20
    @_sub_soundplay_real = $lpNewAddr + offset_sub_soundplay_real
    @_sub_timer4ontimer_real = $lpNewAddr + 0xb64
    @_sub_instruct_playBGM = $lpNewAddr + 0xc00
    @_sub_instruct_playBGM_direct = @_sub_instruct_playBGM + 11
    @_sub_checkOrbFlight = $lpNewAddr + 0xc38
    @_sub_checkBGM_ext = $lpNewAddr + 0xc64
    @_sub_resetTTimer4 = $lpNewAddr + 0xd0c
    @_sub_initBGM = $lpNewAddr + 0xd38
    @_sub_finalizeBGM = $lpNewAddr + 0xd90
    @_sub_save_excludeBGM = $lpNewAddr + 0xdd8

    injBuf = bgm_filename.ljust(MAX_PATH, "\0") + BGM_PHANTOMFLOOR +
[1, 0xff].pack('LL') + # 0B0C byte isInProlog; 0B10 byte last_bgmid
[0, MCI_DGV_SETAUDIO_VOLUME, 1000].pack('lll') + # 0B14 mci_params
# HWND dwCallback (no need); DWORD dwItem (volume); DWORD dwValue (volume fraction 0 to 1000)

# 0B20: subroutine soundplay_real
"\x55\x8B\xEC\x6A\0\x53\x56\x57\x8B\xD8\x31\xC0\x55\x68\x0C\xC7\x47\0\x64\xFF\x30\x64\x89\x20\xA1" +
[BGM_ID_ADDR, 0xc083, 0x83fb, 0x11f8, 0x1877, 0xbf, @_bgm_basename, 0xbe, @_bgm_phantomfloor,
 0x0974, 0xf06b, BGM_BASENAME_GAP, 0xc681, BGM_BASENAME_ADDR, 0xa5fc, 0xe9a5,
 BGM_PLAY_OPEN_N_PLAY_ADDR-$lpNewAddr-0xb62, 0x9090].pack('LSSSSCLCLSSCSLSSlS') + # 0B5D...0B62 jmp 47c6d3

# 0B64: subroutine timer4ontimer_real
[0xb8, @_mci_params, 0x7881, 8, 1000, 0x1b75, 0x158b, BGM_ID_ADDR, 0x153a, @_last_bgmid,
 0x0d75, 0x838b, OFFSET_TTIMER4, 0xd231, 0xe9, TTIMER_SETENABLED_ADDR-$lpNewAddr-0xb8d, # 0B88...0B8D jmp TTimer.SetEnabled
 0x6881, 8, fadeStrength, 0x7350, 0x6a09, 0x6800,
 MCI_CLOSE, 0x0aeb, 0x68, MCI_DGV_SETAUDIO_ITEM_VALUE, 0x68, MCI_SETAUDIO,
 0x838b, OFFSET_TMEDIAPLAYER5, 0xb70f, 0x80, OFFSET_TMEDIAPLAYER_DEVICEID,
 0xe850, MCISENDCOMMAND_ADDR-$lpNewAddr-0xbbd, # 0BB8...0BBD call winmm.mciSendCommandA
 0xc085, 0xb8, @_mci_params_volume, 0x0575, 0x3883, 0, 0x3479,
 0x00c7, 1000, 0x838b, OFFSET_TMEDIAPLAYER5, 0xd231, 0x9088, OFFSET_TMEDIAPLAYER_PLAYSTATE, 0x838b, OFFSET_TTIMER4,
 0xe8, TTIMER_SETENABLED_ADDR-$lpNewAddr-0xbea, # 0BE5...0BEA call TTimer.SetEnabled
 0xa1, BGM_ID_ADDR, 0xa2, @_last_bgmid, 0x013c, 0x0778, 0xc38b,
 0xe9, offset_sub_soundplay_real-0xbff, # 0BFA...0BFF jmp sub_soundplay_real
 0xc3].pack('CLSCLSSLSLSSLSClSCLSSSLSCLCLSLSCLSlSCLSSCSSLSLSSLSLClCLCLSSSClC') +

# 0C00: subroutine instruct_playBGM
"\x8B\x14\x4D\x50\xC7\x48\0\x84\xD2\x74\x2B\x88\x15" +
[BGM_ID_ADDR, 0xf684, 0x0b74, 0x838b, OFFSET_TMEDIAPLAYER6, 0xe8, TMEDIAPLAYER_CLOSE_ADDR-$lpNewAddr-0xc20, # 0C1B...0C20 call TMediaPlayer.Close
 0x838b, OFFSET_TTIMER4, 0x06b2, 0xe8, TTIMER_SETENABLED_ADDR-$lpNewAddr-0xc2d, # 0C28...0C2D call TTimer.SetEnabled
 0xc38b, 0xe8, TTIMER4_ONTIMER_ADDR-$lpNewAddr-0xc34, # 0C2F...0C34 jmp TTSW10.timer4ontimer
 0xd231, 0x90c3].pack('LSSSLClSLSClSClSS') +

# 0C38: subroutine checkOrbFlight
[0xb9, BGM_ID_ADDR, 0xba, @_last_bgmid, 0x3980, 0x7801, 0xe81b,
 BGM_CHECK_ADDR-$lpNewAddr-0xc4c].pack('CLCLSSSl') + # 0C47...0C4C call TTSW10.soundcheck
"\x8A\2\x3A\1\x74\x10\xC6\1\xFF\xB2\6\x8B\x83" +
[OFFSET_TTIMER4, 0xe9, TTIMER_SETENABLED_ADDR-$lpNewAddr-0xc62, # 0C5D...0C62 jmp TTimer.SetEnabled
 0x90c3].pack('LClS') +

# 0C64: subroutine checkBGM_ext
[0xb8, STATUS_ADDR, 0x3883, 0, 0x0b75, 0x05c6, BGM_ID_ADDR].pack('CLSCSSL') +
"\x0E\x83\xC4\4\xC3\x8B\x40#{(STATUS_INDEX[4] << 2).chr}\x50" +
BGM_CHECK_EXT.map {|i| [0xf883, i[0], 0x75, i[7], 0xb8, 0, i[5], i[6], 0xa0,
 MAP_ADDR+123*i[0]+11*i[1]+i[2]+2, 0x258a, MAP_ADDR+123*i[0]+11*i[3]+i[4]+2,
 0xeb, i[8]].pack(i[8] ? 'SCCcCSCCCLSLCc' : 'SCCcCSCCCLSL')}.join +
"\x3C\x17\x75\4\xB0\x0C\xEB\x0C\xC1\xE8\x08\x38\xE0\x74\2\x58\xC3\xC1\xE8\x10\xA2" +
[BGM_ID_ADDR, 0xc483, 0xc308, 0x90].pack('LSSC') +

# 0D0C: subroutine resetTTimer4
[0x488b, OFFSET_PARENT, 0x813b, OFFSET_TTIMER4, 0x1575, 0x05c6, @_isInProlog,
 0xb900, BGM_FADE_INTERVAL, 0x483b, OFFSET_TTIMER_INTERVAL, 0x0474, 0x4889,
 OFFSET_TTIMER_INTERVAL, 0xc3, 0x503a, OFFSET_TTIMER_ENABLED, 0x0375, 0xc483,
 4, 0x90c3, 0x9090].pack('SCSLSSLSLSCSSCCSCSSCSS') +

# 0D38: subroutine initBGM
[0xd88b, 0x838b, OFFSET_TTIMER4, 0x408a, OFFSET_TTIMER_ENABLED, 0x0124, 0xa2,
 @_isInProlog, 0xba, BGM_ID_ADDR, 0x0374, 0x02c6, 21, 0x028a, 0x013c, 0x0779,
 0xe8, BGM_CHECK_ADDR-$lpNewAddr-0xd5f, # 0D5A...0D5F call TTSW10.soundcheck
 0x028a, 0xa2, @_last_bgmid, 0x838b, OFFSET_TMEDIAPLAYER5, 0x80c6,
 OFFSET_TMEDIAPLAYER_PLAYSTATE, 0x0f00, 0x80b7, OFFSET_TMEDIAPLAYER_DEVICEID,
 0x68, @_mci_params, 0x006a, 0x68, MCI_CLOSE, 0xe850, MCISENDCOMMAND_ADDR-$lpNewAddr-0xd8C, # 0D87...0D8C call winmm.mciSendCommandA
 0x01b2, 0x04eb].pack('SSLSCSCLCLSSCSSSClSCLSLSLSSLCLSCLSlSS') +

# 0D90: subroutine finalizeBGM
[0xd231, 0xd88b, 0x1588, BGM_SETTING_ADDR, 0x838b, OFFSET_TMENUITEM_BGMON1,
 0xe8, TMENUITEM_SETCHECKED_ADDR-$lpNewAddr-0xda5, # 0DA0...0DA5 callTMenuItem.SetChecked
 0xd231, 0x1538, BGM_SETTING_ADDR, 0x0774, 0xc38b, 0xe9, offset_sub_soundplay_real-0xdb6, # 0DB1...0DB6 jmp sub_soundplay_real
 0x1589, BGM_ID_ADDR, 0x838b, OFFSET_TMEDIAPLAYER5,
 0xe8, TMEDIAPLAYER_CLOSE_ADDR-$lpNewAddr-0xdc7, # 0DC2...0DC7 call TMediaPlayer.Close
 0x158a, @_isInProlog, 0x838b, OFFSET_TTIMER4, 0xe9,
 TTIMER_SETENABLED_ADDR-$lpNewAddr-0xdd8].pack('SSSLSLClSSLSSClSLSLClSLSLCl') + # 0DD3...0DD8 jmp TTimer.SetEnabled

# 0DD8: subroutine save_excludeBGM
"\x31\xFF\x8B\x18\x53\x8D\x44\x24\x08\x57\x50\x51\x52\x53\xB8" +
[BGM_ID_ADDR, 0x188b, 0x1d29, DATA_CHECK1_ADDR, 0x1d29,
 DATA_CHECK2_ADDR, 0x3889, 0xe8, WRITE_FILE_ADDR-$lpNewAddr-0xe00, # 0DFB...0E00 call kernel32.WriteFile
 0xe8, CLOSE_HANDLE_ADDR-$lpNewAddr-0xe05, # 0E00...0E05 call kernel32.CloseHandle
 0x1d89, BGM_ID_ADDR, 0x0483, 0x1424, 0xc2, 4].pack('LSSLSLSClClSLSSCS')

    WriteProcessMemory.call_r($hPrc, @_bgm_filename, injBuf, injBuf.size, 0)

    takeOverBGM(true) if $BGMtakeOver
  end
  def takeOverBGM(bEnable)
    BGM_PATCH_BYTES.each do |i|
      if bEnable
        d = i[3]
        if (p=i[4])
          v = instance_variable_get(p)
          if (o=i[5])
            v -= o+i[0]
          end
          d = d % [v].pack('l')
        end
      else
        d = i[2]
      end
      WriteProcessMemory.call_r($hPrc, i[0], d, i[1], 0)
    end
    if bEnable
      callFunc(@_sub_initBGM)
    elsif !$preExitProcessed or ($BGMtakeOver and @bgm_path) # the following condition should not call sub_finalizeBGM: ($preExitProcessed && !($BGMtakeOver && @bgm_path)), because Timer4 is now changed back to prolog, so quitting tswBGM can sometimes cause unexpectedly ending the current game (more details: if $BGMtakeOver has never been turned on, then `sub_initBGM` never has a chance to run, and `isInProlog` thus remains TRUE; if @bgm_path is always nil, then `@_sub_finalizeBGM` will never be assigned)
      callFunc(@_sub_finalizeBGM)
    end
  end
  def raiseInvalDir(reason)
    quit() if $BGMtakeOver and msgboxTxt(23, MB_ICONEXCLAMATION | MB_OKCANCEL, $str::STRINGS[reason]) == IDCANCEL
    @bgm_path = nil
  end
end
