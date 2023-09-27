
local bl = pd.Class:new():register("bezierloop")
local v2 = require("vec2")
local eos = require("eos")

function bl:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.npoints = 4
  self.points = {}
  self.beziercontrol = 0.5
  self.baseradius = 0.5
  self.color = { r=0, g=0, b=1 }
  self.subdivide = 32
  self.timestep = 1.0 / 500.0
  self.time = 0.0
  self.noisescale = 0.2
  self:updatepoints(0)
  return true
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
  local s = require("simplex")
  self.points = {}
  local ang = math.pi * 2.0 / self.npoints
  for i=0,self.npoints-1 do
    local x = math.cos(i*ang)
    local y = math.sin(i*ang)
    local rad = self.baseradius + s.noise3d(x*self.noisescale, y*self.noisescale, t)
    x = x * rad
    y = y * rad
    local c1x = x + y*self.beziercontrol
    local c1y = y - x*self.beziercontrol
    local c2x = x - y*self.beziercontrol
    local c2y = y + x*self.beziercontrol

    table.insert(self.points, bl:makepoint(x, y, c1x, c1y, c2x, c2y ))
  end

end


function bl:in_1_bang()
  local out = {}
  self:updatepoints(self.time)
  for i=1,self.npoints do
    local i1 = eos.wrapidx(i, self.npoints)
    local i2 = eos.wrapidx(i+1, self.npoints)

    local p1 = self.points[i1].pos
    p1.r = self.color.r
    p1.g = self.color.g
    p1.b = self.color.b

    local p2 = self.points[i2].pos
    local c1 = self.points[i1].cp2
    local c2 = self.points[i2].cp1
    eos.subdivide_bezier(out, p1, c1, c2, p2, self.subdivide, "lines")
  end

  -- local lastp = eos.pointatindex(out, #out/5)
  local fp = eos.pointatindex(out, 1)
  eos.addpoint(out, fp.x, fp.y, fp.r, fp.g, fp.b, 1)

  self.time = self.time + self.timestep
  self:outlet(2, "float", { #out / 5 })
  self:outlet(1, "list", out)
end


function bl:in_2(sel, atoms)
  if sel == "baseradius" then
    self.baseradius = atoms[1]
    self:updatepoints()
  elseif sel == "npoints" then
    self.npoints = atoms[1]
    self:updatepoints()
  elseif sel == "beziercontrol" then
    self.beziercontrol = atoms[1]
    self:updatepoints()
  elseif sel == "subdivide" then
    self.subdivide = atoms[1]
  elseif sel == "timestep" then
    self.timestep = atoms[1] / 500.0
  elseif sel == "noisescale" then
    self.noisescale = atoms[1]
  end
end
