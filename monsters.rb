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
# This module provides functions for managing monster and hero stats, and battle calculations.
# It includes methods for determining monster IDs, calculating battle damage,
# handling magic attacks, and updating map tiles with damage information.

# Instance Variables:
#   @check_mag      [Boolean] Whether to check for sorcerers and magicians.
#   @cross          [Boolean] Whether the hero has the Cross item.
#   @dragonSlayer   [Boolean] Whether the hero has the Dragon Slayer item.
#   @luckyGold      [Boolean] Whether the hero has Lucky Gold.
#   @heroOrb        [Boolean] Whether the hero has the Hero Orb.
#   @heroHP         [Integer] Hero's HP.
#   @heroATK        [Integer] Hero's ATK.
#   @heroDEF        [Integer] Hero's DEF.
#   @statusFactor   [Integer] Status multiplier (1 or 44).
#   @monsters       [Hash]    Details about monsters on the current floor.
#   @magAttacks     [Array]   Magic attack damage from wizards at each tile.

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
  # Returns the monster ID for a given tile ID, or nil if not a monster tile.
    if tileID < 61 # not a monster tile
      nil
    elsif tileID < 97 # slimeG - vampire
      tileID - 61 >> 1
    elsif tileID < 106 # octopus
      18
    elsif tileID == 122 # dragon
      19
    elsif tileID < 133 # octopus/dragon not for battle
      nil
    elsif tileID < 159 # goldenKnight - GatemanA
      tileID - 93 >> 1
    else nil # invalid tile
    end
  end
  def getStatus(monster_id)
  # Calculates the battle stats between the hero and a specified monster.
  # The calculation considers special items (Cross, DragonSlayer), and status factors (*44 or not).

  # @param monster_id [Integer] The ID of the monster to retrieve status for.
  # @return [Array] Returns an array containing:
  #   - dmg [Integer, String]: Total damage the hero will take, or a string if unable to attack.
  #   - oneTurnDmg [Integer]: Damage taken by the hero per turn.
  #   - turnsCount [Integer, String]: Number of turns required to defeat the monster, or a string if unable to attack.
  #   - criVals [Array]: Array of critical attack values for the hero to defeat the monster in fewer turns.
  #   - mGold [Integer]: Amount of gold dropped by the monster (may be doubled if @luckyGold is true).
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
  # Checks and updates the map state for monsters and magic attacks.
  # Iterates through all map tiles (indices 0 to 120) and performs actions based on tile type:
  #   - For tile type 255 (special tile):
  #     - Skips calculation if $MPnewMode is enabled (no need; handled elsewhere) or @heroOrb is not present.
  #     - If magic attack damage is not recorded, updates the tile and calculates damage.
  #     - Otherwise, draws the damage value on the map.
  #   - For tile types 1..7 and 29..60 (doors, roads, items):
  #     - Calculates magic damage if initializing and magic check is enabled.
  #   - For other tile types:
  #     - Calculates monster damage if @heroOrb is present.

  # @param init [Boolean] Indicates whether to initialize the map state. If true, clears the monsters and resets magic attacks.
    if init
      @monsters.clear
      @magAttacks.fill(nil)
    end
    for i in 0...121
      case $mapTiles[i].abs
      when 255
        next unless @heroOrb
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
  # Calculates and shows magical damage to the hero based on adjacent monsters, at a given map tile index.

  # The method checks for the following conditions:
  # - If the hero is flanked by sorcerers (monster ID 16) on both sides (left/right or up/down),
  #   sets the map tile to 255 (special tile) and calculates damage as half of hero's HP (rounded up).
  # - If adjacent to magicians (monster ID 29 or 30), adds 200 or 100 damage respectively for each adjacent magician.
  # - If no adjacent magicians and not flanked by sorcerers, returns with no damage.
  # - If damage exists, updates the map tile, checks for special modes (see below), and stores the damage in @magAttacks.
  #   - If @heroOrb is not present, skips further damage calculation.
  #   - Damage from adjacent magicians is multiplied by @statusFactor.
  # - Draws the damage on the map using HookProcAPI.drawDmg.

  # @param i [Integer] The index in the map tile array, calculated as 11*y + x (vertical and horizontal positions, respectively; 0..10).
    y, x = i.divmod(11)
    left  = (x >  0) ? getMonsterID($mapTiles[i -  1].abs) : nil
    right = (x < 10) ? getMonsterID($mapTiles[i +  1].abs) : nil
    up    = (y >  0) ? getMonsterID($mapTiles[i - 11].abs) : nil
    down  = (y < 10) ? getMonsterID($mapTiles[i + 11].abs) : nil
    dmg1 = 0
    if (left == 16 && right == 16) || (up == 16 && down == 16) # flanked by sorcerers
      $mapTiles[i] = 255
      return unless @heroOrb
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
      return unless @heroOrb
      dmg1 += dmg2*@statusFactor
    end
    @magAttacks[i] = dmg1
    HookProcAPI.drawDmg(x, y, normalize(dmg1).to_s, false, dmg1 >= @heroHP) # cri=false --> magic attack
  end
  def getMonDmg(i)
  # Calculates and displays the normal damage information for a monster at the given map tile index, at a given map tile index.
  # The method retrieves the monster ID from the map tile, fetches or initializes its status,
  # and, if in legacy mode, calculates the damage and critical attack information.
  # It then calls HookProcAPI.drawDmg to display the damage, critical attack value, and danger status (damage >= hero HP).

  # @param i [Integer] The index in the map tile array
    mID = getMonsterID($mapTiles[i].abs)
    return unless mID

    y, x = i.divmod(11)
    res = @monsters[mID]
    if !res then res = getStatus(mID); @monsters[mID] = res end
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
  # Formats detailed battle information about a monster, which will be shown in the bottom status bar.

  # @param octopusPart [Boolean] Indicates if the monster is an octopus part (affects gold reward).
  # @param dmg;oneTurnDmg;turnsCount;criVals;mGold: The original values.

  # @return [Array] Returns an array containing:
  #   - dmg and oneTurnDmg: if in the backside tower and the monster is defeatable, these values are formatted to show both the scaled and normalized values (e.g., "88[2]").
  #   - turnsCount: not changed.
  #   - mGold: halved if octopus part.
  #   - criVals: previous and next critical values are shown separately; both are formatted similarly to dmg; if no previous critical value (DEF-out), returns an empty string; if no next critical values (ATK-out), returns only the previous critical value.
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
  # Formats a dmg or criVals value for display, showing both scaled and normalized values if in the backside tower.
    return val if val.zero? # no need to show the value divided by 44 if it's already 0
    return "#{val}[#{normalize(val)}]"
  end
  def normalize(val)
  # Converts a scaled value in the backside tower to its normalized form based on @statusFactor, rounded up.
    return (val-1) / @statusFactor + 1
  end
end
