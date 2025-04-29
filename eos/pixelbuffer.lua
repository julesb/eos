local PixelBuffer = {}
PixelBuffer.__index = PixelBuffer

-- Supported blend modes
PixelBuffer.blend_modes = {
  add = true
}

function PixelBuffer.new(size)
  local buf = {
    size = size or 4096,
    buffer = {},
    clearColor = {r=0, g=0, b=0, a=1} -- Default "off" color
  }

  -- Initialize the buffer
  for i=1,buf.size do
    buf.buffer[i] = {r=0, g=0, b=0, a=0} -- RGBA format
  end

  return setmetatable(buf, PixelBuffer)
end

function PixelBuffer:clear(color)
  local c = color or self.clearColor
  for i=1, self.size do
    self.buffer[i] = {r=c.r, g=c.g, b=c.b, a=c.a}
  end
  return self
end

function PixelBuffer:set_pixel(index, color)
  if index > 0 and index <= self.size then
    local c = {
      r = color.r or 0,
      g = color.g or 0,
      b = color.b or 0,
      a = color.a or 1
    }
    self.buffer[index] = c
  end
  return self
end


function PixelBuffer:blend(mode)
  local previousBuffer = self.buffer
  mode = mode or "add" -- default mode

  if not PixelBuffer.blend_modes[mode] then
    print("blend(): unknown mode, using 'add'")
    mode = "add"
  end

  return function(otherBuffer)
    for i=1,self.size do
      local c1 = previousBuffer[i]
      local c2 = otherBuffer.buffer[i]

      if mode == "add" then
        self.buffer[i] = {
          r = math.min(1, c1.r + c2.r),
          g = math.min(1, c1.g + c2.g),
          b = math.min(1, c1.b + c2.b),
          a = math.min(1, c1.a + c2.a)
        }
      -- elseif mode == ... TODO
      end
    end
    return self
  end
end

function PixelBuffer:map(fn)
  for i=1, self.size do
    -- Position normalized to 0-1 range
    local x = (i-1)/(self.size-1)
    -- Call with position, index, and current color
    local r, g, b, a = fn(x, i, self.buffer[i])
    self.buffer[i] = {r=r or 0, g=g or 0, b=b or 0, a=a or 1}
  end
  return self
end

-- Get the buffer as an array of points translated
-- and scaled to the provided screen space (0..1)
-- position and width.
function PixelBuffer:as_points(x, y, w)
  local points = {}
  x = x or -1 -- screen space pos
  y = y or 0  -- screen space pos
  w = w or 2  -- screen space width
  local step = w / self.size
  local sx, sy
  for i = 1, self.size do
    sx = x + (i-1) * step
    sy = y
    table.insert(points, {
      x = sx,
      y = sy,
      r = self.buffer[i].r,
      g = self.buffer[i].g,
      b = self.buffer[i].b
    })
  end

  -- add a single blank at the final position
  table.insert(points, {x=sx, y=sy, r=0, g=0, b=0})
  return points
end


function PixelBuffer:to_string()
  local result = "PixelBuffer(size=" .. self.size .. ")\n"
  local maxToShow = math.min(16, self.size)
  result = result .. "First " .. maxToShow .. " pixels:\n"

  for i=1, maxToShow do
    local p = self.buffer[i]
    result = result .. string.format("[%d]\trgba(%.2f, %.2f, %.2f, %.2f)\n",
      i, p.r, p.g, p.b, p.a)
  end

  return result
end


return PixelBuffer
