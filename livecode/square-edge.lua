-- test.lua


function init()
  print("init")
end



function animate(time)
  local eos = require("eos")
  local pb = require("pixelbuffer")
  local plugins = require("pixelplugins")
  local color2 = {r=0, g=0, b=1, a=1}

  local freq = 20 --math.sin(time) * 5
  -- local duty = (math.sin(time * 10.21211))
  local duty = 0.2 + 0.7 * (0.5 + 0.5 * math.sin(time * 1.21211))
  local phase = 50 * math.sin(time *0.05) + duty*2

  local wave = pb.new(4096)
  wave
    :apply_effect(plugins.gen.square(color2, freq, duty, phase))

  local edges = wave:clone()
  edges
    :apply_effect(plugins.conv.edge())
    :flatten(0.5)
    :blend("add")(wave)

  local points = edges:as_points_optimized()
  -- local out = {}
  laser.send(eos.points_to_xyrgb(points))
end

function cleanup()
  print("cleanup")
  -- laser.send({0, 0, 0, 0, 0}) -- blank at 0,0
end
