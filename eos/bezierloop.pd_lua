
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
  self.gradcolor1 = {r=1,g=0,b=0}
  self.gradcolor2 = {r=0,g=0,b=1}
  self.autogradcolor1 = {r=1,g=0,b=0}
  self.autogradcolor2 = {r=0,g=0,b=1}

  self.usegradient = false
  self.autogradient = false
  self.agconf = {
    driftoffset = 0.0,
    driftspeed = 0.0,
    range = 0.0,
    speed = 0.0
  }

  self:updatepoints(0)
  return true
end


function bl:updateautogradient()
  local cs = require("colorspace")
  local h_min = 0
  local h_max = 1
  local s1_min = 0.75
  local s1_max = 1
  local v1_min = 0.5
  local v1_max = 1
  local s2_min = 1.0
  local s2_max = 1
  local v2_min = 0.0
  local v2_max = 0.2
  local h_range = (h_max - h_min) * 0.5
  local s1_range = (s1_max - s1_min) * 0.5
  local s2_range = (s2_max - s2_min) * 0.5
  local v1_range = (v1_max - v1_min) * 0.5
  local v2_range = (v2_max - v2_min) * 0.5
  -- local h_c = (h_max + h_min) * 0.5
  local s1_c = (s1_max + s1_min) * 0.5
  local s2_c = (s2_max + s2_min) * 0.5
  local v1_c = (v1_max + v1_min) * 0.5
  local v2_c = (v2_max + v2_min) * 0.5
  local c = self.agconf

  local h1 = c.driftoffset + s.noise3d(123, 131, self.time * c.speed) * h_range
  local s1 = s1_c + s.noise3d(521, 330, self.time * c.speed) * s1_range
  local v1 = v1_c + s.noise3d(342, 419, self.time * c.speed) * v1_range
  h1 = h1 % 1.0
  s1 = math.min(1, math.max(0, s1))
  v1 = math.min(1, math.max(0, v1))
  local hsv1 = {h=h1, s=s1, v=v1}

  local h2  = h1 + s.noise3d(544, 389, self.time * c.speed) * c.range
  local s2  = s2_c + s.noise3d(774, 930, self.time * c.speed) * s2_range
  local va2 = v2_c + s.noise3d(918, 747, self.time * c.speed) * v2_range
  h2 = h2 % 1.0
  s2 = math.min(1, math.max(0, s2))
  va2 = math.min(1, math.max(0, va2))
  local hsv2 = {h=h2, s=s2, v=va2}

  self.autogradcolor1 = cs.hsv_to_rgb(hsv1)
  self.autogradcolor2 = cs.hsv_to_rgb(hsv2)
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
  local cs = require("colorspace")
  local out = {}
  local npoints = self.samples * self.symmetry

  local t = socket.gettime()
  local dt = t - self.tprev
  if dt > 1.0 then dt = 1.0 / self.targetframerate end
  self.tprev = self.time
  self.time = self.time + dt*self.timestep

  self:updatepoints(self.time)
  if self.autogradient then
    self:updateautogradient()
  end


  local colstep, col1, col2, col1_t, col2_t

  if self.colorsymmetry then
    colstep = (1.0 / npoints) * (self.symmetry)
  else
    colstep = (1.0 / npoints)
  end

  for i=1,npoints do

    col1_t = (i-1) * colstep
    col2_t = col1_t + colstep

    if self.usegradient then
      if self.autogradient then
        col1 = cs.hcl_gradient(self.autogradcolor1, self.autogradcolor2, cs.mirror_t(col1_t))
        col2 = cs.hcl_gradient(self.autogradcolor1, self.autogradcolor2, cs.mirror_t(col2_t))
      else
        col1 = cs.hcl_gradient(self.gradcolor1, self.gradcolor2, cs.mirror_t(col1_t))
        col2 = cs.hcl_gradient(self.gradcolor1, self.gradcolor2, cs.mirror_t(col2_t))
      end
    else
      col1 = pal.sinebow(col1_t)
    end

    local i1 = eos.wrapidx(i, npoints)
    local i2 = eos.wrapidx(i+1, npoints)

    local p1 = self.points[i1].pos
    local p2 = self.points[i2].pos
    local c1 = self.points[i1].cp2
    local c2 = self.points[i2].cp1

    if self.dwell > 0 then
      eos.addpoint(out, p1.x, p1.y, col1.r, col1.g, col1.b, self.dwell)
    end

    if self.usegradient then
      eos.subdivide_beziercolor2(out, p1, c1, c2, p2, self.subdivide,
                                 "lines", col1, col2)
    else
      eos.subdivide_beziercolor(out, p1, c1, c2, p2, self.subdivide,
                                "lines", col1_t, col2_t)
    end
  end

  -- dwell on start point to ensure loop is closed before blanking
  local fp = eos.pointatindex(out, 1)
  eos.addpoint(out, fp.x, fp.y, fp.r, fp.g, fp.b, 2)

  self.agconf.driftoffset = self.agconf.driftoffset + self.agconf.driftspeed*0.001
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
  elseif sel == "usegradient" then
    self.usegradient = (atoms[1] ~= 0)
  elseif sel == "gradcolor1" then
    self.gradcolor1 = {
      r = atoms[1],
      g = atoms[2],
      b = atoms[3]
    }
  elseif sel == "gradcolor2" then
    self.gradcolor2 = {
      r = atoms[1],
      g = atoms[2],
      b = atoms[3]
    }
  end
end
