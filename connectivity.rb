#!/usr/bin/env ruby
# Author: Z.Sun

module Connectivity
# Connectivity module provides pathfinding and route calculation utilities for the grid-based map.
# It uses flood fill to determine accessible tiles and reconstructs movement routes.
# BFS (Breadth-First Search; using a queue for storage) is employed, instead of DFS (Depth-First Search; using a stack for storage),
# because BFS guarantees the shortest path in an unweighted grid, and that path will be rendered on the map using PolyLine.

# Usage:
#   - Call `Connectivity.floodfill(ox, oy)` to initialize pathfinding from origin (ox, oy).
#   - Call `Connectivity.main(tx, ty)` to calculate route to destination (tx, ty).

# Instance Variables:
#   @queue [Array<Integer>]: BFS task queue for managing what tile to process next and the order of tile processing; each element is an index (0-120) corresponding to a position on an 11x11 grid.
#   @ancestor [Array<Integer>]: Has a length of 121, corresponding to each position on an 11x11 grid. Each element records the parent position (index) from which the current position was reached during pathfinding. This is used to reconstruct the path taken.
#   @route [Array<Integer>]: Sequence of x and y pixel coordinates of the route from a source to a destination, which will be used for rendering the path using PolyLine. Each tile in the route contains two elements, x and y, respectively, so the number of Array elements is twice the length of the route.
#   @destTile [Integer]: The target tile's type; used to determine accessibility (directly accessible, event tile, or impassible).
#   @facing [Integer, nil]: The direction that hero is supposed to faceupon reaching the destination (1: down, 2: left, 3: right, 4: up).

  @queue = []
  @ancestor = Array.new(121) # for each position, record its parent position (where it is moved from)
  @route = []
  @destTile = 0
  @facing = nil
  class << self
    attr_reader :route
    attr_reader :destTile
    attr_reader :facing
  end
# note: in order to detect magic attacks (mark these floor tiles as impassible), need to call `Monsters.checkMap` beforehand
  module_function
  def main(tx, ty) # end point: (tx, ty)
  # Calculates the route from the current position to the target tile (tx, ty).
  # Updates @route with the path, checks accessibility, and sets @facing direction.

  # @param tx [Integer] The x-coordinate of the target tile.
  # @param ty [Integer] The y-coordinate of the target tile.
  # @return [Integer, nil] Returns 0 if the destination is directly accessible, a nonzero integer if a step is required
  #   (+1, -1, +11, or -11, indicating the direction), or nil if the destination is inaccessible or an error occurs.
    @route.clear # clear last route
    @route.push(tx*$TILE_SIZE+$MAP_LEFT+$TILE_SIZE/2, ty*$TILE_SIZE+$MAP_TOP+$TILE_SIZE/2)
    @facing = nil
    t_index = 11*ty + tx
    @destTile = $mapTiles[t_index]
    return nil if @destTile > 0 # inaccessible
    @destTile = -@destTile # a zero value indicates an accessible floor tile; a negative value indicates an accessible event tile (see `floodfill`), so negate it back to positive value here

    index = @ancestor[t_index]
    case @destTile
    when 4, 5, 8, 13, 14, 15, 17, 115..121, 123..132, 159..254 # gate; prison; lava; starlight; wings of altar; dragon (not head); other
      return nil # impassible
    when 0
      d_i = index - t_index
      access = 0 # in this case, can directly go to that destination
    else
      access = d_i = index - t_index # in this case, should first go to somewhere 1 step away from destination
    end

    loop do
      y, x = index.divmod(11)
      @route.push(x*$TILE_SIZE+$MAP_LEFT+$TILE_SIZE/2, y*$TILE_SIZE+$MAP_TOP+$TILE_SIZE/2)
      break if index == @o_index
      index = @ancestor[index]
    end
    if d_i == -11 then @facing = 1 # facing down
    elsif d_i == 1 then @facing = 2 # facing left
    elsif d_i == -1 then @facing = 3 # facing right
    elsif d_i == 11 then @facing = 4 # facing up
    end
    return access
  rescue # unlikely, but in case the ancestor of a position can't be found, return false
    return nil
  end
  def floodfill(ox, oy) # starting point: (ox, oy)
  # Performs a flood fill algorithm starting from the given coordinates (ox, oy).
  # Marks visited (i.e., accessible) tiles in the global $mapTiles array by
  # - setting their value to 0 if the tile is a floor tile (type id == 6).
  # - negates their value otherwise (i.e., the tile is either impassible or an event tile).
  #   This is to indicate that the tile has been processed and should not be revisited.
  # Uses a queue to traverse neighboring tiles in four directions (up, down, left, right).
  # Skips tiles that have already been visited (explicitly for zeros; negative ones will also be implicitly skipped in `neighbor`).

  # @param ox [Integer] The x-coordinate of the starting point.
  # @param oy [Integer] The y-coordinate of the starting point.
    @o_index = 11*oy + ox
    @queue = [@o_index]
    @ancestor.fill(nil)

    init = true
    until @queue.empty?
      index = @queue.shift # current index; remove the first element of @queue
      next if $mapTiles[index].zero? # already visited before
      if init then init = false else $mapTiles[index] = 0 end # always mark the starting tile as 0 (visited floor tile)
      y, x = index.divmod(11)

      neighbor(index,  -1) if x >  0
      neighbor(index,   1) if x < 10
      neighbor(index, -11) if y >  0
      neighbor(index,  11) if y < 10
    end
  end
  def neighbor(index, offset)
  # Private method called by `floodfill`. Processes a neighboring tile based on its index and direction (offset).
  # - If the neighbor tile has already processed (id <= 0), returns immediately.
  # - Otherwise, @ancestor of that tile will be updated, and for its $mapTiles type value:
  #   - If the neighbor tile's type id is 6, adds it to the processing @queue (Its type will then be marked as zero in `floodfill`).
  #   - Otherwise (impassible or event tile), marks the neighbor tile as completed by negating its type value.

  # @param index [Integer] The current tile index.
  # @param offset [Integer] The offset (+1, -1, +11, or -11, indicating direction) to get the neighbor tile's index.
    index2 = index + offset
    id = $mapTiles[index2]
    return if id <= 0 # already has an ancestor

    if id == 6
      @queue.push(index2)
    else
      $mapTiles[index2] = -id # search ends here, but still need to record an ancestor, and mark its status as completed
    end
    @ancestor[index2] = index
  end
end
