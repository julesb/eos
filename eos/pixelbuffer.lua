--[[

TODO
gradients
peak/trough detect
noise
threshold
mask
copy
paste
resample


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
    size = size or 1024,
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


function PixelBuffer:resample(new_size)
  if new_size == self.size then
    return self -- No resampling needed
  end

  -- Create a temporary buffer with the original data
  local original_buffer = {}
  for i = 1, self.size do
    original_buffer[i] = {table.unpack(self.buffer[i])}
  end
  local original_size = self.size

  -- Reset our buffer to the new size
  self.buffer = {}
  for i = 1, new_size do
    self.buffer[i] = {0, 0, 0, 1}
  end
  self.size = new_size

  -- Linear interpolation from original to new size
  local scale = (original_size - 1) / (new_size - 1)

  for i = 1, new_size do
    -- Map the target index to source space
    local src_idx_f = (i - 1) * scale + 1
    local src_idx_low = math.floor(src_idx_f)
    local src_idx_high = math.min(src_idx_low + 1, original_size)
    local weight = src_idx_f - src_idx_low

    -- Get the two neighboring pixels for interpolation
    local color_low = original_buffer[src_idx_low]
    local color_high = original_buffer[src_idx_high]

    -- Linear interpolation between the colors
    self.buffer[i] = {
      color_low[1] * (1 - weight) + color_high[1] * weight,
      color_low[2] * (1 - weight) + color_high[2] * weight,
      color_low[3] * (1 - weight) + color_high[3] * weight,
      color_low[4] * (1 - weight) + color_high[4] * weight
    }
  end

  -- Also need to adjust dwell_map if it has entries
  -- if next(self.dwell_map) then
  --   local new_dwell_map = {}
  --   -- Simple approach: nearest neighbor for dwell map (since it's likely sparse)
  --   for orig_idx, dwell in pairs(self.dwell_map) do
  --     local new_idx = math.floor(1 + (orig_idx - 1) / original_size * new_size)
  --     if new_idx >= 1 and new_idx <= new_size then
  --       new_dwell_map[new_idx] = dwell
  --     end
  --   end
  --   self.dwell_map = new_dwell_map
  -- end

  return self
end

-- function PixelBuffer:resample(new_size)
--   if new_size == self.size then
--     return self:clone() -- No resampling needed
--   end
--
--   local result = PixelBuffer.new(new_size)
--   result.clearColor = {table.unpack(self.clearColor)}
--
--   -- Calculate scaling factor
--   local scale = (self.size - 1) / (new_size - 1)
--
--   for i = 1, new_size do
--     -- Map the target index to source space
--     local src_idx_f = (i - 1) * scale + 1
--     local src_idx_low = math.floor(src_idx_f)
--     local src_idx_high = math.min(src_idx_low + 1, self.size)
--     local weight = src_idx_f - src_idx_low
--
--     -- Get the two neighboring pixels for interpolation
--     local color_low = self.buffer[src_idx_low]
--     local color_high = self.buffer[src_idx_high]
--
--     -- Linear interpolation between the colors
--     local new_color = {
--       color_low[R] * (1 - weight) + color_high[R] * weight,
--       color_low[G] * (1 - weight) + color_high[G] * weight,
--       color_low[B] * (1 - weight) + color_high[B] * weight,
--       color_low[A] * (1 - weight) + color_high[A] * weight
--     }
--
--     result.buffer[i] = new_color
--   end
--
--   return result
-- end

-- position -1..1 -> index 1..bufsize
function PixelBuffer.pos2idx(pos, size)
  return math.floor(1 + (0.5 + 0.5 * pos) * (size-1))
end

function PixelBuffer:clear(color)
  local c = to_internal(color or to_named(self.clearColor))
  for i=1, self.size do
    self.buffer[i] = {c[1], c[2], c[3], c[4]}
  end
  return self
end

function PixelBuffer:set_pixel_idx(index, color)
  if index > 0 and index <= self.size then
    color.a  = color.a or 1
    self.buffer[index] = to_internal(color)
  end
  return self
end

-- pos range -1..1
function PixelBuffer:set_pixel(pos, color)
  local index = math.floor(1 + (0.5 + 0.5 * pos) * (self.size-1))
  if index > 0 and index <= self.size then
    color.a  = color.a or 1
    self.buffer[index] = to_internal(color)
  end
  return self
end

function PixelBuffer:set_pixel_aa(pos, color)
  color.a  = color.a or 1
  color = to_internal(color)
  if pos < -1 or pos > 1 then return self end

  local f_idx = 1 + (0.5 + 0.5 * pos) * (self.size - 1)
  local x_idx = math.floor(f_idx)
  local x_fract = f_idx - x_idx

  -- Calculate weights for adjacent pixels
  -- Linear distribution of intensity to neighboring pixels
  local left_weight = 1.0 - x_fract
  local right_weight = x_fract

  -- Apply color to current pixel and adjacent pixel based on weights
  if x_idx >= 1 and x_idx <= self.size then
    self.buffer[x_idx] = PixelBuffer.alphablend(self.buffer[x_idx], color, left_weight)
  end

  if x_idx + 1 <= self.size then
    self.buffer[x_idx + 1] = PixelBuffer.alphablend(self.buffer[x_idx + 1], color, right_weight)
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

function PixelBuffer:threshold(thresh, mode)
  mode = mode or "below" -- Default mode is "below"

  for i=1, self.size do
    local c = self.buffer[i]
    -- Use perceptual luminance formula (0.299R + 0.587G + 0.114B)
    local intensity = 0.299*c[1] + 0.587*c[2] + 0.114*c[3]

    if (mode == "below" and intensity < thresh) or
       (mode == "above" and intensity >= thresh) then
      -- Zero out RGB but preserve the alpha/dwell
      self.buffer[i] = {0, 0, 0, c[4]}
    end
  end

  return self
end

function PixelBuffer:flatten(threshold)
  threshold = threshold or 0.5
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
      r = p[1],
      g = p[2],
      b = p[3]
    })
  end
  return points
end

function PixelBuffer:as_points_optimized(x, y, w)
  local points = {}
  x = x or -1
  y = y or 0
  w = w or 2
  local step = w / self.size

  -- Handle empty buffer case
  if self.size == 0 then
    return points
  end

  -- Add the first point
  local current_color = self.buffer[1]
  table.insert(points, {
    x = x,
    y = y,
    r = current_color[1],
    g = current_color[2],
    b = current_color[3],
    a = current_color[4] or 1  -- Added alpha support
  })

  -- Track start of current span
  local span_start_idx = 1

  -- Process the rest of the points
  for i = 2, self.size do
    local p = self.buffer[i]

    -- Check if color has changed
    if p[1] ~= current_color[1] or
       p[2] ~= current_color[2] or
       p[3] ~= current_color[3] or
       (p[4] or 1) ~= (current_color[4] or 1) then

      -- Add the last point of the previous span if it wasn't a single point
      if i - 1 > span_start_idx then
        table.insert(points, {
          x = x + (i-2) * step,
          y = y,
          r = current_color[1],
          g = current_color[2],
          b = current_color[3],
          a = current_color[4] or 1
        })
      end

      -- Start a new span with the current color
      current_color = p
      span_start_idx = i

      -- Add the first point of the new span
      table.insert(points, {
        x = x + (i-1) * step,
        y = y,
        r = p[1],
        g = p[2],
        b = p[3],
        a = p[4] or 1
      })
    end
  end

  -- Add the last point if the last span has more than one point
  if span_start_idx < self.size then
    local last_p = self.buffer[self.size]
    table.insert(points, {
      x = x + (self.size-1) * step,
      y = y,
      r = last_p[1],
      g = last_p[2],
      b = last_p[3],
      a = last_p[4] or 1
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
      math.min(1, c1[1] + c2[1] * c2[4]),
      math.min(1, c1[2] + c2[2] * c2[4]),
      math.min(1, c1[3] + c2[3] * c2[4]),
      c1[4]
    }
  end,
  multiply = function(c1, c2)
    return {
      c1[1] * (c2[1] * c2[4] + (1 - c2[4])),
      c1[2] * (c2[2] * c2[4] + (1 - c2[4])),
      c1[3] * (c2[3] * c2[4] + (1 - c2[4])),
      c1[4]
    }
  end,
  replace = function(_, c2)
    return {
      c2[1],
      c2[2],
      c2[3],
      c2[4]
    }
  end,
  screen = function(c1, c2)
    return {
      1 - (1 - c1[1]) * (1 - c2[1] * c2[4]),
      1 - (1 - c1[2]) * (1 - c2[2] * c2[4]),
      1 - (1 - c1[3]) * (1 - c2[3] * c2[4]),
      c1[4]
    }
  end,
  over = function(c1, c2)
    return {
      c2[1] * c2[4] + c1[1] * (1 - c2[4]),
      c2[2] * c2[4] + c1[2] * (1 - c2[4]),
      c2[3] * c2[4] + c1[3] * (1 - c2[4]),
      c2[4] + c1[4] * (1 - c2[4])
    }
  end,
  max = function(c1, c2)
    return {
      math.max(c1[1], c2[1] * c2[4]),
      math.max(c1[2], c2[2] * c2[4]),
      math.max(c1[3], c2[3] * c2[4]),
      math.max(c1[4], c2[4])
    }
  end,
  min = function(c1, c2)
    return {
      math.min(c1[1], c2[1] * c2[4]),
      math.min(c1[2], c2[2] * c2[4]),
      math.min(c1[3], c2[3] * c2[4]),
      math.min(c1[4], c2[4])
    }
  end
}

function PixelBuffer.alphablend(base_color, new_color, weight)
  -- Assuming colors are tables with r, g, b, a components (0-1 range)
  -- Weight determines how much of new_color to apply (0-1)

  -- Apply weight to the new color's alpha
  local blend_alpha = new_color[A] * weight

  -- If new color is fully transparent after weighting, just return base
  if blend_alpha <= 0 then return base_color end

  -- Calculate resulting alpha using "over" compositing
  local result_alpha = blend_alpha + base_color[4] * (1 - blend_alpha)

  -- Early return if result is fully transparent
  if result_alpha <= 0 then
    return {0, 0, 0, 0}
  end

  -- Calculate each color component with alpha premultiplication
  local result = {}
  result[1] = (new_color[1] * blend_alpha + base_color[1] * base_color[4] * (1 - blend_alpha)) / result_alpha
  result[2] = (new_color[2] * blend_alpha + base_color[2] * base_color[4] * (1 - blend_alpha)) / result_alpha
  result[3] = (new_color[3] * blend_alpha + base_color[3] * base_color[4] * (1 - blend_alpha)) / result_alpha
  result[4] = result_alpha

  return result -- {result.r, result.g, result.b, result.a}
end


function PixelBuffer:to_ansi_grayscale()
  local result = ""
  local width = math.min(self.size, 120)  -- Adjust for your desired width

  for i=1, self.size do
    local p = self.buffer[i]
    local intensity = p[R]

    -- Convert intensity (0-1) to grayscale (0-255)
    local gray = math.floor(intensity * 255)

    -- ANSI escape code for setting background color
    result = result .. string.format("\27[48;2;%d;%d;%dm  \27[0m", gray, gray, gray)

    if i % width == 0 then
      result = result .. "|"
    end
  end

  return result
end

function PixelBuffer:to_ansi_rgb()
  local result = ""
  local width = math.min(self.size, 120)  -- Adjust for your desired width

  for i=1, self.size do
    local p = self.buffer[i]

    -- Convert intensity (0-1) to RGB (0-255)
    local r = math.floor(p[R] * 255)
    local g = math.floor(p[G] * 255)
    local b = math.floor(p[B] * 255)

    -- ANSI escape code for setting background color (RGB)
    result = result .. string.format("\27[48;2;%d;%d;%dm  \27[0m", r, g, b)

    if i % width == 0 then
      result = result .. "|"
    end
  end

  return result
end

-- Quantize a continuous position -1..1 to the corresponding
-- pixel position
function PixelBuffer.quantize_position(x, bufsize)
  x = math.max(-1, math.min(1, x))
  local pwidth = 2 / bufsize
  local index = 1 + ((x + 1) / 2) * (bufsize - 1)
  local nearest_index = math.floor(index + 0.5)
  local quantized_x = -1 + (2 * (nearest_index - 1) / (bufsize - 1))
  return quantized_x + pwidth / 2
end

-- function PixelBuffer:resolve_function(fname)
--   if self[fname] then
--     return self[fname]
--   else
--     local plugins = require("pixelplugins")
--     -- iterate through plugins to find fname
--     -- ...
--   end
-- end

return PixelBuffer
