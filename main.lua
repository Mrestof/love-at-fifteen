local Animation = require('animation')

MainFont = nil

GameState = 'grid'

Direction = 'none'
Directions = {'left', 'right', 'up', 'down'}

Speed = 150
ShuffleAmnt = 1000

Grid = {
  {1,  2,  3,  4},
  {5,  6,  7,  8},
  {9,  10, 11, 12},
  {13, 14, 15, 0},
}
NilPos = {0, 0}
HiddenPos = {0, 0}
ActiveTile = {  -- positions are specified in pixels {x, y}
  current = {0, 0},
  start = {0, 0},
  finish = {0, 0},
}

Axis = 0

WinMediaType = 'animation'
if WinMediaType == 'animation' then
  WinAnim = nil
  WinAnimParams = {scale = 1, y_pos = 0, speed = 20}
  WinAudio = nil
elseif WinMediaType == 'video' then
  WinVideo = nil
  WinVideoParams = {scale = 1, y_pos = 0}
end
WinTextParams = {limit = 0, y_pos = 0, color_id = 0, color_step = 0.4}

local lg = love.graphics

-- math for mapping ranges: https://stackoverflow.com/q/5731863
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

local function simple_move(grid, direction)
  --local newNilPos = {unpack(NilPos)}
  if direction == 'left' and NilPos[2] ~= #Grid[1]
  then
    grid[NilPos[1]][NilPos[2]] = grid[NilPos[1]][NilPos[2]+1]
    grid[NilPos[1]][NilPos[2]+1] = 0
    NilPos[2] = NilPos[2] + 1
  end
  if direction == 'right' and NilPos[2] ~= 1
  then
    grid[NilPos[1]][NilPos[2]] = grid[NilPos[1]][NilPos[2]-1]
    grid[NilPos[1]][NilPos[2]-1] = 0
    NilPos[2] = NilPos[2] - 1
  end
  if direction == 'up' and NilPos[1] ~= #Grid
  then
    grid[NilPos[1]][NilPos[2]] = grid[NilPos[1]+1][NilPos[2]]
    grid[NilPos[1]+1][NilPos[2]] = 0
    NilPos[1] = NilPos[1] + 1
  end
  if direction == 'down' and NilPos[1] ~= 1
  then
    grid[NilPos[1]][NilPos[2]] = grid[NilPos[1]-1][NilPos[2]]
    grid[NilPos[1]-1][NilPos[2]] = 0
    NilPos[1] = NilPos[1] - 1
  end
end

local function random_shuffle_grid(grid)
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
  NilPos = locate_nil(grid)
end

local function print_grid(grid)
  for row_idx = 1, #grid, 1 do
    print(table.concat(grid[row_idx], '\t'))
  end
end

