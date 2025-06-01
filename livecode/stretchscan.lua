---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global

local eos = require("eos")
local pb = require("pixelbuffer")
local plugins = require("pixelplugins")

local numpoints = 192
local noise_amp = 0.1
local noise_divergence = 0.83

local gradcolor1 = {r=1, g=0, b=0}
local gradcolor2 = {r=0, g=0, b=1}
local colormode = 2 -- 0 = HSV, 1 = gradient

local timestep = 0.3
local bufsize = 1024
local noisebuf = pb.new(bufsize)
local stretchbuf = pb.new(bufsize)

function init()
  return true
end


local function seamless_noise(ang, rad, t)
  local simplex = require("simplex")
  local x = rad * math.cos(ang * math.pi*2)
  local y = rad * math.sin(ang * math.pi*2)
  return simplex.noise3d(x, y, t)
end


function get_points(time)
  local cs = require("colorspace")
  local drift = time * 0.025

  noisebuf:apply_effect(plugins.gen.rgbnoise(0.01, time*timestep*1))
  stretchbuf:clear({r=0, g=0, b=0, a=0})

  for i = 1,numpoints do
    local t = (i-1) / (numpoints-1) -- t goes from 0 to 1

    local x = t * 2 - 1 -- x goes from -1 to 1
    local nx = x + noise_amp * seamless_noise(t, noise_divergence, time*timestep)
    nx = eos.wrap_neg1_to_1(nx)

    local c
    t = (t + drift) % 1.0 -- slow drift, wrapped

    if colormode == 0 then
      c = eos.hsv2rgb(t, 1, 1)
      -- c.a = 0
    else
      t = 1 - math.abs(2 * t - 1) -- triangle / seamless
      c = cs.hcl_gradient(gradcolor1, gradcolor2, t)
      -- c.a = 0
    end

    stretchbuf:set_pixel(nx, c)
  end

  -- noisebuf:blend("replace")(stretchbuf)
  noisebuf:blend("normal")(stretchbuf)
  -- noisebuf:blend("screen")(stretchbuf)
  -- noisebuf:blend("add")(stretchbuf)
  -- noisebuf:blend("max")(stretchbuf)
  -- noisebuf:blend("min")(stretchbuf)
  -- noisebuf:blend("subtract")(stretchbuf)
  -- noisebuf:blend("difference")(stretchbuf)
  -- points = noisebuf:as_points_optimized()

  return eos.points_to_xyrgb(noisebuf:as_points_optimized())
end


function animate(time)
  laser.send(get_points(time))
end


