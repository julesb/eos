-- test.lua
---@diagnostic disable: undefined-global
---@diagnostic disable: lowercase-global


function init()
  print("init")
end

local framecount = 0

function animate(time)
  local eos = require("eos")
  local numpoints = 200
  local points = {}

  for i=1, numpoints do
    local t = (i-1) / (numpoints-1)
    local x = t * 2 - 1
    local y = 0
    local col = {
      r = 0.5 + 0.5 * math.sin(time),
      g = 0.5 + 0.5 * math.sin(time + math.pi/2),
      b = 0.5 + 0.5 * math.sin(time + math.pi)
    }

    table.insert(points, eos.newpoint2(x, y, col))
  end

  laser.send(eos.points_to_xyrgb(points))
end

function cleanup()
  print("cleanup")
end
