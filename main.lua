SPEED = 150

DIRECTION = 'none'

GRID = {
  {1,  2,  3,  4},
  {5,  6,  7,  8},
  {9,  10, 11, 12},
  {13, 14, 15, 0},
}
NIL_POS = {4, 4}
HIDDEN_POS = {0, 0}
ACTIVE_TILE = {  -- positions are specified in pixels {x, y}
  current = {0, 0},
  start = {0, 0},
  finish = {0, 0},
}

AXIS = 0

local lg = love.graphics

-- math for mapping ranges: https://stackoverflow.com/questions/5731863/mapping-a-numeric-range-onto-another
local function map(input, input_start, input_end, output_start, output_end)
  local output = output_start + (
    (output_end - output_start) / (input_end - input_start)
  ) * (input - input_start)
  return output
end

local function current_speed(x, x0, x1, cutoff)
  cutoff = cutoff or 0
  local f_start = cutoff + ((3 * math.pi) / 2)
  local f_end = -cutoff + (((3 * math.pi) / 2) + (2 * math.pi))
  local f_x = map(x, x0, x1, f_start, f_end)
  local speed = (math.sin(f_x) + 1) *  5
  if x0 > x1 then speed = -speed end
  --print('(sin(x) + 1) * 5', speed)
  return speed
end

local function locate_nil(grid)
  for row_idx = 1, #grid, 1 do
    for col_idx = 1, #grid[1], 1 do
      if grid[row_idx][col_idx] == 0
      then
        return {row_idx, col_idx}
      end
    end
  end
end

local function shuffle_grid(grid)
  for _ = 1, (#grid + #grid[1]) * 2 do
    local row_a = math.random(#grid)
    local row_b = math.random(#grid)
    local col_a = math.random(#grid[1])
    local col_b = math.random(#grid[1])
    local val_a = grid[row_a][col_a]
    local val_b = grid[row_b][col_b]
    grid[row_a][col_a] = val_b
    grid[row_b][col_b] = val_a
  end
  NIL_POS = locate_nil(grid)
end

local function print_grid(grid)
  for row_idx = 1, #grid, 1 do
    print(table.concat(grid[row_idx], '\t'))
  end
end

local function pixel_pos_from_tile_pos(row, col, spacing)
  spacing = spacing or 5
  local x = (col - 1) * 100 + spacing
  local y = (row - 1) * 100 + spacing
  return {x, y}
end

function love.keypressed(k)
  if k == 'escape' or k == 'q'
  then
    love.event.quit()
  end
  if DIRECTION ~= 'none'
  then
    goto skip_direction
  end
  if (k == 'h' or k == 'left') and NIL_POS[2] ~= #GRID[1]
  then
    AXIS = 1
    DIRECTION = 'left'
    HIDDEN_POS = {unpack(NIL_POS)}
    HIDDEN_POS[2] = HIDDEN_POS[2] + 1
  end
  if (k == 'l' or k == 'right') and NIL_POS[2] ~= 1
  then
    AXIS = 1
    DIRECTION = 'right'
    HIDDEN_POS = {unpack(NIL_POS)}
    HIDDEN_POS[2] = HIDDEN_POS[2] - 1
  end
  if (k == 'k' or k == 'up') and NIL_POS[1] ~= #GRID
  then
    AXIS = 2
    DIRECTION = 'up'
    HIDDEN_POS = {unpack(NIL_POS)}
    HIDDEN_POS[1] = HIDDEN_POS[1] + 1
  end
  if (k == 'j' or k == 'down') and NIL_POS[1] ~= 1
  then
    AXIS = 2
    DIRECTION = 'down'
    HIDDEN_POS = {unpack(NIL_POS)}
    HIDDEN_POS[1] = HIDDEN_POS[1] - 1
  end
  ACTIVE_TILE.start = pixel_pos_from_tile_pos(HIDDEN_POS[1], HIDDEN_POS[2])
  ACTIVE_TILE.finish = pixel_pos_from_tile_pos(NIL_POS[1], NIL_POS[2])
  ACTIVE_TILE.current = {unpack(ACTIVE_TILE.start)}
  ::skip_direction::
  print(DIRECTION)
end

function love.load()
  print(':::start:::')
  math.randomseed(os.time())
  love.window.setMode(#GRID*100, #GRID[1]*100)
  lg.setNewFont(28)
  shuffle_grid(GRID)
  print_grid(GRID)
end

function love.update(dt)
  if DIRECTION ~= 'none'
  then
    local dp = current_speed(
      ACTIVE_TILE.current[AXIS],
      ACTIVE_TILE.start[AXIS],
      ACTIVE_TILE.finish[AXIS],
      0.8
    ) * SPEED
    ACTIVE_TILE.current[AXIS] = ACTIVE_TILE.current[AXIS] + dp * dt
    local boundary_check
    if DIRECTION == 'left' or DIRECTION == 'up'
    then
      boundary_check = ACTIVE_TILE.current[AXIS] < ACTIVE_TILE.finish[AXIS]
    elseif DIRECTION == 'right' or DIRECTION == 'down'
    then
      boundary_check = ACTIVE_TILE.current[AXIS] > ACTIVE_TILE.finish[AXIS]
    end
    if boundary_check
    then
      DIRECTION = 'none'
      GRID[NIL_POS[1]][NIL_POS[2]] = GRID[HIDDEN_POS[1]][HIDDEN_POS[2]]
      GRID[HIDDEN_POS[1]][HIDDEN_POS[2]] = 0
      NIL_POS = {unpack(HIDDEN_POS)}
      HIDDEN_POS = {0, 0}
      ACTIVE_TILE.current[AXIS] = ACTIVE_TILE.finish[AXIS]
    end
    print(ACTIVE_TILE.current[1])
  end
end

local function draw_grid(grid, spacing)
  spacing = spacing or 5
  for row_idx = 1, #grid, 1 do
    for col_idx = 1, #grid[1], 1 do
      local value = grid[row_idx][col_idx]
      if value == 0
      then
        goto continue
      end
      local x, y = 0, 0
      if row_idx == HIDDEN_POS[1] and col_idx == HIDDEN_POS[2]
      then
        x, y = unpack(ACTIVE_TILE.current)
      else
        x, y = unpack(pixel_pos_from_tile_pos(row_idx, col_idx, spacing))
      end
      lg.setColor(love.math.colorFromBytes(0x7d, 0x60, 0xca))
      lg.rectangle('fill', x, y, 100 - spacing * 2, 100 - spacing * 2)
      lg.setColor(1, 1, 1)
      lg.print(value, x+4, y+2)
      ::continue::
    end
  end
end

function love.draw()
  draw_grid(GRID)
end

function love.quit()
  print(':::end:::')
end
