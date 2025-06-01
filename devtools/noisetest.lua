
local osimplex = require("opensimplex2s")
local S = osimplex.new()


local x, y, z, w, t, t2
local COLUMNS =129
local CENTER = math.floor(COLUMNS/2)
x = 0.0
y = 0.0
z = 0.0
w = 0.0
t = 0.0
t2 = 0.0
local off = 0.1


local colors = {
    "\27[31m", -- Red
    "\27[33m", -- Yellow
    "\27[32m", -- Green
    "\27[34m", -- Blue
    "\27[35m", -- Magenta
    "\27[36m", -- Cyan
    "\27[37m", -- White
}
local reset = "\27[39m"

local buf = {}

while true do
  -- reset buffer
  for i = 1, COLUMNS do buf[i] = 0 end

  t = t + 0.005
  t2 = t2 + 0.006

  local n0 = S:noise4_Classic(x-off, y, t2, t*8)
  local n1 = S:noise4_Classic(x,     y, t2, t)
  local n2 = S:noise4_Classic(x+off, y, t2, t/4)

  local column0 = math.floor((n0 + 1) / 2 * (COLUMNS - 0) + 0.5)
  local column1 = math.floor((n1 + 1) / 2 * (COLUMNS - 0) + 0.5)
  local column2 = math.floor((n2 + 1) / 2 * (COLUMNS - 0) + 0.5)

  buf[column0] = buf[column0] + 1
  buf[column1] = buf[column1] + 2
  buf[column2] = buf[column2] + 4

  local output = "" -- = string.rep(" ", COLUMNS)
  local tstr = string.format("%.3f ", t)

  local colidx, color
  for i=1,COLUMNS do
    colidx = buf[i]
    if colidx == 0 then
      color = colors[6]
      if i == CENTER then
        output = output .. "."
      else
        output = output .. " "
      end
    else
      color = colors[colidx]
      output = output .. color .. "#" .. reset
    end
  end

  print(tstr .. "|" .. output .. "|")
  os.execute("sleep " .. tonumber(0.01))
end

