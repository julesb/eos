
local pb = require("pixelbuffer")
local plugins = require("pixelplugins")
local simplex = require("simplex")
local buffer = pb.new (16)
local buf2 = pb.new (16)

local function noisefunc(freq, time)
  return function (x, i, c)
    local sr = 12.34521
    local sg = 371.15164
    local sb = 93.36358

    local nr = 0.5 + 0.5 * simplex.noise2d(time*freq+i, sr)
    local ng = 0.5 + 0.5 * simplex.noise2d(time*freq+i, sg)
    local nb = 0.5 + 0.5 * simplex.noise2d(time*freq+i, sb)

    local r = math.min(1, c.r + nr)
    local g = math.min(1, c.g + ng)
    local b = math.min(1, c.b + nb)

    return r, g, b, 1
  end
end

local function edge_test()

  local wave = pb.new(16)
  local color2 = {r=0, g=0, b=1, a=1}
  wave:apply_effect(plugins.gen.square(color2, 1, 0.5, 0))
  local edges = wave:clone()
  edges
    :apply_effect(plugins.conv.edge())
    -- :flatten(0.1)
  --
  -- wave:blend("add")(edges)
  print(edges:to_string())
end




local function resample_test()
  local size = 16
  local buf = pb.new(size)
  buf
    -- :set_pixel_idx(1,                    {r=1, g=1, b=1})
    -- :set_pixel_idx(math.floor(size/4),   {r=1, g=1, b=1})
    -- :set_pixel_idx(0,                    {r=1, g=1, b=1})
    -- :set_pixel_idx(math.floor(size*3/4), {r=1, g=1, b=1})
    -- :set_pixel_idx(math.floor(size),     {r=1, g=1, b=1})

    -- :set_pixel(-1.0, {r=1, g=1, b=1})
    -- :set_pixel(-0.5, {r=1, g=1, b=1})
    -- :set_pixel( 0.0, {r=1, g=1, b=1})
    -- :set_pixel( 0.5, {r=1, g=1, b=1})
    -- :set_pixel( 1.0, {r=1, g=1, b=1})

    :set_pixel_aa(-1.0, {r=1, g=1, b=1})
    :set_pixel_aa(-0.5, {r=1, g=1, b=1})
    :set_pixel_aa( 0.0, {r=1, g=1, b=1})
    :set_pixel_aa( 0.5, {r=1, g=1, b=1})
    :set_pixel_aa( 1.0, {r=1, g=1, b=1})

    -- :resample(16)

  print(buf:to_string())

end

local function sine_pixel_test(size1, size2, t)
  local skyblue = {r=0.1, g=0.5, b=0.9}
  local black   = {r=0.0, g=0.0, b=0.0}
  local orange  = {r=1.0, g=0.4, b=0.0}
  local plum  =   {r=0.9, g=0.2, b=0.1}
  -- local size =16
  local tau = math.pi*2
  local buf = pb.new(size1)
  buf
    :clear(black)
    :set_pixel(math.sin(t), orange)
    :set_pixel(math.sin(t+tau*0.333), plum)
    :set_pixel(math.sin(t+tau*0.666), skyblue)
    -- :set_pixel_aa(math.sin(t), orange)
    -- :set_pixel_aa(math.sin(t+tau*0.333), plum)
    -- :set_pixel_aa(math.sin(t+tau*0.666), skyblue)
    :apply_effect(plugins.conv.blur(3, 2))
    -- :resample(size2)
  return buf
end

-- edge_test()

local t = 0
-- while true do
for i=1,50 do
  print(sine_pixel_test(32, 32, t):to_ansi_rgb())
  -- print(sine_pixel_test(t):to_string())
  os.execute("sleep 0.05")
  t = t + 0.05
end

-- buf2:set_pixel(12, {r=0, g=0, b=1})
--
-- buffer
--   :set_pixel(4, {r=1, g=0, b=0})
--   :set_pixel(8, {r=0, g=1, b=0})
--   :blend("add")(buf2)
--   -- :map(noisefunc(3, 1.23))
--
-- print(buffer:to_string())
