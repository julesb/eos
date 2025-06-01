local v2 = require("vec2")

local p0 = v2.new(1, 0)
local p1 = v2.new(0, 0)
local p2 = v2.new(0, 1)

local npoints = 20

for i=0, 20 do
  local a = (i-1) * math.pi * 2 / npoints
  p2.x = math.cos(a)
  p2.y = math.sin(a)

  local c = v2.curvature(p0, p1, p2)
  print("C:", c)
end

