local ss = pd.Class:new():register("stretchscan")

function ss:initialize(sel, atoms)
  -- Set up inlets and outlets
  self.inlets = 2    -- bang, bufsize, rule, cycle
  self.outlets = 2  -- cell state output

  self.screenunit = 1.0 / 2047.0
  self.time = 0.0
  self.points = {}

  self.numpoints = 200
  self.noise_amp = 0.18
  self.noise_divergence = 0.03
  self.timestep = 0.01
  self.dwellnum = 2
  self.cellwidth = 0.0

  self.gradcolor1 = {r=1, g=0, b=0}
  self.gradcolor2 = {r=0, g=0, b=1}

  self.colormode = 1 -- 0 = HSV, 1 = gradient
  if type(atoms[1]) == "number" then
    self.numpoints = math.floor(atoms[1])
  end
  return true
end


function ss:seamless_noise(ang, rad, t)
  local simplex = require("simplex")
  local x = rad * math.cos(ang * math.pi*2)
  local y = rad * math.sin(ang * math.pi*2)
  return simplex.noise3d(x, y, t)
end

function ss:get_points()
  local eos = require("eos")
  local v2 = require("vec2")
  local cs = require("colorspace")
  local points = {}
  local out = {}
  local cellrad = (2.0 / self.numpoints) * self.cellwidth / 2.0
  local edgeoffset = { x = cellrad, y = 0, r = 0, g = 0, b = 0 }
  local drift = self.time * 0.01

  for i = 1,self.numpoints do
    local t = (i-1) / (self.numpoints-1) -- t goes from 0 to 1

    local x = t * 2 - 1 -- x goes from -1 to 1
    local nx = x + self.noise_amp * self:seamless_noise(t, self.noise_divergence, self.time)
    nx = eos.wrap_neg1_to_1(nx)

    local c
    t = (t + drift) % 1.0 -- slow drift, wrapped

    if self.colormode == 0 then
      c = eos.hsv2rgb(t, 1, 1)
    else
      t = 1 - math.abs(2 * t - 1) -- triangle / seamless
      c = cs.hcl_gradient(self.gradcolor1, self.gradcolor2, t)
    end

    points[i] = eos.newpoint(nx, 0, c.r, c.g, c.b)
  end

  -- sort points  by x position
  table.sort(points, function(a, b)
    return a.x < b.x
  end)

  for i=1, #points do
    if self.cellwidth > 0 then
      local c = {r=points[i].r, g=points[i].g, b=points[i].b}
      local left = v2.sub(points[i], edgeoffset)
      -- left.x = eos.wrap_neg1_to_1(left.x)
      eos.setcolor(left, c)
      local right = v2.add(points[i], edgeoffset)
      -- right.x = eos.wrap_neg1_to_1(right.x)
      eos.setcolor(right, c)

      eos.addblank(out, left, self.dwellnum)
      eos.addpoint2(out, left, 1)
      eos.addpoint2(out, right, self.dwellnum)
      eos.addblank(out, right, 1)
    else
      eos.addblank(out, points[i], self.dwellnum)
      eos.addpoint2(out, points[i], self.dwellnum)
      eos.addblank(out, points[i], 1)
    end
  end

  return out
end


function ss:in_1_bang()
  local out = self:get_points()
  self.time = self.time + self.timestep
  self:outlet(2, "float", {#out / 5})
  self:outlet(1, "list", out)
end


function ss:in_2(sel, atoms)
  if sel == "numpoints" then
    self.numpoints = math.max(3, atoms[1])
  elseif sel == "timestep" then
    self.timestep = atoms[1] * 0.001
  elseif sel == "dwell" then
    self.dwellnum = math.max(0, atoms[1])
  elseif sel == "noiseamp" then
    self.noise_amp = atoms[1] * 0.01
  elseif sel == "noisediverge" then
    self.noise_divergence = atoms[1]
  elseif sel == "cellwidth" then
    self.cellwidth = atoms[1]
  elseif sel == "colormode" then
    self.colormode = math.max(0, math.min(1, atoms[1]))
  elseif sel == "gradcolor1" then
    self.gradcolor1 = {r= atoms[1], g=atoms[2], b=atoms[3]}
  elseif sel == "gradcolor2" then
    self.gradcolor2 = {r= atoms[1], g=atoms[2], b=atoms[3]}
  end
end

