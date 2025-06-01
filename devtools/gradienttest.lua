local pal = require("palettes")

local n = 100

for i = -n,n do
  local t = (i-1) / n * 2
  local c = pal.sinebow(t)
  print(string.format("[%.3f]: %.2f, %.2f, %.2f", t, c.r, c.g, c.b))
end
