
local bl = pd.Class:new():register("bezierloop")
local v2 = require("vec2")
local eos = require("eos")
local pal = require("palettes")
local s = require("simplex")
local socket = require("socket")

function bl:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.points = {}
  self.samples = 2
  self.beziercontrol = 0.5
  self.baseradius = 0.5
  self.color = { r=0, g=0, b=1 }
  self.subdivide = 32
  self.timestep = 1.0 / 500.0
  self.time = 0.0
  self.divergence = 0.2
  self.scale = 0.5
  self.rotrange = 0
  self.rotspeed = 1.0
  self.radrange = 1.0
  self.radspeed = 1.0
  self.symmetry = 4
  self.colorsymmetry = true
  self.dwell = 0
  self.tprev = 0.0
  self.targetframerate = 90

  self.autogradient = false
  self.agconf = {
    offset = 0.0,
    driftspeed = 0.0,
    c1base = 0.0,
    c2base = 0.0,
    range = 0.0,
    speed = 0.0
  }

  self:updatepoints(0)
  return true
end


function bl:getautogradient(col_t)
  local c = self.agconf
  if col_t < 0.5 then col_t = col_t*2 else col_t = 1.0 - (col_t-0.5)*2 end

  local c1 = c.offset + (0.5 + 0.5 * s.noise3d(12, 13, self.time * c.speed)) * c.range
  local c2 = c.offset + (0.5 + 0.5 * s.noise3d(3, 4, self.time * c.speed)) * c.range
  -- local c1 = c.offset + c.c1base + s.noise3d(12, 13, self.time * c.speed) * c.range
  -- local c2 = c.offset + c.c2base + s.noise3d(3, 4, self.time * c.speed) * c.range
  -- c1 = c1 - math.floor(c1)
  -- c2 = c2 - math.floor(c2)
  -- if c1 < 0.5 then c1 = c1*2 else c1 = 1.0 - (c1-0.5)*2 end
  -- if c2 < 0.5 then c2 = c2*2 else c2 = 1.0 - (c2-0.5)*2 end

  local val =  c1 + col_t * (c2 - c1)
  -- val = val - math.floor(val)
  -- if val < 0 then
  --   val = 1.0 - val
  -- end
  return val
  -- return val - math.floor(val)
end


function bl:makepoint(x, y, c1x, c1y, c2x, c2y)
  return {
    pos = v2.new(x, y),
    cp1 = v2.new(c1x, c1y),
    cp2 = v2.new(c2x, c2y),
    dir = v2.normalize(v2.new(x, y))
  }
end

function bl:updatepoints(t)
  self.points = {}
  local npoints = self.samples * self.symmetry
  local ang = math.pi * 2.0 / npoints
  for i=0,npoints do
    -- local i0 = (i-1) % self.symmetry
    local i1 = i % self.samples
    -- local i2 = (i+1) % self.symmetry

    local np1 = {
      x = math.cos(i1*ang),
      y = math.sin(i1*ang)
    }

    local p0 = {
      x = math.cos((i-1)*ang),
      y = math.sin((i-1)*ang)
    }
    local p1 = {
      x = math.cos(i*ang),
      y = math.sin(i*ang)
    }
    local p2 = {
      x = math.cos((i+1)*ang),
      y = math.sin((i+1)*ang)
    }
    local nrad = s.noise3d( np1.x*self.divergence,  np1.y*self.divergence, t*self.radspeed)
    local nrot = s.noise3d(-np1.x*self.divergence, -np1.y*self.divergence, t*self.rotspeed)
    local rad = self.baseradius + nrad*self.radrange
    p0 = v2.scale(p0, rad*self.scale)
    p1 = v2.scale(p1, rad*self.scale)
    p2 = v2.scale(p2, rad*self.scale)

    local p0r = v2.rotate(p0, nrot*self.rotrange)
    local p1r = v2.rotate(p1, nrot*self.rotrange)
    local p2r = v2.rotate(p2, nrot*self.rotrange)

    local c1dist = 0.5 * v2.dist(p1, p0)
    local c2dist = 0.5 * v2.dist(p1, p2)
    local cdir = v2.normalize(v2.sub(p2r, p0r))

    local c1 = v2.sub(p1r, v2.scale(cdir, c1dist * self.beziercontrol))
    local c2 = v2.add(p1r, v2.scale(cdir, c2dist * self.beziercontrol))

    table.insert(self.points, bl:makepoint(p1r.x, p1r.y, c1.x, c1.y, c2.x, c2.y ))
  end
