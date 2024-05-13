
local simplex = require("simplex2")
local osimplex = require("opensimplex2s")


local x, y, z, w, t
local COLUMNS = 129
local CENTER = math.floor(COLUMNS/2)
x = 0.0
y = 0.0
z = 0.0
w = 0.0
t = 0.0

local S = osimplex.new()

while true do
  t = t + 0.05

  -- local n = simplex.noise4d(x, y, z, t)
  local n = S:noise4_Classic(t, y, z, w)
  local column = math.floor((n + 1) / 2 * (COLUMNS - 0) + 0.5)
  local output = string.rep(" ", COLUMNS)
  local tstr = string.format("%.3f ", t)
  output = output:sub(1, column) .. "#" .. output:sub(column + 2)

  if column ~= CENTER then
    output = output:sub(1, CENTER) .. "." .. output:sub(CENTER + 2)
  end

  print(tstr .. "|" .. output .. "|")
  os.execute("sleep " .. tonumber(0.05))
end

