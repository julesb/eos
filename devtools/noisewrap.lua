
local simplex = require("simplex")
local charwidth = 80

local ang = 0
local t = 0.0
local pi2 = math.pi*2

local function sleep(sec)
  local socket = require("socket")
  socket.select(nil, nil, sec)
end

local iters = 0
local noisesum = 0
local n
while true do
  -- for _=1,10000000 do
    iters = iters + 1
    n = simplex.noise3d(10, 10, t)
    n = n - 0.0111580 -- correction for slight positive noise bias
    noisesum = noisesum + n
    t = t + 0.03
  -- end
  ang = ang + 0.1 * n
  if ang >= pi2 then ang = ang - pi2 end
  if ang < 0 then ang = ang + pi2 end
  local pos = math.floor((ang / pi2) * charwidth)
  for i=0,charwidth-1 do
    if pos == i then
      io.write("#")
    else
      io.write(" ")
    end
  end
  -- io.write(string.format("%d: %.4f\t%.4f\t %.6f", iters, n, noisesum, noisesum/iters))
  io.write("|\n")
  sleep(0.01)
end
