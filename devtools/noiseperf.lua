
local s1 = require("simplex")
local osimplex = require("opensimplex2s")
local s2 = osimplex.new()



local function simplex1(count)
  for _ = 1, count do
    local n = s1.noise3d(
      math.random(1000),
      math.random(1000),
      math.random(1000))
    n = n + 1
  end
end


local function simplex2(count)
  for _ = 1, count do
    local n = s2:noise3_Classic(
      math.random(1000),
      math.random(1000),
      math.random(1000))
    n = n + 1
  end
end

-- simplex1(1000000)

simplex2(1000000)


