local Animation = {}
Animation.__index = Animation


function Animation:new(imageFileNameList, speed)
  local imageList = {}
  for _, imageFileName in ipairs(imageFileNameList) do
    table.insert(imageList, love.graphics.newImage(imageFileName))
  end
  local anim = {
    frames = imageList,
    speed = 1 / (speed or 1),
    timer = 0,
    position = 1,
    direction = 1,
  }
  return setmetatable(anim, Animation)
end

function Animation:update(dt)
  self.timer = self.timer + dt
  if self.timer > self.speed then
    self.timer = 0
    if self.position >= #self.frames then
      self.direction = -1
    elseif self.position <= 1 then
      self.direction = 1
    end
    self.position = self.position + self.direction
  end
end

function Animation:current_frame()
  return self.frames[self.position]
end

function Animation:getDimensions()
  return self.frames[1]:getDimensions()
end

function Animation:draw(x, y, r, sx, sy)
  sy = sy or sx
  love.graphics.draw(self:current_frame(), x, y, r, sx, sy)
end


return Animation
