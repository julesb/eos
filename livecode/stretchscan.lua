---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global


local eos = require("eos")
local pb = require("pixelbuffer")
local plugins = require("pixelplugins")

local numpoints = 192
local noise_amp = 0.1
local noise_divergence = 0.83
local dwellnum = 2
local cellwidth = 0.0

local gradcolor1 = {r=1, g=0, b=0}
local gradcolor2 = {r=0, g=0, b=1}
local colormode = 0 -- 0 = HSV, 1 = gradient

local timestep = 0.3
local bufsize = 256
local noisebuf = pb.new(bufsize)

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
  local v2 = require("vec2")
  local cs = require("colorspace")
  local out = {}
  local cellrad = (2.0 / numpoints) * cellwidth / 2.0
  local edgeoffset = { x = cellrad, y = 0, r = 0, g = 0, b = 0 }
  local drift = time * 0.05

  local stretchpoints = {}
  local points = {}

  noisebuf:apply_effect(plugins.gen.rgbnoise(0.2, time))

  for i = 1,numpoints do
    local t = (i-1) / (numpoints-1) -- t goes from 0 to 1

    local x = t * 2 - 1 -- x goes from -1 to 1
    local nx = x + noise_amp * seamless_noise(t, noise_divergence, time*timestep)
    nx = eos.wrap_neg1_to_1(nx)

    local c
    t = (t + drift) % 1.0 -- slow drift, wrapped

    if colormode == 0 then
      c = eos.hsv2rgb(t, 1, 1)
    else
      t = 1 - math.abs(2 * t - 1) -- triangle / seamless
      c = cs.hcl_gradient(gradcolor1, gradcolor2, t)
    end

    stretchpoints[i] = eos.newpoint(nx, 0, c.r, c.g, c.b)
  end

  local noisepoints = noisebuf:as_points_optimized()


    for i=1, #stretchpoints do
      table.insert(points, stretchpoints[i])
    end
    -- for i=1,#noisepoints do
    --   table.insert(points, noisepoints[i])
    -- end

  -- sort points  by x position
  table.sort(points, function(a, b)
    return a.x < b.x
  end)

  for i=1, #points do
    if cellwidth > 0 then
      local c = {r=points[i].r, g=points[i].g, b=points[i].b}
      local left = v2.sub(points[i], edgeoffset)
      -- left.x = eos.wrap_neg1_to_1(left.x)
      eos.setcolor(left, c)
      local right = v2.add(points[i], edgeoffset)
      -- right.x = eos.wrap_neg1_to_1(right.x)
      eos.setcolor(right, c)

      eos.addblank(out, left, dwellnum)
      eos.addpoint2(out, left, 1)
      eos.addpoint2(out, right, dwellnum)
      eos.addblank(out, right, 1)
    else
      eos.addblank(out, points[i], dwellnum)
      eos.addpoint2(out, points[i], dwellnum)
      eos.addblank(out, points[i], 1)
    end
  end

  return out
end


function animate(time)
  laser.send(get_points(time))
end


