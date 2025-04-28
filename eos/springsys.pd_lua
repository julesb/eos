local ss = pd.Class:new():register("springsys")

function ss:initialize(sel, atoms)
  -- Set up inlets and outlets
  self.inlets = 2
  self.outlets = 2

  self.screenunit = 1.0 / 2047.0
  self.time = 0.0
  self.iteration = 0
  self.numpoints = 50
  self.timestep = 0.1
  self.dwellnum = 1

  self.springsys = require("springsystem")
  -- self.noise_amp = 0.2
  -- self.noise_divergence = 0.2

  if type(atoms[1]) == "number" then
    self.numpoints = math.floor(atoms[1])
  end


  self.ssys = self.springsys:init(self.numpoints)

  return true
end

function ss:get_colors()
  local eos = require("eos")
  local v2 = require("vec2")
  local result = {}
  local vels = self.ssys:get_velocities()
  local max_vel = 1
  for i=1,#vels do
    local l = v2.len(vels[i]) / max_vel
    if l < 0.01 then
      result[i] = {r=0,g=0,b=0}
    else
      local hue = math.max(0, math.min(l, 1))
      result[i] = eos.hsv2rgb(hue, 1, 1)
    end
  end
  return result
end


function ss:get_points(points)
  local eos = require("eos")
  local out = {}
  local colors = self:get_colors()
  local huestep = 1 / (self.numpoints - 1)
  for i=1, #points do
    eos.setcolor(points[i], eos.hsv2rgb((i-1)*huestep, 1, 1))
    -- eos.setcolor(points[i], {r=1, g=1, b=1})
    -- eos.setcolor(points[i], colors[i])
  end
  -- sort points  by x position
  -- table.sort(points, function(a, b)
  --   return a.x < b.x
  -- end)

  for i=1, #points do
    -- eos.addblank(out, points[i], self.dwellnum)
    eos.addpoint2(out, points[i], self.dwellnum)
    -- eos.addblank(out, points[i], 1)
  end
  return out
end


function ss:in_1_bang()


  self.ssys:update(self.timestep)

  -- self.ssys:apply_force(self.numpoints/2, {x=0, y=50})

  -- if math.random() < 0.008 then
  --   local index = math.floor(math.random(self.numpoints))
  --   -- local index = math.floor(self.numpoints / 3)
  --   local force = {x=0, y=(math.random()*2-1) * 20.0 }
  --   self.ssys:apply_force(index,force)
  --   pd.post(string.format("apply_force: [%d]: %f", index, force.y))
  -- end

  local spring_points = self.ssys:get_points()
  local out = self:get_points(spring_points)

  self.time = self.time + self.timestep
  self.iteration = self.iteration + 1
  self:outlet(2, "float", {#out / 5})
  self:outlet(1, "list", out)
end


function ss:in_2(sel, atoms)
  if sel == "numpoints" then
    self.numpoints = math.max(3, atoms[1])
    self.ssys:set_size(self.numpoints)
  elseif sel == "timestep" then
    self.timestep = atoms[1] * 0.1
    self.ssys:set_time_step(self.timestep)
  elseif sel == "dwell" then
    self.dwellnum = math.max(0, atoms[1])
  elseif sel == "gravity" then
    self.ssys:set_gravity({x=0, y=atoms[1]})
  elseif sel == "springconst" then
    self.ssys:set_spring_constant(math.max(0, atoms[1]))
  elseif sel == "damping" then
    self.ssys:set_damping(math.max(0.00001, atoms[1] * 0.01))
  elseif sel == "position1" then
    self.ssys:set_position(1, {x=atoms[1], y=atoms[2], r=1, g=1, b=1})
  elseif sel == "position2" then
    self.ssys:set_position(self.numpoints, {x=atoms[1], y=atoms[2], r=1, g=1, b=1})
  -- elseif sel == "noiseamp" then
  --   self.noise_amp = atoms[1] * 0.01
  -- elseif sel == "noisediverge" then
  --   self.noise_divergence = atoms[1]
  end
end

