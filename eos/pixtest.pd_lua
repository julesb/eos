local pixtest = pd.Class:new():register("pixtest")

function pixtest:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2

  self.screenunit = 1.0 / 2047.0
  self.time = 0.0
  self.bufsize = 1024
  self.noisefreq = 1.0
  self.timestep = 0.01
  self.dwellnum = 2

  if type(atoms[1]) == "number" then
    self.bufsize = math.floor(atoms[1])
  end

  self.pb = require("pixelbuffer")
  self.buffer = self.pb.new(self.bufsize)
  return true
end


function pixtest:in_1_bang()
  local eos = require("eos")

  local function noisefunc(freq, time)
    local simplex = require("simplex")
    return function (x, i, c)
      local sr = 12.34521
      local sg = 371.15164
      local sb = 93.36358
      local nr = math.max(0, simplex.noise3d(freq*i, sr, time))
      local ng = math.max(0, simplex.noise3d(freq*i, sg, time))
      local nb = math.max(0, simplex.noise3d(freq*i, sb, time))
      -- local nr = 0.5 + 0.5 * simplex.noise3d(freq*i, sr, time)
      -- local ng = 0.5 + 0.5 * simplex.noise3d(freq*i, sg, time)
      -- local nb = 0.5 + 0.5 * simplex.noise3d(freq*i, sb, time)
      local r = math.min(1, c.r + nr)
      local g = math.min(1, c.g + ng)
      local b = math.min(1, c.b + nb)
      return r, g, b, 1
    end
  end

  self.buffer
    :clear()
    :map(noisefunc(self.noisefreq, self.time))

  local points = self.buffer:as_points()
  local out = eos.points_to_xyrgb(points)

  self.time = self.time + self.timestep

  self:outlet(2, "float", {#out / 5})
  self:outlet(1, "list", out)
end


function pixtest:in_2(sel, atoms)
  if sel == "bufsize" then
    self.bufsize = math.max(1, atoms[1])
  elseif sel == "timestep" then
    self.timestep = atoms[1] * 0.001
  elseif sel == "dwell" then
    self.dwellnum = math.max(0, atoms[1])
  elseif sel == "noisefreq" then
    self.noisefreq = atoms[1] * 0.01
  end
end

