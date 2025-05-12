-- test.lua


function init()
  print("init")
end



function animate(time)
  local eos = require("eos")
  local pb = require("pixelbuffer")
  local plugins = require("pixelplugins")
  local screenunit = 2 / 1024
  local simplex = require("simplex")
  local color2 = {r=1, g=0, b=1}
  local numpoints = 16
  local vscale = 0.1
  local diverge = 1.1
  local seed = 123.456
  local rate = 0.666


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

  local bufsize = 1024
  local out_buf = pb.new(bufsize)
  local points = {}

  for i=1, numpoints do
    local t = (i-1) / (numpoints-1)
    local x = t * 2 - 1
    local n = 0.5 + 0.5 * simplex.noise3d(i*diverge, seed, time * rate)

    -- n = thresholdExponential(n, 0.7, 1.5)
    -- n = gain(n, 0.5)
    n = bias(n, 0.001)
    -- n = 1 - exp(n, 0.3)

    local y = n * vscale

    local p = eos.newpoint2(x, y, color2)

    table.insert(points, p)
    table.insert(points, p)

    local buf = pb.new(bufsize)
    buf
      :clear({r=0.01, g=0.01, b=0.01})
      :set_pixel(p.x, {r=p.r, g=p.g, b=p.b})
      -- :set_pixel(p.x-screenunit, {r=p.r, g=p.g, b=p.b})
      -- :set_pixel(p.x+screenunit, {r=p.r, g=p.g, b=p.b})
      :apply_effect(plugins.conv.blur(n*40, 120))
      :set_pixel(p.x, {r=p.r, g=p.g, b=p.b})
      -- :apply_effect(plugins.conv.blur(n*40, 120))
      -- :set_pixel(p.x, {r=p.r, g=p.g, b=p.b})
      -- :apply_effect(plugins.conv.blur(n*40, 120))
      -- :set_pixel(p.x, {r=p.r, g=p.g, b=p.b})

    out_buf:blend("add")(buf)

  end

  -- local b = 0.5 + 0.5 * simplex.noise3d(time+0.3, 12.34, 45.56)

  -- local outpoints = {}
  local outpoints = out_buf:as_points_optimized()
  -- for i=1,#points do
  --   table.insert(outpoints, points[i])
  -- end
  --
  -- table.sort(outpoints, function(a, b)
  --   return a.x < b.x
  -- end)

  laser.send(eos.points_to_xyrgb(outpoints))
end

function cleanup()
  print("cleanup")
  -- laser.send({0, 0, 0, 0, 0}) -- blank at 0,0
end
