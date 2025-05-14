-- test.lua
---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global


function init()
  print("init")
end



function animate(time)
  local eos = require("eos")
  local pb = require("pixelbuffer")
  local plugins = require("pixelplugins")
  -- local screenunit = 2 / 1024
  local simplex = require("simplex")
  local color1 = {r=0.25, g=1.0, b=.5, a=1}
  local bbcolor = C.GREEN
  local sqrcolor = C.RED
  local sincolor = C.BLUE
  local numpoints = 10
  local vscale = 0.1
  local diverge = 0.2
  local seed = 123.456
  local rate = 0.53


  local function exp(x, e)
    return x ^ e
  end

  local function bias(x, biasValue)
      return x ^ (math.log(biasValue) / math.log(0.5))
  end

  local function gain(x, gainValue)
      if x < 0.5 then
          return bias(2 * x, 1 - gainValue) / 2
      else
          return 1 - bias(2 - 2 * x, 1 - gainValue) / 2
      end
  end

  local function thresholdExponential(simplexNoise, threshold, power)
      if simplexNoise > threshold then
          return ((simplexNoise - threshold) / (1 - threshold)) ^ power
      else
          return 0
      end
  end

  -- map pos -1..1 to the x position of the nearest pixel
  local function quantize_position(x, bufsize)
    x = math.max(-1, math.min(1, x))
    local pwidth = 2 / bufsize
    local index = 1 + ((x + 1) / 2) * (bufsize - 1)
    local nearest_index = math.floor(index + 0.5)
    local quantized_x = -1 + (2 * (nearest_index - 1) / (bufsize - 1))
    return quantized_x - pwidth / 2 -- should be "+"? (fudge factor)
  end

  local bufsize = 512
  local out_buf = pb.new(bufsize)
  local points = {}

  for i=1, numpoints do
    local t = (i-1) / (numpoints-1)
    local x = t * 2 - 1
    local n = 0.5 + 0.5 * simplex.noise3d(i*diverge, seed, time * rate)

    n = thresholdExponential(n, 0.06, 1)
    -- n = thresholdExponential(n, 0.00125, 2.5)
    -- n = gain(n, 0.85)
    -- n = bias(n, 0.01)
    -- n = 1 - exp(n, 0.5)

    local y = n * vscale

    local p = eos.newpoint2(x, y, bbcolor)

    local br = math.max(0.1, 1 - (0.2 + n * 0.8)) -- brightness

    -- dwell points
    local qx = quantize_position(p.x, bufsize)
    local col = {r=bbcolor.r*br, g=bbcolor.g*br, b=bbcolor.b*br, a=1}
    for _ = 1, 2 do
      table.insert(points, eos.newpoint2(qx, 0, col))
    end

    local buf = pb.new(bufsize)

    buf
      :clear()
      :set_pixel(p.x, {r=p.r, g=p.g, b=p.b, a=1})
      :apply_effect(plugins.conv.blur(n*40, 5))
      -- :set_pixel(p.x, {r=p.r*br, g=p.g*br, b=p.b*br, a=1})

    out_buf:blend("add")(buf)

  end

  local sqrwave = pb.new(bufsize)
    :apply_effect(plugins.gen.square(sqrcolor, 60, 0.2,
                                     math.sin(time*1.1)* 20 ))
  local sinwave = pb.new(bufsize)
    :apply_effect(plugins.gen.sine(sincolor, 1, 1, math.sin(time*0.04)* 50 ))

  out_buf
    :blend("add")(sqrwave)
    :blend("screen")(sinwave)
  -- local b = 0.5 + 0.5 * simplex.noise3d(time+0.3, 12.34, 45.56)

  -- local outpoints = {}
  local outpoints = out_buf:as_points()
  -- local outpoints = out_buf:as_points_optimized()
  for i=1,#points do
    table.insert(outpoints, points[i])
  end
  --
  table.sort(outpoints, function(a, b)
    return a.x < b.x
  end)

  laser.send(eos.points_to_xyrgb(outpoints))
end

function cleanup()
  print("cleanup")
end
