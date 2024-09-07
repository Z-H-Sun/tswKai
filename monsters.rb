#!/usr/bin/env ruby
# Author: Z.Sun

SHOW_MONSTER_STATUS_ADDR = 0x4b78c + BASE_ADDRESS # TTSW10.monshyouji
CUR_MONSTER_ID_ADDR = 0x8c5b8 + BASE_ADDRESS
MONSTER_STATUS_FACTOR_ADDR = 0xb8904 + BASE_ADDRESS
MONSTER_STATUS_ADDR = 0x89910 + BASE_ADDRESS
MONSTER_STATUS_LEN = 132 # 33*4 (4=HP/ATK/DEF/GOLD)
MONSTER_STATUS_TYPE = 'L132'
DAMAGE_DISPLAY_FONT = [16, 6, 0, 0, 700, 0, 0, 0, 0, 0, 0, NONANTIALIASED_QUALITY, 0, 'Tahoma']

module Monsters
  @check_mag = false # whether to check sorcerers and magicians
  @cross = false
  @dragonSlayer = false
  @luckyGold = false
  @heroOrb = false
  @heroHP = 1000
  @heroATK = 100
  @heroDEF = 100
  @statusFactor = 1
  @monsters = Hash.new() # details about monsters on this floor
  @magAttacks = Array.new(121) # places and damage where you will get magic attacks from wizards
  class << self
    attr_writer :check_mag
    attr_writer :cross
    attr_writer :dragonSlayer
    attr_writer :luckyGold
    attr_accessor :heroOrb
    attr_accessor :heroHP
    attr_accessor :heroATK
    attr_accessor :heroDEF
    attr_accessor :monsters
    attr_accessor :magAttacks
    attr_accessor :statusFactor # 1 or 44
  end
  module_function
  def getMonsterID(tileID)
    return 19 if tileID == 122
    if tileID < 61 or tileID > 158
      nil
    elsif tileID < 97
      tileID - 61 >> 1
    elsif tileID < 106
      18
    elsif tileID < 133
      nil
    else
      tileID - 93 >> 1
    end
  end
  def getStatus(monster_id)
    mHP, mATK, mDEF, mGold = $monStatus[monster_id*4, 4]
    mGold <<= 1 if @luckyGold
    mHP *= @statusFactor
    mATK *= @statusFactor
    mDEF *= @statusFactor
    oneTurnDmg = mATK - @heroDEF
    oneTurnDmg = 0 if oneTurnDmg < 0
    heroATKfactor = (((monster_id == 17 || monster_id == 12 || monster_id == 13) && @cross) || (monster_id == 19 && @dragonSlayer)) ? 2 : 1
    diff = @heroATK - mDEF
    if diff <= 0 # the condition should have been `oneTurnDmg2Mon <= 0`, but in TSW, when you battle with vampire / dragon, even with Cross / DragonSlayer, you will not be able to attack it if your ATK <= its DEF, despite that your ATK*2 > its DEF
      dmg = turnsCount = $str::STRINGS[-2]
      criVals = [nil, 1-diff] # should have been `1-oneTurnDmg2Mon`
    else
      oneTurnDmg2Mon = @heroATK*heroATKfactor - mDEF
      turnsCount = (mHP-1) / oneTurnDmg2Mon
      dmg = turnsCount * oneTurnDmg
      return dmg, oneTurnDmg, turnsCount, [nil], mGold if oneTurnDmg.zero? # if already DEF-out (zero one-turn-damage, and dmg is not Inf), no need to show critical values...
      criVals = []
      for i in 0..4 # prev and next 4 critical values
        next if turnsCount < i
        criVals << ((mHP-1)/(turnsCount+1-i)+mDEF)/heroATKfactor + 1 - @heroATK
      end
    end
    return dmg, oneTurnDmg, turnsCount, criVals, mGold
  end
  def checkMap(init)
    if init
      @monsters.clear
      @magAttacks.fill(nil)
    end
    for i in 0...121
      case $mapTiles[i].abs
      when 255
        break if $MPnewMode or !@heroOrb # no need for further calculation under such cases
        dmg = @magAttacks[i]
        if dmg.nil? # unlikely, but let's add this new item into database
          sign = $mapTiles[i] <=> 0
          $mapTiles[i] = 1 # this was 6 instead of 1 before. Because this scenario can only be caused by an unknown bug; let's be cautious and make this tile reachable but inpassible (1=yellow door)
          getMagDmg(i); $mapTiles[i] *= sign
        else
          y, x = i.divmod(11)
          HookProcAPI.drawDmg(x, y, normalize(dmg).to_s, false, dmg >= @heroHP) # cri=false --> magic attack
        end
      when 1..7, 29..60 # doors/road/items
        getMagDmg(i) if init and @check_mag
      else
        getMonDmg(i) if @heroOrb
      end
    end
  end
  def getMagDmg(i) # i = 11*y + x
    y, x = i.divmod(11)
    left  = (x >  0) ? getMonsterID($mapTiles[i -  1].abs) : nil
    right = (x < 10) ? getMonsterID($mapTiles[i +  1].abs) : nil
    up    = (y >  0) ? getMonsterID($mapTiles[i - 11].abs) : nil
    down  = (y < 10) ? getMonsterID($mapTiles[i + 11].abs) : nil
    dmg1 = 0
    if (left == 16 && right == 16) || (up == 16 && down == 16) # flanked by sorcerers
      $mapTiles[i] = 255
      return if $MPnewMode or !@heroOrb # no need for further calculation under such cases
      dmg1 = @heroHP + 1 >> 1
    end
    dmg2 = 0
    if left  == 29 then dmg2 += 200 elsif left  == 30 then dmg2 += 100 end # adjacent mag A/B
    if right == 29 then dmg2 += 200 elsif right == 30 then dmg2 += 100 end
    if up    == 29 then dmg2 += 200 elsif up    == 30 then dmg2 += 100 end
    if down  == 29 then dmg2 += 200 elsif down  == 30 then dmg2 += 100 end

    if dmg2.zero?
      return if dmg1.zero?
    else
      $mapTiles[i] = 255
      return if $MPnewMode or !@heroOrb # no need for further calculation under such cases
      dmg1 += dmg2*@statusFactor
    end
    @magAttacks[i] = dmg1
    HookProcAPI.drawDmg(x, y, normalize(dmg1).to_s, false, dmg1 >= @heroHP) # cri=false --> magic attack
  end
  def getMonDmg(i)
    mID = getMonsterID($mapTiles[i].abs)
    return unless mID

    res = @monsters[mID]
    if !res then res = getStatus(mID); @monsters[mID] = res end
    return if $MPnewMode # further calculation is only needed in legacy mode

    y, x = i.divmod(11)
    dmg = res[0]
    if dmg == $str::STRINGS[-2]
      danger = true
    else
      danger = (dmg >= @heroHP)
      dmg = normalize(dmg).to_s
    end
    cri = res[3][1]
    cri = normalize(cri).to_s if cri
    HookProcAPI.drawDmg(x, y, dmg, cri, danger)
  end
  def detail(octopusPart, dmg, oneTurnDmg, turnsCount, criVals, mGold)
    mGold >>= 1 if octopusPart # octopus part: 50 Gold; octopus head: 100 Gold
    criVals = criVals.dup() # copy the original array to avoid affecting its value
    prevCriVal = criVals.shift
    if @statusFactor != 1
      if dmg != $str::STRINGS[-2]
        dmg = format(dmg)
        prevCriVal = format(prevCriVal) if prevCriVal
      end
      oneTurnDmg = format(oneTurnDmg)
      criVals.map! {|i| format(i)}
    end
    if dmg == $str::STRINGS[-2]
      return dmg, oneTurnDmg, turnsCount, mGold, $str::STRINGS[16] % criVals.first
    elsif prevCriVal.nil? # no prevCriVal means DEF-out (zero one-turn-damage)
      return dmg, oneTurnDmg, turnsCount, mGold, ''
    elsif criVals.empty? # no next criVals means ATK-out (zero battle round)
      return dmg, oneTurnDmg, turnsCount, mGold, $str::STRINGS[15] % prevCriVal
    else
      return dmg, oneTurnDmg, turnsCount, mGold, ($str::STRINGS[15] % prevCriVal) + ($str::STRINGS[16] % criVals.join('/'))
    end
  end
  def format(val)
    return val if val.zero? # no need to show the value divided by 44 if it's already 0
    return "#{val}[#{normalize(val)}]"
  end
  def normalize(val)
    return (val-1) / @statusFactor + 1
  end
end
