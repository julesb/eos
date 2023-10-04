
local bl = pd.Class:new():register("bezierloop")
local v2 = require("vec2")
local eos = require("eos")
local pal = require("palettes")

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
  self.scale = 0.5
  self.noiserot = 180
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
    local n = s.noise3d(p1.x*self.noisescale, p1.y*self.noisescale, t)
    local n2 = s.noise3d(-p1.x*self.noisescale, -p1.y*self.noisescale, t)
    local rad = self.baseradius + n
    p0 = v2.scale(p0, rad*self.scale)
    p1 = v2.scale(p1, rad*self.scale)
    p2 = v2.scale(p2, rad*self.scale)

    -- local p0r = v2.rotate(p0, (i+1)*n2*t*self.noiserot)
    -- local p1r = v2.rotate(p1, (i+1)*n2*t*self.noiserot)
    -- local p2r = v2.rotate(p2, (i+1)*n2*t*self.noiserot)
    local p0r = v2.rotate(p0, n2*self.noiserot)
    local p1r = v2.rotate(p1, n2*self.noiserot)
    local p2r = v2.rotate(p2, n2*self.noiserot)

    local c1dist = 0.5 * v2.dist(p1, p0)
    local c2dist = 0.5 * v2.dist(p1, p2)
    local cdir = v2.normalize(v2.sub(p2r, p0r))

    local c1 = v2.sub(p1r, v2.scale(cdir, c1dist * self.beziercontrol))
    local c2 = v2.add(p1r, v2.scale(cdir, c2dist * self.beziercontrol))

    table.insert(self.points, bl:makepoint(p1r.x, p1r.y, c1.x, c1.y, c2.x, c2.y ))
  end
end

-- function bl:updatepoints(t)
--   local s = require("simplex")
--   self.points = {}
--   local ang = math.pi * 2.0 / self.npoints
--   for i=0,self.npoints-1 do
--     local x = math.cos(i*ang)
--     local y = math.sin(i*ang)
--     local n = s.noise3d(x*self.noisescale, y*self.noisescale, t)
--     local n2 = s.noise3d(-x*self.noisescale, -y*self.noisescale, t)
--     local rad = self.baseradius + n
--     x = x * rad * self.scale
--     y = y * rad * self.scale
--     local p = v2.rotate(v2.new(x, y), n2*self.noiserot)
--     local c1x = p.x + p.y*self.beziercontrol
--     local c1y = p.y - p.x*self.beziercontrol
--     local c2x = p.x - p.y*self.beziercontrol
--     local c2y = p.y + p.x*self.beziercontrol
--
--     table.insert(self.points, bl:makepoint(p.x, p.y, c1x, c1y, c2x, c2y ))
--   end
-- end


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

  for i=1,#out/5 do
    local col = pal.sinebow(i*5 / #out)
    local pidx = 1 + (i-1) * 5
    out[pidx+2] = col.r
    out[pidx+3] = col.g
    out[pidx+4] = col.b
  end
  -- local lastp = eos.pointatindex(out, #out/5)
  -- local fp = eos.pointatindex(out, 1)
  -- eos.addpoint(out, fp.x, fp.y, fp.r, fp.g, fp.b, 1)


  self.time = self.time + self.timestep
  self:outlet(2, "float", { #out / 5 })
  self:outlet(1, "list", out)
end


function bl:in_2(sel, atoms)
  if sel == "baseradius" then
    self.baseradius = atoms[1]
  elseif sel == "npoints" then
    self.npoints = atoms[1]
  elseif sel == "beziercontrol" then
    self.beziercontrol = atoms[1]
  elseif sel == "subdivide" then
    self.subdivide = atoms[1]
  elseif sel == "timestep" then
    self.timestep = atoms[1] / 500.0
  elseif sel == "noisescale" then
    self.noisescale = atoms[1]
  elseif sel == "scale" then
    self.scale = atoms[1]
  elseif sel == "noiserot" then
    self.noiserot = atoms[1]
  end
end
