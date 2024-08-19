XS = 10
X = XS
XF = 500
SPEED = 85

INPUT_LOCK = false
DIRECTION = 'none'

GRID = {
  {1,  2,  3,  4},
  {5,  6,  7,  8},
  {9,  10, 11, 12},
  {13, 14, 15, 0},
}
NIL_POS = {4, 4}
HIDDEN_POS = {0, 0}
ACTIVE_TILE = {
  current = {0, 0},
  start = {0, 0},
  finish = {0, 0},
}

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
  spacing = spacing or 10
  local x = (col - 1) * 100 + spacing
  local y = (row - 1) * 100 + spacing
  return {x, y}
end

function love.keypressed(k)
  if k == 'escape' or k == 'q'
  then
    love.event.quit()
  end
  if INPUT_LOCK
  then
    goto skip_direction
  end
  if (k == 'h' or k == 'left') and NIL_POS[2] ~= #GRID[1]
  then
    DIRECTION = 'left'
    INPUT_LOCK = true
    HIDDEN_POS = {unpack(NIL_POS)}
    HIDDEN_POS[2] = HIDDEN_POS[2] + 1
    ACTIVE_TILE.start = pixel_pos_from_tile_pos(HIDDEN_POS[1], HIDDEN_POS[2])
    ACTIVE_TILE.finish = pixel_pos_from_tile_pos(NIL_POS[1], NIL_POS[2])
    ACTIVE_TILE.current = {unpack(ACTIVE_TILE.start)}
    print(table.concat(ACTIVE_TILE.start, ','))
    print(table.concat(ACTIVE_TILE.finish, ','))
    print(table.concat(ACTIVE_TILE.current, ','))
  end
  if (k == 'l' or k == 'right') and NIL_POS[2] ~= 1
  then
    DIRECTION = 'right'
    INPUT_LOCK = true
    HIDDEN_POS = NIL_POS
    HIDDEN_POS[2] = HIDDEN_POS[2] - 1
  end
  if (k == 'k' or k == 'up') and NIL_POS[1] ~= #GRID
  then
    DIRECTION = 'up'
    INPUT_LOCK = true
    HIDDEN_POS = NIL_POS
    HIDDEN_POS[1] = HIDDEN_POS[1] + 1
  end
  if (k == 'j' or k == 'down') and NIL_POS[1] ~= 1
  then
    DIRECTION = 'down'
    INPUT_LOCK = true
    HIDDEN_POS = NIL_POS
    HIDDEN_POS[1] = HIDDEN_POS[1] - 1
  end
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
  print('nil pos:', table.concat(NIL_POS, ','))
end

function love.update(dt)
  --love.timer.sleep(0.08)
  --if DIRECTION == 'right'
  --then
  --  local dx = current_speed(X, XS, XF, 0.8) * SPEED
  --  X = X + dx * dt
  --  if X >= XF
  --  then
  --    DIRECTION = 'none'
  --    X = XF
  --  end
  --end
  --if DIRECTION == 'left'
  --then
  --  local dx = current_speed(X, XS, XF, 0.8) * SPEED
  --  X = X - dx * dt
  --  if X <= XS
  --  then
  --    DIRECTION = 'none'
  --    X = XS
  --  end
  --end
end

local function draw_grid(grid, spacing)
  spacing = spacing or 10
  for row_idx = 1, #grid, 1 do
    for col_idx = 1, #grid[1], 1 do
      local value = grid[row_idx][col_idx]
      if
        value == 0
        or row_idx == HIDDEN_POS[1] and col_idx == HIDDEN_POS[2]
      then
        goto continue
      end
      lg.setColor(love.math.colorFromBytes(0x7d, 0x60, 0xca))
      local x, y = unpack(pixel_pos_from_tile_pos(row_idx, col_idx, spacing))
      lg.rectangle('fill', x, y, 100 - spacing * 2, 100 - spacing * 2)
      lg.setColor(1, 1, 1)
      lg.print(value, x+4, y+2)
      ::continue::
    end
  end
end

function love.draw()
  draw_grid(GRID, 5)
end

function love.quit()
  print(':::end:::')
end
