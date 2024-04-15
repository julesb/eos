
local camera3d = pd.Class:new():register("camera3d")

function camera3d:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.screenunit = 1.0 / 2047.0

  self.cam_pos = { x=0, y=0, z=-10 }
  self.lookat = { x=0, y=0, z=0 }
  self.up = {x=0, y=-1, z=0}
  self.aspect_ratio = 1.0
  self.fov = 60
  self.near_clip = 0.5 -- * self.screenunit
  self.far_clip = 20 -- * self.screenunit

  self.show_axis = true

  local len = 1
  self.cube_verts = {
    -- bottom square
    -- -- initial blank
    {x=-len, y=-len, z=-len, r=0, g=0, b=0},

    {x=-len, y=-len, z=-len, r=1, g=1, b=1},
    {x=-len, y=-len, z= len,  r=1, g=1, b=1},
    {x= len, y=-len, z= len, r=1, g=1, b=1},
    {x= len, y=-len, z=-len,  r=1, g=1, b=1},
    ---- back to first point
    {x=-len, y=-len, z=-len, r=1, g=1, b=1},

    -- first vertical happens

    -- top square
    {x=-len, y= len, z=-len, r=1, g=1, b=1},
    {x=-len, y= len, z= len,  r=1, g=1, b=1},
    {x= len, y= len, z= len, r=1, g=1, b=1},
    {x= len, y= len, z=-len,  r=1, g=1, b=1},

    ---- back to first point
    {x=-len, y= len, z=-len, r=1, g=1, b=1},

    -- blank
    {x=-len, y= len, z=-len, r=0, g=0, b=0},
    -- remaining three verticals
    -- 1
    {x=-len, y= len, z= len, r=1, g=1, b=1},
    {x=-len, y=-len, z= len, r=1, g=1, b=1},
    -- blank
    {x=-len, y=-len, z= len, r=0, g=0, b=0},
    -- 2
    {x= len, y=-len, z= len, r=1, g=1, b=1},
    {x= len, y= len, z= len, r=1, g=1, b=1},
    -- blank
    {x= len, y= len, z= len, r=0, g=0, b=0},
    -- 3

    {x= len, y= len, z=-len, r=1, g=1, b=1},
    {x= len, y=-len, z=-len, r=1, g=1, b=1},
    -- blank
    {x= len, y=-len, z=-len, r=0, g=0, b=0}
  }

  self.quad_verts = {
    {x=-1, y=-1, z=0, r=1, g=1, b=1.0},
    {x= 1, y=-1, z=0, r=1, g=1, b=1.0},
    {x= 1, y= 1, z=0, r=1, g=1, b=1.0},
    {x=-1, y= 1, z=0, r=1, g=1, b=1.0},
    {x=-1, y=-1, z=0, r=1, g=1, b=1.0},
  }


  self.axis_verts = {
    -- {x= 0, y=0, z=0, r=0, g=0, b=0}, -- blank

    {x= 0.0, y=0, z=0, r=0, g=0, b=0}, -- blank
    {x= 0.0, y=0, z=0, r=1, g=0, b=0},
    {x= len, y=0, z=0, r=1, g=0, b=0},
    {x= len, y=0, z=0, r=0, g=0, b=0}, -- blank

    {x= 0, y= 0.0, z=0, r=0, g=0, b=0}, -- blank
    {x= 0, y= 0.0, z=0, r=0, g=1, b=0},
    {x= 0, y= len, z=0, r=0, g=1, b=0},
    {x= 0, y= len, z=0, r=0, g=0, b=0}, -- blank

    {x= 0, y=0, z= 0.0, r=0, g=0, b=0}, -- blank
    {x= 0, y=0, z= 0.0, r=0, g=0, b=1},
    {x= 0, y=0, z= len, r=0, g=0, b=1},
    {x= 0, y=0, z= len, r=0, g=0, b=0}, -- blank

    -- {x= 0, y=0, z=0, r=0, g=0, b=0}, -- blank
  }

  return true
end




function camera3d:in_1_list(inp)
  local eos = require("eos")
  local m4 = require("mat4")
  local v2 = require("vec2")
  local v3 = require("vec3")
  local clipper = require("clipper")
  local s3d = require("scene3d")

  local npoints =  #inp / 5

  local inp3d = {}
  for i=1,npoints do
    local p = eos.pointatindex(inp, i)
    p.z = 0
    table.insert(inp3d, p)
  end

  local scene = s3d.scene({
    -- self.xaxis_verts,
    inp3d
    -- self.axis_verts,
    -- self.cube_verts,
    -- self.triangle_verts
  })

  if self.show_axis then
    s3d.add_object(scene, self.axis_verts)
    s3d.add_object(scene, self.quad_verts)

  end

  local points = m4.camera(
    scene,
    v3.scale(self.cam_pos, 1),
    v3.scale(self.lookat, 1),
    self.up,
    -- math.rad(self.fov) * 2.3333,
    math.rad(self.fov),
    self.aspect_ratio,
    self.near_clip,
    self.far_clip)

    local clipped_points = clipper.frustum.nearfar(points, self.near_clip,
                                                   self.far_clip)
  local out = eos.points_to_xyrgb(clipped_points)
  out = clipper.rect.clip(out, {x=0,y=0,w=1.9,h=1.9})
  if #out == 0 then eos.addpoint(out, 0, 0, 0, 0, 0) end

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end


function camera3d:in_2(sel, atoms)
  -- print(string.format("camera3d: receive %s: %s", sel, atoms[1]))
  if sel == "camx" then
    self.cam_pos.x = atoms[1]
  elseif sel == "camy" then
    self.cam_pos.y = atoms[1]
  elseif sel == "camz" then
    self.cam_pos.z = atoms[1]
  elseif sel == "lookatx" then
    self.lookat.x = atoms[1]
  elseif sel == "lookaty" then
    self.lookat.y = atoms[1]
  elseif sel == "lookatz" then
    self.lookat.z = atoms[1]

  elseif sel == "fov" then
    self.fov = atoms[1]
  elseif sel == "near" then
    self.near_clip = math.max(0.01, atoms[1])
  elseif sel == "far" then
    self.far_clip = math.max(self.near_clip+0.01, atoms[1])
  elseif sel == "axis" then
    self.show_axis = (atoms[1] ~= 0)
  end
end
