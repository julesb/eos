local conv = {}

-- Gaussian kernel generator
local function gaussian_kernel(radius, sigma)
  local size = radius * 2 + 1
  local kernel = {}
  local sum = 0

  for i = 1, size do
    local x = i - radius - 1
    local w = math.exp(- (x * x) / (2 * sigma * sigma))
    kernel[i] = w
    sum = sum + w
  end

  -- Normalize
  for i = 1, size do
    kernel[i] = kernel[i] / sum
  end

  return kernel
end

conv.blur = function(radius, sigma)
  radius = radius or 3
  sigma = sigma or radius / 2
  local kernel = gaussian_kernel(radius, sigma)
  return {
    type = "convolve",
    fn = function(pb)
      return pb:convolve(kernel)
    end
  }
end

conv.edge = function()
  local kernel = {-1, 0, 1}
  return {
    type = "convolve",
    fn = function(pb)
      local clone = pb:clone()
      local function abs_color(c)
        local a
        if c[1] ~= 0 or c[2] ~= 0 or c[3] ~= 0 then a = 1 else a = 0 end
        -- if (c.r or 0) > 0 or (c.g or 0) > 0 or (c.b or 0) > 0 then a = 1 else a = 0 end
        return { math.abs(c[1]), math.abs(c[2]), math.abs(c[3]), a }
        -- return { math.abs(c[1]), math.abs(c[2]), math.abs(c[3]), c[4] }
      end
      clone:convolve(kernel)
      for i=1, clone.size do
        clone.buffer[i] = abs_color(clone.buffer[i])
      end
      pb.buffer = clone.buffer
      return pb
    end
  }
end

-- Simple edge detection using [-1, 0, 1]
conv.rising_edge = function()
  local kernel = {-1, 0, 1}
  return {
    type = "convolve",
    fn = function(pb)
      return pb:convolve(kernel)
    end
  }
end

return conv
