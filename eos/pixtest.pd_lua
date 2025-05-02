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
  self.falloff = 0.0005

  self.blurradius = 3
  self.blursigma = 1.5

  self.color1 = {r=1, g=0, b=0}
  self.color2 = {r=0, g=0, b=1}

  self.freq = 1
  self.phase = 0
  self.duty = 0.5
  self.dir = 1

  pd.post("sel: " .. sel)


  if type(atoms[1]) == "number" then
    self.bufsize = math.floor(atoms[1])
  end

  self.pb = require("pixelbuffer")
  self.buffer = self.pb.new(self.bufsize)
  return true
end


function pixtest:edge_test()
  local plugins = require("pixelplugins")

  local sqr = self.pb.new(self.bufsize)
  sqr:apply_effect(plugins.gen.square( self.color2, self.freq, self.duty, self.time))
  local sine = self.pb.new(self.bufsize)
  sine:apply_effect(plugins.gen.sine(self.color1, self.freq * 0.2, self.duty, -self.time*0.2))

  local edges = sqr:clone()
  edges
    :apply_effect(plugins.conv.edge())
    :flatten(0.1)
  --
  sqr
    :blend("add")(edges)
    :blend("add")(sine)

  local points = sqr:as_points()
  return points
end


function pixtest:in_1_bang()
  local eos = require("eos")

  local function noisefunc(freq, time)
    local simplex = require("simplex")
    return function (x, i, c)
      local sr = 12.34521
      local sg = 371.15164
      local sb = 93.36358
      -- local nr = math.max(0, simplex.noise3d(freq*i, sr, time))
      -- local ng = math.max(0, simplex.noise3d(freq*i, sg, time))
      -- local nb = math.max(0, simplex.noise3d(freq*i, sb, time))
      local nr = 0.5 + 0.5 * simplex.noise3d(freq*i, sr, time)
      local ng = 0.5 + 0.5 * simplex.noise3d(freq*i, sg, time)
      local nb = 0.5 + 0.5 * simplex.noise3d(freq*i, sb, time)
      local r = math.min(1, c.r + nr)
      local g = math.min(1, c.g + ng)
      local b = math.min(1, c.b + nb)
      return nr, ng, nb, 1
    end
  end


  local function expdotfunc(posx, e)
    return function (x, i, c)
      local d = math.abs(x - (0.5 + 0.5 * posx))
      if d == 0 then d = 0.0005 end
      local b = math.min(1, e / (d*d))
      if b < 0.1 then b = 0 end
      -- return c.r, c.g, b+c.b, 1
      return b+c.r, b+c.g, b+c.b, 1
    end
  end

  local function threshold(thresh)
    return function (_, _, c)
      local r, g, b
      if c.r >= thresh then r = c.r else r=0 end
      if c.g >= thresh then g = c.g else g=0 end
      if c.b >= thresh then b = c.b else b=0 end
      return r, g, b, 1
    end
  end

  -- local dotx = 0.8 * math.sin(self.time * 0.1)
  -- local plugins = require("pixelplugins")
  -- -- local sinecol = {r=0, g=0, b=1}
  -- local layer1 = self.pb.new(self.bufsize)
  -- layer1
  --   :apply_effect(plugins.gen.sine(self.color2, self.freq, 1, self.time))
  --   -- :apply_effect(plugins.gen.triangle(self.color2, self.freq, self.phase))
  --   -- :apply_effect(plugins.gen.saw(self.color2, self.freq, self.phase))
  --   -- :apply_effect(plugins.gen.square(self.color2, self.freq, self.duty, self.phase))
  --   -- :apply_effect(plugins.conv.blur(self.blurradius, self.blursigma))
  --
  -- self.buffer
  --   :clear(self.color1)
  --   :blend("add")(layer1)
  --
  -- -- self.buffer
  -- --   :clear()
  -- --   :map(noisefunc(self.noisefreq, self.time))
  -- --   :map(threshold(0.5))
  --   -- :map(expdotfunc(dotx, self.falloff))
  --
  -- -- local points = self.buffer:as_points_alt(self.dir)
  -- local points = self.buffer:as_points()
  local points = self:edge_test()
  local out = eos.points_to_xyrgb(points)

  self.time = self.time + self.timestep
  if self.dir == 1 then self.dir = -1 else self.dir = 1 end

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
  elseif sel == "falloff" then
    self.falloff = atoms[1] * 0.0001
  elseif sel == "freq" then
    self.freq = atoms[1]
  elseif sel == "duty" then
    self.duty = atoms[1]
  elseif sel == "phase" then
    self.phase = atoms[1]
  elseif sel == "blurradius" then
    self.blurradius = atoms[1]
  elseif sel == "blursigma" then
    self.blursigma = atoms[1]
  elseif sel == "color1" then
    self.color1 = {r= atoms[1] or 0, g=atoms[2] or 0, b=atoms[3] or 0}
  elseif sel == "color2" then
    self.color2 = {r= atoms[1] or 0, g=atoms[2] or 0, b=atoms[3] or 0}
 end
end

