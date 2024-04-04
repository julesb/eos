
local T3D = pd.Class:new():register("3dtest")

function T3D:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.screenunit = 1.0 / 2047.0

  self.cam_pos = { x=0, y=0, z=-10 }
  self.lookat = { x=0, y=0, z=0 }
  self.up = {x=0, y=1, z=0}
  self.aspect_ratio = 1.0
  self.fov = 60
  self.near_clip = 0.1 -- * self.screenunit
  self.far_clip = 100 -- * self.screenunit

  self.cube_verts = {
    {x=-0.1, y=-0.1, z=-0.1, r=1, g=1, b=1},
    {x=-0.1, y=-0.1, z=0.1, r=1, g=1, b=1},
    {x=-0.1, y=0.1,  z=-0.1, r=1, g=1, b=1},
    {x=-0.1, y=0.1,  z=0.1, r=1, g=1, b=1},
    {x=0.1,  y=-0.1, z=-0.1, r=1, g=1, b=1},
    {x=0.1,  y=-0.1, z=0.1, r=1, g=1, b=1},
    {x=0.1,  y=0.1,  z=-0.1, r=1, g=1, b=1},
    {x=0.1,  y=0.1,  z=0.1, r=1, g=1, b=1}
  }
  self.quad_verts = {
    {x=-0.1, y=-0.1, z=-0.1, r=1, g=1, b=1.0},
    {x=-0.1, y=-0.1, z=0.1, r=1, g=1, b=1.0},
    {x=-0.1, y=0.1,  z=-0.1, r=1, g=1, b=1.0},
    {x=-0.1, y=0.1,  z=0.1, r=1, g=1, b=1.0},
  }
  return true
end

function T3D:in_1_bang(sel, atoms)
  local eos = require("eos")
  local m4 = require("mat4")
  local v2 = require("vec2")
  -- local npoints = #self.cube_verts

  self.lookat.x = self.cam_pos.x

  local points = m4.camera(
    self.quad_verts,
    self.cam_pos,
    self.lookat,
    self.up,
    self.fov,
    self.aspect_ratio,
    self.near_clip,
    self.far_clip)


  for _, point in ipairs(points) do
    point = v2.scale(point, self.screenunit)
  end

  for _, point in ipairs(points) do
    print("point: ", v2.tostring(point))
  end
  local out = eos.points_to_xyrgb(points)

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end


function T3D:in_2(sel, atoms)
  if sel == "camx" then
    self.cam_pos.x = atoms[1] * self.screenunit
  elseif sel == "camy" then
    self.cam_pos.y = atoms[1] * self.screenunit
  elseif sel == "camz" then
    self.cam_pos.z = atoms[1] * self.screenunit
  elseif sel == "fov" then
    self.fov = atoms[1]
  end
end
