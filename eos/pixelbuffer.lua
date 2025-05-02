


--[[

TODO
gradients
peak/trough detect
noise
threshold
mask
copy
poste

Blend Modes
difference
screen
lighten (max)
darken (min)
...


--]]

local PixelBuffer = {}
PixelBuffer.__index = PixelBuffer

-- Channel indices
local R, G, B, A = 1, 2, 3, 4

-- Helper to convert user-friendly named color to internal format
local function to_internal(c)
  return {
    c.r or 0,
    c.g or 0,
    c.b or 0,
    c.a or 1
  }
end

-- Helper to convert internal format to named format (used only for to_string and as_points)
local function to_named(c)
  return {
    r = c[R],
    g = c[G],
    b = c[B],
    a = c[A]
  }
end

function PixelBuffer.new(size)
  local buf = {
    size = size or 4096,
    buffer = {},
    dwell_map = {},
    clearColor = {0, 0, 0, 1} -- Default "off" color in flat format
  }
  for i=1,buf.size do
    buf.buffer[i] = {0, 0, 0, 1}
  end
  return setmetatable(buf, PixelBuffer)
end

function PixelBuffer:clone()
  local copy = {
    size = self.size,
    buffer = {},
    dwell_map = {},
    clearColor = {table.unpack(self.clearColor)}
  }

  for i = 1, self.size do
    local c = self.buffer[i]
    copy.buffer[i] = {c[1], c[2], c[3], c[4]}
    local d = self.dwell_map[i]
    if d then copy.dwell_map[i] = d end
  end

  return setmetatable(copy, PixelBuffer)
end

function PixelBuffer:clear(color)
  local c = to_internal(color or to_named(self.clearColor))
  for i=1, self.size do
    self.buffer[i] = {c[R], c[G], c[B], c[A]}
  end
  return self
end

function PixelBuffer:set_pixel(index, color)
  if index > 0 and index <= self.size then
    self.buffer[index] = to_internal(color)
  end
  return self
end

function PixelBuffer:blend(mode)
  local previousBuffer = self.buffer
  local blendfn = self.blend_modes[mode or "add"]
  return function(otherBuffer)
    for i=1,self.size do
      local c1 = previousBuffer[i]
      local c2 = otherBuffer.buffer[i]
      self.buffer[i] = blendfn(c1, c2)
    end
    return self
  end
end

function PixelBuffer:map(fn)
  for i=1, self.size do
    local x = (i-1)/(self.size-1)
    local r, g, b, a = fn(x, i, to_named(self.buffer[i]))
    self.buffer[i] = {r or 0, g or 0, b or 0, a or 1}
  end
  return self
end

function PixelBuffer:convolve(kernel)
  local size = #kernel
  local half = math.floor(size / 2)
  local new_buffer = {}

  for i = 1, self.size do
    local r, g, b, a = 0, 0, 0, 0
    for k = 1, size do
      local offset = k - half - 1
      local j = i + offset

      if j >= 1 and j <= self.size then
        local c = self.buffer[j]
        local weight = kernel[k]
        r = r + c[1] * weight
        g = g + c[2] * weight
        b = b + c[3] * weight
        a = a + c[4] * weight
      end
    end
    new_buffer[i] = {r, g, b, a}
  end

  self.buffer = new_buffer
  return self
end

function PixelBuffer:apply_effect(effect)
  if not effect or not effect.type or not effect.fn then
    error("Invalid effect: missing type or fn")
  end

  if effect.type == "map" then
    return self:map(effect.fn)
  elseif effect.type == "convolve" then
    return effect.fn(self)
  else
    error("Unsupported effect type: " .. tostring(effect.type))
  end
end

function PixelBuffer:flatten(threshold)
  threshold = threshold or 0
  for i = 1, self.size do
    local c = self.buffer[i]
    local mag = c[1]^2 + c[2]^2 + c[3]^2
    if mag > threshold^2 then
      self.buffer[i] = {1, 1, 1, c[4]}
    else
      self.buffer[i] = {0, 0, 0, c[4]}
    end
  end
  return self
end


function PixelBuffer:as_points(x, y, w)
  local points = {}
  x = x or -1
  y = y or 0
  w = w or 2
  local step = w / self.size
  for i = 1, self.size do
    local p = self.buffer[i]
    table.insert(points, {
      x = x + (i-1) * step,
      y = y,
      r = p[R],
      g = p[G],
      b = p[B]
    })
  end
  return points
end

function PixelBuffer:to_string()
  local result = "PixelBuffer(size=" .. self.size .. ")\n"
  local maxToShow = math.min(16, self.size)
  result = result .. "First " .. maxToShow .. " pixels:\n"
  for i=1, maxToShow do
    local p = self.buffer[i]
    result = result .. string.format("[%d]\trgba(%.2f, %.2f, %.2f, %.2f)\n",
      i, p[R], p[G], p[B], p[A])
  end
  return result
end

PixelBuffer.blend_modes = {
  add = function(c1, c2)
    return {
      math.min(1, c1[R] + c2[R] * c2[A]),
      math.min(1, c1[G] + c2[G] * c2[A]),
      math.min(1, c1[B] + c2[B] * c2[A]),
      c1[A]
    }
  end,
  multiply = function(c1, c2)
    return {
      c1[R] * (c2[R] * c2[A] + (1 - c2[A])),
      c1[G] * (c2[G] * c2[A] + (1 - c2[A])),
      c1[B] * (c2[B] * c2[A] + (1 - c2[A])),
      c1[A]
    }
  end,
  replace = function(_, c2)
    return {
      c2[R],
      c2[G],
      c2[B],
      c2[A]
    }
  end,
  screen = function(c1, c2)
    return {
      1 - (1 - c1[R]) * (1 - c2[R] * c2[A]),
      1 - (1 - c1[G]) * (1 - c2[G] * c2[A]),
      1 - (1 - c1[B]) * (1 - c2[B] * c2[A]),
      c1[A]
    }
  end,
  over = function(c1, c2)
    return {
      c2[R] * c2[A] + c1[R] * (1 - c2[A]),
      c2[G] * c2[A] + c1[G] * (1 - c2[A]),
      c2[B] * c2[A] + c1[B] * (1 - c2[A]),
      c2[A] + c1[A] * (1 - c2[A])
    }
  end,
  max = function(c1, c2)
    return {
      math.max(c1[R], c2[R] * c2[A]),
      math.max(c1[G], c2[G] * c2[A]),
      math.max(c1[B], c2[B] * c2[A]),
      math.max(c1[A], c2[A])
    }
  end,
  min = function(c1, c2)
    return {
      math.min(c1[R], c2[R] * c2[A]),
      math.min(c1[G], c2[G] * c2[A]),
      math.min(c1[B], c2[B] * c2[A]),
      math.min(c1[A], c2[A])
    }
  end
}

return PixelBuffer
