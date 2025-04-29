
local pb = require("pixelbuffer")
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

buf2:set_pixel(12, {r=0, g=0, b=1})

buffer
:set_pixel(4, {r=1, g=0, b=0})
:set_pixel(8, {r=0, g=1, b=0})
:blend()(buf2)
:map(noisefunc(3, 1.23))

print(buffer:to_string())