end


function bl:in_1_bang()
  local out = {}
  local npoints = self.samples * self.symmetry

  local t = socket.gettime()
  local dt = t - self.tprev
  if dt > 1.0 then dt = 1.0 / self.targetframerate end
  self.tprev = self.time
  self.time = self.time + dt*self.timestep

  self:updatepoints(self.time)
  local colstep
  if self.colorsymmetry then
    colstep = (1.0 / npoints) * (self.symmetry)
  else
    colstep = (1.0 / npoints)
  end

  for i=1,npoints do
    -- local iw = eos.wrapidx(i, self.symmetry)
    local col1_t, col2_t
    if self.autogradient then
      if self.colorsymmetry then
        col1_t = self:getautogradient((i-1)*colstep)
        col2_t = col1_t + 1.0/npoints / self.samples
      else
        col1_t = self:getautogradient((i-1)*colstep)
        col2_t = self:getautogradient(i * colstep)
      end
    else
      col1_t = (i-1) * colstep
      col2_t = col1_t + colstep
    end
    local col = pal.sinebow(col1_t)
    local i1 = eos.wrapidx(i, npoints)
    local i2 = eos.wrapidx(i+1, npoints)

    local p1 = self.points[i1].pos
    local p2 = self.points[i2].pos
    local c1 = self.points[i1].cp2
    local c2 = self.points[i2].cp1
    if self.dwell > 0 then
      eos.addpoint(out, p1.x, p1.y, col.r, col.g, col.b, self.dwell)
    end
    eos.subdivide_beziercolor(out, p1, c1, c2, p2, self.subdivide, "lines", col1_t, col2_t)
  end

  -- dwell on start point to ensure loop is closed before blanking
  local fp = eos.pointatindex(out, 1)
  eos.addpoint(out, fp.x, fp.y, fp.r, fp.g, fp.b, 12)

  self.agconf.offset = self.agconf.offset + self.agconf.driftspeed
  -- self.agconf.offset = math.modf(self.agconf.offset, 1.0)
  -- self.time = self.time + self.timestep
  self:outlet(2, "float", { #out / 5 })
  self:outlet(1, "list", out)
end


function bl:in_2(sel, atoms)
  if sel == "baseradius" then
    self.baseradius = atoms[1]
  elseif sel == "samples" then
    self.samples = atoms[1]
  elseif sel == "symmetry" then
    self.symmetry = math.max(1, atoms[1])
  elseif sel == "colorsymmetry" then
    self.colorsymmetry = (atoms[1] ~= 0)
  elseif sel == "beziercontrol" then
    self.beziercontrol = atoms[1]
  elseif sel == "dwell" then
    self.dwell = math.max(0, atoms[1])
  elseif sel == "subdivide" then
    self.subdivide = atoms[1]
  elseif sel == "timestep" then
    self.timestep = atoms[1]  / 10.0
  elseif sel == "divergence" then
    self.divergence = atoms[1]
  elseif sel == "scale" then
    self.scale = atoms[1]
  elseif sel == "radrange" then -- radius range
    self.radrange = atoms[1]
  elseif sel == "radspeed" then -- radius speed
    self.radspeed = atoms[1]
  elseif sel == "rotrange" then -- rotation amount
    self.rotrange = atoms[1]
  elseif sel == "rotspeed" then -- rotation speed
    self.rotspeed = atoms[1]
  elseif sel == "autogradient" then
    self.autogradient = (atoms[1] ~= 0)
  elseif sel == "autogradspeed" then
    self.agconf.speed = atoms[1]
  elseif sel == "autogradrange" then
    self.agconf.range = atoms[1]
  elseif sel == "autograddrift" then
    self.agconf.driftspeed = atoms[1]
  end
end