local function simulated_shuffle_grid(grid)
  NilPos = locate_nil(grid)
  local direction
  for _ = 1, ShuffleAmnt do
    direction = Directions[math.random(#Directions)]
    simple_move(grid, direction)
    --print(direction)
  end
end

local function pixel_pos_from_tile_pos(row, col, spacing)
  spacing = spacing or 5
  local x = (col - 1) * 100 + spacing
  local y = (row - 1) * 100 + spacing
  return {x, y}
end

local function check_win_status(grid)
  local prev = -1
  for row_idx = 1, #grid do
    for col_idx = 1, #grid[1] do
      local value = grid[row_idx][col_idx]
      --print(value, prev)
      if value > prev or (row_idx == #grid and col_idx == #grid[1]) then
        prev = value
      else
        return false
      end
    end
  end
  return true
end

function love.keypressed(k)
  if k == 'escape' or k == 'q'
  then
    love.event.quit()
  end
  if Direction == 'none'
  then
    -- the section in this if block is a possible bug place
    HiddenPos = {unpack(NilPos)}
    if (k == 'h' or k == 'left') and NilPos[2] ~= #Grid[1]
    then
      Axis = 1
      Direction = 'left'
      HiddenPos[2] = HiddenPos[2] + 1
    end
    if (k == 'l' or k == 'right') and NilPos[2] ~= 1
    then
      Axis = 1
      Direction = 'right'
      HiddenPos[2] = HiddenPos[2] - 1
    end
    if (k == 'k' or k == 'up') and NilPos[1] ~= #Grid
    then
      Axis = 2
      Direction = 'up'
      HiddenPos[1] = HiddenPos[1] + 1
    end
    if (k == 'j' or k == 'down') and NilPos[1] ~= 1
    then
      Axis = 2
      Direction = 'down'
      HiddenPos[1] = HiddenPos[1] - 1
    end
    ActiveTile.start = pixel_pos_from_tile_pos(HiddenPos[1], HiddenPos[2])
    ActiveTile.finish = pixel_pos_from_tile_pos(NilPos[1], NilPos[2])
    ActiveTile.current = {unpack(ActiveTile.start)}
  end
  print(Direction)
end

function love.load()
  print(':::start:::')
  NilPos = locate_nil(Grid)
  math.randomseed(os.time())
  love.window.setMode(#Grid*100, #Grid[1]*100)
  MainFont = lg.setNewFont(28)
  simulated_shuffle_grid(Grid)
  print_grid(Grid)
  if WinMediaType == 'animation' then
    WinAnim = Animation:new(
      {'gfx/up.jpg','gfx/mid.jpg','gfx/low.jpg'},
      WinAnimParams.speed
    )
    WinAudio = love.audio.newSource(
      'gfx/groove-audio-full-low-quality.ogg',
      'stream'
    )
  elseif WinMediaType == 'video' then
    WinVideo = lg.newVideo('gfx/groove-man-loop10.ogv')
  end
end

local function grid_logic(dt)
  if Direction ~= 'none'
  then
    local dp = current_speed(
      ActiveTile.current[Axis],
      ActiveTile.start[Axis],
      ActiveTile.finish[Axis],
      0.8
    ) * Speed
    ActiveTile.current[Axis] = ActiveTile.current[Axis] + dp * dt
    local boundary_check
    if Direction == 'left' or Direction == 'up'
    then
      boundary_check = ActiveTile.current[Axis] < ActiveTile.finish[Axis]
    elseif Direction == 'right' or Direction == 'down'
    then
      boundary_check = ActiveTile.current[Axis] > ActiveTile.finish[Axis]
    end
    if boundary_check
    then
      Direction = 'none'
      Grid[NilPos[1]][NilPos[2]] = Grid[HiddenPos[1]][HiddenPos[2]]
      Grid[HiddenPos[1]][HiddenPos[2]] = 0
      NilPos = {unpack(HiddenPos)}
      HiddenPos = {0, 0}
      ActiveTile.current[Axis] = ActiveTile.finish[Axis]
      if check_win_status(Grid)
      then
        GameState = 'win_screen'
        local win_width, win_height = love.window.getMode()
        local MediaPieceParams
        local media_width, media_height, media_scale
        if WinMediaType == 'animation' then
          media_width, media_height = WinAnim:getDimensions()
          MediaPieceParams = WinAnimParams
          WinAudio:play()
        elseif WinMediaType == 'video' then
          media_width, media_height = WinVideo.getDimensions()
          MediaPieceParams = WinVideoParams
          WinVideo:play()
        end
        print(media_width)
        media_scale = win_width / media_width
        print(media_scale)
        MediaPieceParams.scale = media_scale
        MediaPieceParams.y_pos = win_height - media_height * media_scale
        WinTextParams.limit = win_width
        WinTextParams.y_pos = (
          win_height - (MainFont:getHeight() + (media_height * media_scale))
        ) / 2
      end
    end
    --print(ActiveTile.current[1])
  end
end

local function rainbow_color(x)
  local red = (math.sin(x) / 2) + 0.5
  local green = (math.sin(x + 2*math.pi/3) / 2) + 0.5
  local blue = (math.sin(x + 4*math.pi/3) / 2) + 0.5
  return {red, green, blue}
end

local function win_screen_logic(dt)
  WinAnim:update(dt)
end

function love.update(dt)
  if GameState == 'grid' then
    grid_logic(dt)
  end
  if GameState == 'win_screen' then
    win_screen_logic(dt)
  end
end

local function draw_grid(grid, spacing)
  spacing = spacing or 5
  for row_idx = 1, #grid, 1 do
    for col_idx = 1, #grid[1], 1 do
      local value = grid[row_idx][col_idx]
      if value ~= 0
      then
        local x, y = 0, 0
        if row_idx == HiddenPos[1] and col_idx == HiddenPos[2]
        then
          x, y = unpack(ActiveTile.current)
        else
          x, y = unpack(pixel_pos_from_tile_pos(row_idx, col_idx, spacing))
        end
        -- 7d60ca
        lg.setColor(love.math.colorFromBytes(0x7d, 0x60, 0xca))
        lg.rectangle('fill', x, y, 100 - spacing * 2, 100 - spacing * 2)
        lg.setColor(1, 1, 1)
        lg.print(value, x+4, y+2)
      end
    end
  end
end

local function draw_win_screen()
  lg.setColor(rainbow_color(WinTextParams.color_id))
  WinTextParams.color_id = (
    WinTextParams.color_id + WinTextParams.color_step
  )
  lg.printf(
    'Congratulations,\nyou won!',
    0,
    WinTextParams.y_pos,
    WinTextParams.limit,
    'center'
  )
  lg.setColor(1, 1, 1)
  WinAnim:draw(0, WinAnimParams.y_pos, 0,  WinAnimParams.scale)
  -- lg.draw(
  --   WinVideo,
  --   0,
  --   WinVideoParams.y_pos,
  --   0,
  --   WinVideoParams.scale,
  --   WinVideoParams.scale
  -- )
end

function love.draw()
  if GameState == 'grid'
  then
    draw_grid(Grid)
  end
  if GameState == 'win_screen'
  then
    draw_win_screen()
  end
end

function love.quit()
  print(':::end:::')
end
