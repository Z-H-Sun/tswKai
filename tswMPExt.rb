#!/usr/bin/env ruby
# encoding: ASCII-8Bit
# Author: Z.Sun
# asm codes: tswMPExt_*.asm

# the first half of this script file deals with tswExt functions
EXT_KEY = VK_RETURN # shortcut key for tswExt

module Math
  module_function
  unless defined?(cbrt) # low version Math.cbrt support (Ruby <= 1.9.0.1)
    def cbrt(x) # in this script, we will make sure that the argument x always >= 0, so no need to consider about cases when x < 0
    # if x >= 0
        return x**0.3333333333333333
    # else # pow(x,1.0/3) will return a complex number (or even NaN in Ruby 1.8) when x<0
    #   return -(-x)**0.3333333333333333
    # end
    end
  end
end

module Ext
  open('tswMPExt.bmp', 'rb') do |f| # temporary treatments here; in the future, the contents of EXT_BMP will be incorporated into tswMPDat.rb
    f.seek(14) # skip BMP file header
    EXT_BMP = [f.read(64), # first 40 bytes are BITMAPINFOHEADER, followed by 6*4 bytes of color table (6 RGBA colors in total)
      f.read(800)] # then, 40*40 pixel data, each pixel taking up 4 bits (half byte)
  end

  MAX_STATUS = 999999999 # to avoid int32 overflow
  MAX_VISITS = 9999

  HERO_FXYD_ADDR = 0x48c74c # a temporary variable for hero's current floor / x / y / facing direction (used when saving a temp data after using the "convience shop" function)
  SAVETEMP_PREP_ADDR = 0x480944 # preparations before saving a temp data (after using the "convience shop" function)
  POSTPROCESS_1_ADDR = 0x480980 # post processing after using the "convience shop" function
  POSTPROCESS_2_ADDR = 0x4809A8 # post processing after using the "clear monsters" function

  EXT_WPARAM = 2 # signature for the WM_APP message (so we can know the Msg means to open the tswExt console)
  EXT_OPTIONS = '012345' # items 0-5
  EXT_OPTIONS_LEN = EXT_OPTIONS.size
  EXT_DESCR_TITLE_LINE = EXT_OPTIONS_LEN+3 # "Description:"
  EXT_DESCR_TITLE_END = 16 # a short sentence will sometimes show in the same line at this col number
  EXT_DESCR_LINE = EXT_OPTIONS_LEN+5 # start showing descriptions for the selected item from Line 9
  EXT_DESCR_SIZE = (::Console::CONSOLE_HEIGHT-EXT_OPTIONS_LEN-3)*::Console::CONSOLE_WIDTH-EXT_DESCR_TITLE_END # space for descripions
  module Console # extension to the ::Console class
    module_function
    def pause(curInd, prompt=nil, allowEnter=false) # in addition to "press any key to continue," you can press arrow / numeric keys to select a different item
      case (c=$console.pause(prompt))
      when VK_LEFT, VK_UP
        return (curInd-1) % EXT_OPTIONS_LEN
      when VK_RIGHT, VK_DOWN
        return (curInd+1) % EXT_OPTIONS_LEN
      when VK_SPACE, VK_RETURN # if `allowEnter`, will determine whether the user confirms the message or pressed any other key
        if allowEnter
          $console.beep() unless $CONenableSoundEffect
          return true
        end
      when 0x30...(0x30+EXT_OPTIONS_LEN) # choose another item using numeric keys
        return c-0x30
      end
      $console.SE.cancellation()
      return false
    end
    def get_num(max)
      $console.show_cursor(true)
      $console.fprint(STYLE_B_YELLOW, '[1, %d]: ', max)
      if max < 10
        r = $console.choice_num(1, max, !$CONenableSoundEffect)
        $console.print(r.to_s)
      else
        if max < 100 then d = 2
        elsif max < 1000 then d = 3 # for altar visits, `max` won't exceed 999 (m_max <= cbrt(q) < cbrt(3*2^31/10) = 863), so at most 3 digits
        elsif max < 10000 then d = 4 # the `if` branches below are less likely
        elsif max < 100000 then d = 5
        elsif max < 1000000 then d = 6
        else d = 7 end # at most, you cannot sell more than 10^7 yellow keys, because otherwise, you will gain more than 10^9 gold, which can easily cause int32 overflow
        r = $console.get_num(d, !$CONenableSoundEffect)
        if r > max # ex: `max` is 789 but user enters 888, then need to rectify
          r = max
          x, y = $console.get_cursor()
          $console.cursor(x-d, y)
          $console.print(r.to_s)
        elsif r.zero?
          $console.SE.cancellation()
        end
      end
      return r
    end
  end

  module Altar
    ALTAR_FLOORS = {5=>46, 4=>32, 2=>12, 1=>4} # block => floor
    ALTAR_TILE_ID = 16 # 16-th tile is Altar (middle part)

    # check whether an altar is accessible from the downstairs stair
    # ignore magic attack (in TSW, there is no such scenario en route to altars)
    # DFS algorithm instead of BFS
    module Connectivity
      module_function
      def main(floorID)
        if $heroStatus[STATUS_INDEX[4]] == floorID # you are currently on that floor
          return (@t_i = $mapTiles.index(-ALTAR_TILE_ID)) # whether you can access altar on the current floor (already processed in the `::Connectivity` module)
        end

        ReadProcessMemory.call_r($hPrc, MAP_ADDR+floorID*123, $buf, 123, 0)
        o_i = $buf.ord # the 1st/2nd byte of each floor's map data is the location index (x+11*y) of the player when you go up/downstairs to this floor; here use the location of the first case
        @mapTiles = $buf[2, 121].unpack(MAP_TYPE)
        @t_i = @mapTiles.index(ALTAR_TILE_ID) # the location index (x+11*y) of the altar tile
        return nil unless @t_i # although unlikely, do not further process if an altar tile is not found

        @found = nil
        @mapTiles[o_i] = 6 # do not consider the origin points; set as floor
        floodFill(o_i)
        return @found
      end

      def floodFill(index) # index = 11*y + x
        return if @found # stop searching
        return (@found=index) if index == @t_i
        return if @mapTiles[index] != 6
        @mapTiles[index] = 0 # mark as visited
        y, x = index.divmod(11)
        floodFill(index -  1) if x > 0
        floodFill(index +  1) if x < 10
        floodFill(index - 11) if y > 0
        floodFill(index + 11) if y < 10
      end

      def altar_pos(); return @t_i+11; end # in TSW, the position right below altar is passable
    end

    module_function
    def need_init; @need_init = true; end # call this everytime tswExt starts; calculate once so the results can be used later

    def check() # return value is nil if OK; otherwise the id of reason to disable
      return 0 unless $mapTiles.include?(-11) or $mapTiles.include?(-12) # you must have access to stairs
      return 1 unless (@mul_max = highestMultiplier()) # you must have access to at least one altar
      return maxVisits()
    end

    def highestMultiplier()
      highestFloor = $heroStatus[STATUS_INDEX[5]]
      ALTAR_FLOORS.each_pair {|i, f| return i if highestFloor >= f && self::Connectivity.main(f)}
      return nil # no altar visited
    end

    # maximum number of visits *m* you can pay before you run out of Gold, given that you have visited the altar for *n* times before
    # see detailed math derivation in 'tswMPExt/altar_math.md'
    def maxVisits()
      n = $heroStatus[STATUS_INDEX[11]] # previous altar visits
      return 3 if n >= MAX_VISITS # upper limit reached; don't further process; because can easily lead to int32 overflow

      g = $heroStatus[STATUS_INDEX[3]]/10 # [Gold/10]
      @s_n = (n*n+5)*n # 3*S_n/10
      q = g*3+@s_n
      x = Math.cbrt(q).to_i
      x = MAX_VISITS if x > MAX_VISITS # upper limit reached; actually the operations below has already in the BigNum regime
      f = (x*x+5)*x
      @t_max = (f-@s_n) / 3 # [T_{n,m}/10]
      if f > q
        @t_max -= x*(x-1)+2
        x -= 1
      end
      return 2 if x <= n # not enough Gold even for a single visit (it's impossible to have x<n, but just to be a bit more cautious)
      @m_max = x-n
      return (x==MAX_VISITS ? false : nil) # no problem (but need to add a caveat if going to reach upper limit soon)
    end

    def main(i) # 0=HP; 1=ATK; 2=DEF
      if @need_init
        @disable_reason = check()
        @need_init = false
      end # otherwise, calculated before, use previous results directly
      disable_reason = @disable_reason
      n = $heroStatus[STATUS_INDEX[11]] # previous altar visits
      base = ::Monsters.statusFactor
      if disable_reason.nil? # no probem found. But still need to check if status values will overflow after power-up
        if $heroStatus[STATUS_INDEX[i]] > MAX_STATUS
          m_max = 0 # do not power-up any more
        elsif i.zero?
# HP: summation of (n+i)*100 for i=1 to m, i.e., 50m(m+2n+1), should be <= 999999999-HP_0, so m_max=\sqrt{n^2+n+0.25+c}-n-0.5, where c=[(999999999-HP_0)/50] ([...] is the integer part of ...)
# however, to get rid of float number 0.25 and 0.5, we consider the following approximation:
# let m_1 is the positive real root of equation m^2+2nm=c; then, it is obvious that f(m_1) = m_1^2+(2n+1)m_1 = c+m_1 >= c; also, consider f(m_1-1) = c-2n-m_1 <= c
# therefore, the actual root m_0 is between m_1-1 and m_1. However, we don't know whether the integer m_max, i.e., [m_0], is [m_1] or [m_1-1]
# anyway, we are assigning m_max to be [m_1], so, sometimes we may get a final HP that is slightly larger than 999999999, but that is fine
          base *= 50 # each power-up: 100*n pts
          tmp = n*n+(MAX_STATUS-$heroStatus[STATUS_INDEX[i]])/base
          m_max = (tmp <= 0) ? 0 : (Math.sqrt(tmp).to_i - n) # it is not likely to have `tmp` < 0, but if it happens, its square root is not well-defined
        else
          base *= @mul_max*i << 1 # each power-up: ATK: 2*multiplier pts; DEF: 4*multiplier pts
          m_max = (MAX_STATUS-$heroStatus[STATUS_INDEX[i]])/base
        end
        disable_reason = 4 if m_max <= 0
      end
      $console.cursor(1, EXT_DESCR_LINE)
      if disable_reason
        $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[53][disable_reason])
        $console.fprint(STYLE_B_RED, $str::STRINGS[54][0], n*n+n+2) if disable_reason == 2
        return Ext::Console.pause(i, $str::STRINGS[52][3])
      end
      if m_max > @m_max
        m_max = @m_max # this is the new upper limit after taking the final status value into consideration
      else
        disable_reason = false # add a caveat because upper limit will be soon exceeded
      end

      $console.print($str::STRINGS[54][1], @mul_max)
      if $SLautosave
        $console.cursor(EXT_DESCR_TITLE_END, EXT_DESCR_TITLE_LINE)
        $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[52][6])
      end
      val1 = base
      valm = base*m_max
      x = m_max + n
      if i.zero? # HP
        val1 *= n+1 << 1
        valm *= x+n+1
      end
      $console.cursor(1, EXT_DESCR_LINE+2)
      $console.fprint(STYLE_B_GREEN, $str::STRINGS[54][2], n*n+n+2, val1)
      $console.cursor(1, EXT_DESCR_LINE+3)
      $console.fprint(STYLE_B_RED, $str::STRINGS[54][3], m_max, ((x*x+5)*x - @s_n)/3, valm)
      if disable_reason == false
        $console.cursor(1, EXT_DESCR_LINE+4)
        $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[54][4])
      end
      $console.cursor(1, EXT_DESCR_LINE+1)
      $console.print($str::STRINGS[54][5])
      m = Ext::Console::get_num(m_max)
      return false if m <= 0 # cancel or enter 0
      x = m + n
      t = ((x*x+5)*x - @s_n)/3*10
      d = m*base # ATK: 2*m*multiplier; DEF: 4*m*multiplier
      d = (x+n+1)*m*base if i.zero? # HP: summation of (n+i)*100 for i=1 to m
      s = $str::STRINGS[54][-1-i]

      $console.cls_pos(0, EXT_DESCR_LINE+2, ::Console::CONSOLE_WIDTH*3)
      $console.cursor(1, EXT_DESCR_LINE+3)
      $console.fprint(STYLE_B_YELLOW, $str::STRINGS[55], t, d, s)
      $console.SE.transaction()
      # when saving a temp data, temporarily teleport the player to the altar location, so when you load that temp data, you knows the temp data was saved before you used the "convience altar"
      WriteProcessMemory.call_r($hPrc, TIMER1_ADDR, "\xc3", 1, 0) # TIMER1TIMER ret (disable; freeze) [it is unlikely that TSW will refresh during this short period of time, but just to be extra cautious]
      writeMemoryDWORD(HERO_FXYD_ADDR, (self::Connectivity.altar_pos() << 16) | ALTAR_FLOORS[@mul_max]) # LOWORD: floorID of altar; HIWORD: index (11*y+x) of altar
      callFunc(SAVETEMP_PREP_ADDR) # this takes care of everything (see tswMPExt_3.asm)
      callFunc(SL._sub_savetemp) if $SLautosave
      # the actual status changes
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[i] << 2), $heroStatus[STATUS_INDEX[i]]+d)
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[3] << 2), $heroStatus[STATUS_INDEX[3]]-t)
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[11] << 2), $heroStatus[STATUS_INDEX[11]]+m)
      # afterwards, teleport the player back to the current location, and update the player's status display
      callFunc(POSTPROCESS_1_ADDR)
      WriteProcessMemory.call_r($hPrc, TIMER1_ADDR, "\x53", 1, 0) # TIMER1TIMER push ebx (re-enable)
      showMsgTxtbox(55, t, d, s)
      return nil
    end
  end

  module Merchant
    MERCHANT_INDEX = 3 # this is the third extension item
    MERCHANT_FLOOR = 28
    MERCHANT_COORD = 40 # X=3, Y=7
    module_function
    def need_init; @need_init = true; end

    def check() # return value is nil if OK; otherwise the id of reason to disable
      return 0 unless $mapTiles.include?(-11) or $mapTiles.include?(-12) # you must have access to stairs
      return 1 if $heroStatus[STATUS_INDEX[5]] < MERCHANT_FLOOR # you must have been to at least 28F before
      return 2 if (maxKeys = $heroStatus[STATUS_INDEX[8]]) <= 0 # no key available
      maxKeys2 = (MAX_STATUS-$heroStatus[STATUS_INDEX[3]])/100
      return 3 if maxKeys2 <= 0 # too high GOLD already
      if maxKeys2 >= maxKeys # no problem
        @maxKeys = maxKeys
        return nil
      else # going to reach upper limit soon; need to add a caveat
        @maxKeys = maxKeys2
        return false
      end
    end

    def main()
      if @need_init
        @disable_reason = check()
        @need_init = false
      end # otherwise, calculated before, use previous results directly
      $console.cursor(1, EXT_DESCR_LINE)
      if @disable_reason
        $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[56][@disable_reason])
        return Ext::Console.pause(MERCHANT_INDEX, $str::STRINGS[52][3])
      end

      $console.fprint(STYLE_B_GREEN, $str::STRINGS[57][0], @maxKeys, @maxKeys)
      if $SLautosave
        $console.cursor(EXT_DESCR_TITLE_END, EXT_DESCR_TITLE_LINE)
        $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[52][6])
      end
      if @disable_reason == false
        $console.cursor(1, EXT_DESCR_LINE+2)
        $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[57][1])
      end
      $console.cursor(1, EXT_DESCR_LINE+1)
      $console.print($str::STRINGS[57][2])
      k = Ext::Console::get_num(@maxKeys)
      return false if k <= 0 # cancel or enter 0

      g = k * 100
      $console.cls_pos(0, EXT_DESCR_LINE+1, ::Console::CONSOLE_WIDTH*4)
      $console.cursor(1, EXT_DESCR_LINE+2)
      $console.fprint(STYLE_B_YELLOW, $str::STRINGS[58], k, g)
      $console.SE.transaction()
      # when saving a temp data, temporarily teleport the player to the merchant location, so when you load that temp data, you knows the temp data was saved before you used the "convience shop"
      WriteProcessMemory.call_r($hPrc, TIMER1_ADDR, "\xc3", 1, 0) # TIMER1TIMER ret (disable; freeze) [it is unlikely that TSW will refresh during this short period of time, but just to be extra cautious]
      writeMemoryDWORD(HERO_FXYD_ADDR, (MERCHANT_COORD+11 << 16) | MERCHANT_FLOOR) # LOWORD: floorID; HIWORD: index (11*y+x) of merchant (you will be one cell below it, so the actual index is MERCHANT_COORD+11)
      callFunc(SAVETEMP_PREP_ADDR) # this takes care of everything (see tswMPExt_3.asm)
      callFunc(SL._sub_savetemp) if $SLautosave
      # the actual status changes
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[3] << 2), $heroStatus[STATUS_INDEX[3]]+g)
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[8] << 2), $heroStatus[STATUS_INDEX[8]]-k)
      # afterwards, teleport the player back to the current location, and update the player's status display
      callFunc(POSTPROCESS_1_ADDR)
      callFunc(KEY_DISP_ADDR)
      WriteProcessMemory.call_r($hPrc, TIMER1_ADDR, "\x53", 1, 0) # TIMER1TIMER push ebx (re-enable)
      showMsgTxtbox(58, k, g)
      return nil
    end
  end

  module Monsters
    MONSTERS_INDEX = 4 # this is the fourth extension item
    @mapTilesRaw = "\0"*121
    @facing = 1
    module_function
    def need_init; @need_init = true; end

    def check() # return value is nil if OK; otherwise the id of reason to disable
      floor = $heroStatus[STATUS_INDEX[4]]
      return 1 if floor == 49 and $mapTiles.include?(-93) # 49F sorcerer
      curTile = $mapTiles[($heroStatus[STATUS_INDEX[7]]*11+$heroStatus[STATUS_INDEX[6]])]
      return 2 if curTile != 0 and curTile != 6 # not a "normal" road (i.e., without trap nor magic attack damage)
      ReadProcessMemory.call_r($hPrc, MAP_ADDR+floor*123+2, @mapTilesRaw, 121, 0)
      @monsterCount = @goldCount = 0
      @includeGiantMon = false # whether giant monsters (Octopus and Dragon) are included
      return 0 unless checkMon() # first, preliminary trial
      checkMonIter() # then, try next iterations
      return 3 if $heroStatus[STATUS_INDEX[3]]+@goldCount > MAX_STATUS
      return nil
    end

    def checkMon() # return value: whether any monster is detected
      includeGiantMon_last = @includeGiantMon
      monsterCount_last = @monsterCount
      for i in 0...121
        mID = ::Monsters.getMonsterID(-$mapTiles[i]) # $mapTiles[i] is negative if accessible; if inaccessible, `-$mapTiles[i]` will be negative, `getMonsterID(...)` will always return nil
        next unless mID
        mDetail = ::Monsters.monsters[mID]
        if !mDetail then mDetail = ::Monsters.getStatus(mID); ::Monsters.monsters[mID] = mDetail end # unlikely, but just to be extra cautious
        next if mDetail[0] != 0
        gold = mDetail[4]
        @last_loc = i unless @includeGiantMon # if Octopus / Dragon head is present, teleport to that location because TSW will judge whether to erase all 9 cells according to player's current location; otherwise, teleport the last monster's location
        @monsterCount += 1
        @mapTilesRaw[i] = "\6" # change to road = tile id 6
        if mID == 18 # Octopus
          if $mapTiles[i] == -104 # head
            @includeGiantMon = true
          else # part of octopus (not head)
            gold >>= 1
          end
        elsif mID == 19 # Dragon
          @includeGiantMon = true
          @mapTilesRaw[i-1, 3] = @mapTilesRaw[i-12, 3] = @mapTilesRaw[i-23, 3] = "\6\6\6" # clear all 9 cells of Dragon
        end
        @goldCount += gold
      end
      moreMonAvail = (@monsterCount != monsterCount_last)
      @facing = ::Connectivity.get_facing(@last_loc) if (!includeGiantMon_last) and moreMonAvail # if @includeGiantMon is already true prior to this round of `checkMon`, or no more monster detected in this round of `checkMon`, then don't update facing direction
      return moreMonAvail
    end

    def checkMonIter()
      ox = $heroStatus[STATUS_INDEX[6]]
      oy = $heroStatus[STATUS_INDEX[7]]
      begin # clear monster iteratively (it is possible that some monsters are blocked by some other monsters)
        # need to recalculate connectivity
        $mapTiles = @mapTilesRaw.unpack(MAP_TYPE)
        $mapTiles.each_with_index {|x, i| ::Monsters.getMagDmg(i) if x == 6} if ::Monsters.check_mag # re-tag the tiles with magic attack damage (this recalculation is sometimes necessary because if a wizard is eliminated, its surrounding tiles will now be safe, no longer with magic attack damage)
        ::Connectivity.floodfill(ox, oy)
      end while checkMon()
    end

    def main()
      if @need_init
        @disable_reason = check()
        @need_init = false
      end # otherwise, calculated before, use previous results directly
      $console.cursor(1, EXT_DESCR_LINE)
      if @disable_reason
        $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[59][@disable_reason])
        return Ext::Console.pause(MONSTERS_INDEX, $str::STRINGS[52][3])
      end

      $console.fprint(STYLE_B_GREEN, $str::STRINGS[60], @monsterCount, @goldCount)
      $console.cursor(1, EXT_DESCR_LINE+1)
      $console.fprint(STYLE_B_YELLOW, $str::STRINGS[52][4])
      r = Ext::Console.pause(MONSTERS_INDEX, $str::STRINGS[52][5], true)
      return r if r != true

      $console.cls_pos(0, EXT_DESCR_LINE+1, ::Console::CONSOLE_WIDTH*4)
      $console.cursor(1, EXT_DESCR_LINE+2)
      $console.fprint(STYLE_B_YELLOW, $str::STRINGS[61], @monsterCount, @goldCount)
      $console.SE.explosion()
      # first, update map and hero's gold/position/facing direction
      WriteProcessMemory.call_r($hPrc, MAP_ADDR+$heroStatus[STATUS_INDEX[4]]*123+2, @mapTilesRaw, 121, 0)
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[3] << 2), $heroStatus[STATUS_INDEX[3]]+@goldCount)
      writeMemoryDWORD(HERO_FACE_ADDR, @facing) if @facing # facing down
      y, x = @last_loc.divmod(11)
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[6] << 2), x)
      writeMemoryDWORD(STATUS_ADDR+(STATUS_INDEX[7] << 2), y) # teleport to the last monster's location (This is necessary for Dragon and Octopus, because TSW will judge whether to erase all 9 cells according to player's current location)
      # then, redraw map/hero overlay; trigger any monster event, if present
      callFunc(POSTPROCESS_2_ADDR)
      showMsgTxtbox(61, @monsterCount, @goldCount)
      return nil
    end
  end

  @need_init = true
  @curInd = 0 # current item index
  @nxtInd = nil # next item index (nil=not currently selected)

  module_function
  def need_init; @need_init = true; end

  def ExtMain()
    $console.show_cursor(false)
    if @nxtInd # pressed arrow key to navigate to a different item
      c = @nxtInd
      @nxtInd = nil
    else # normal cases
      c = @curInd = $console.choice(EXT_OPTIONS, false)
    end
    return nil if c == -1 # ENTER/SPACE/ESC

    $console.SE.selection()
    c += 1
    for i in 1..EXT_OPTIONS_LEN
      if i == c
        $console.attr_pos(5, i, STYLE_INVERT, 54) # highlight
      else
        $console.attr_pos(5, i, FOREGROUND_INTENSITY, 54) # dim display of other items
      end
    end
    $console.cls_pos(EXT_DESCR_TITLE_END, EXT_DESCR_TITLE_LINE, EXT_DESCR_SIZE)

    case c
    when 1..3
      r = Altar.main(c-1)
    when 4
      r = Merchant.main()
    when 5
      r = Monsters.main()
    else
      $console.cursor(1, EXT_DESCR_LINE)
      r = Ext::Console.pause(c-1, 'TODO') # TODO
    end

    if r
      @nxtInd = @curInd = r
      return true
    end
    (1..EXT_OPTIONS_LEN).each {|i| $console.attr_pos(5, i, STYLE_NORMAL, 54)} # cancel both highlight and dim display
    printDefaultDescr()
    return nil if r.nil?
    return true
  rescue TSWKaiError => e
    if e.is_a?(::Console::STDINCancelError) # pressed arrow key to go to another item
      if c # an item already highlighted, then go to a different item
        case e.arrow
        when VK_UP, VK_LEFT
          @curInd = (c-2) % EXT_OPTIONS_LEN
        when VK_DOWN, VK_RIGHT
          @curInd = c % EXT_OPTIONS_LEN
        end
      end # otherwise, highlight the last chosen item
      @nxtInd = @curInd
      return true
    elsif c # TSW quitted; the choice has been made and is currently inputting values
      (1..EXT_OPTIONS_LEN).each {|i| $console.attr_pos(5, i, STYLE_NORMAL, 54)} # cancel both highlight and dim display
      printDefaultDescr()
    end
    return ! e.is_a?(TSWQuitedError) # stop if TSW has quitted
  end

  def initInterface()
    $console.resize() # in case the windows size is changed
    $console.cls()
    $str::STRINGS[51].each_with_index {|x, i| $console.print_pos(1, i+1, x)} # \r\n does not seem to be properly treated as line breaks using `WriteConsoleOutputCharacter`, so have to do this line by line
    $console.p_rect(2, 1, 1, EXT_OPTIONS_LEN, EXT_OPTIONS, STYLE_B_YELLOW_U)
    $console.cls_pos(0, EXT_OPTIONS_LEN+1, ::Console::CONSOLE_WIDTH, false, 95) # '_'.ord
    $console.cursor(1, EXT_DESCR_TITLE_LINE)
    $console.fprint(STYLE_B_YELLOW_U, $str::STRINGS[52][0])
    printDefaultDescr()
  end

  def printDefaultDescr()
    $console.cls_pos(EXT_DESCR_TITLE_END, EXT_DESCR_TITLE_LINE, EXT_DESCR_SIZE)
    $console.cursor(1, EXT_DESCR_LINE)
    $console.print($str::STRINGS[52][1])
    $console.fprint(FOREGROUND_INTENSITY, $str::STRINGS[52][2])
  end

  def main()
    @curInd = 0
    @nxtInd = nil
    $console = ::Console.new if $console.nil?
    Kai.need_init() # since the console is used here in tswExt, the interface of tswKai needs redrawing in the future
    if $console.switchLang() or @need_init # if language has been changed, or the console interface has been used in tswExt module, need to redraw the whole interface
      @need_init = false
      initInterface()
    end
    $console.setConWinProp(false)
    return if $console.show(true).nil? # fail

    Altar.need_init
    Merchant.need_init
    Monsters.need_init

    $console.SE.selection()
    res = nil
    loop { break unless (res=ExtMain()) }
    $console.show(false) if res.nil? # ESC pressed
    # otherwise, if res==false (TSW quitted), the remainder will be processed in the main loop
  end
end

# ====================================================================================
# the second half of this script file deals with permanent on-map damage display, etc.
require 'tswMPDat' # given the huge size of opcodes, it is stored in binary format in this separate file

DRAW_HERO_ADDR = 0x4808b4
DRAW_HERO_2_ADDR = 0x480908
ERASE_AND_DRAW_HERO_ADDR = 0x480834

DPL_ADDR = 0x4bac68
EPL_ADDR = 0x4bad0c
POLYLINE_COUNT_ADDR = 0x489de5
POLYLINE_VERTICES_ADDR = 0x489e00

module MPExt
  @_tswMPExt_enabled = 0x4ba1b5
  @_always_show_overlay = 0x4ba1b7
  @_sub_ini = 0x4ba558
  @_sub_res = 0x4ba668
  @_sub_fin = 0x4ba6bc

  MP_PATCH_BYTES_3[-1][1] += 136
  MP_PATCH_BYTES_3[-1][2] += "\xB9\x98\x86\x4B\x00\xBA\x4C\xC7\x48\x00\xFF\x32\x8B\x01\x88\x02\x8B\x41\x08\x88\x42\x01\x8B\x41\x0C\x88\x42\x02\xA1\xE8\x87\x4B\x00\x88\x42\x03\x66\x8F\x01\x66\x58\xB2\x0B\xF6\xF2\x88\x61\x08\x88\x41\x0C\xC6\x05\xE8\x87\x4B\x00\x04\xC3\x90\xB9\x98\x86\x4B\x00\x8B\x15\x4C\xC7\x48\x00\x88\x11\x88\x71\x08\xC1\xEA\x10\x88\x51\x0C\x88\x35\xE8\x87\x4B\x00\xC6\x05\x8C\xC5\x48\x00\x00\xE9\x8C\xC1\xFC\xFF\x50\xE8\x8A\x22\xFC\xFF\x8B\x04\x24\xE8\xFE\xFE\xFF\xFF\x8B\x04\x24\xE8\x76\xC1\xFC\xFF\x8B\x04\x24\xE8\x1E\x5B\xFE\xFF\x58\xE9\x40\xB2\xFC\xFF" # temporary treatments here; in the future, the modified contents will be incorporated into tswMPDat.rb

  module_function
  def init
    MP_PATCH_BYTES_1.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}

    callFunc(@_sub_fin) # this is just to guarantee no GDI leak, in case the previous run of tswKai3 failed to clean up on exit
    if $MPnewMode
      changeState()
      callFunc(@_sub_ini)
    else
      WriteProcessMemory.call_r($hPrc, @_tswMPExt_enabled, "\0", 1, 0)
    end

    MP_PATCH_BYTES_2.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}
    MP_PATCH_BYTES_3.each {|i| WriteProcessMemory.call_r($hPrc, i[0], i[2], i[1], 0)}
  end
  def changeState
    WriteProcessMemory.call_r($hPrc, @_always_show_overlay, $MPshowMapDmg ? ($MPshowMapDmg == 1 ? "\1" : "\0") : "\xFF", 1, 0)
  end
  def finalize
    callFunc(@_sub_res) if ($MPnewMode == true) # do nothing if $MPnewMode==1
  end
end
