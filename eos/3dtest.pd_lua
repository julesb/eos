
local T3D = pd.Class:new():register("3dtest")

function T3D:initialize(sel, atoms)
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
    {x=-0.1, y=-0.1, z=-0.1, r=1, g=1, b=1.0},
    {x=-0.1, y=-0.1, z=0.1, r=1, g=1, b=1.0},
    {x=-0.1, y=0.1,  z=-0.1, r=1, g=1, b=1.0},
    {x=-0.1, y=0.1,  z=0.1, r=1, g=1, b=1.0},
  }

  local tx = 3
  self.triangle_verts = {
    {x =tx+ 1, y = 0, z=0, r=1, g=0, b=1},
    {x =tx+ -0.5, y = 0.8660254037844386, z=0, r=1, g=0, b=1},
    {x =tx+ -0.5, y = -0.8660254037844386, z=0, r=1, g=0, b=1},
    {x =tx+ 1, y = 0, z=0, r=1, g=0, b=1}
  }

  self.axis_verts = {
    -- centerblank
    {x=0, y=0, z=0, r=0, g=0,b=0},

    -- C -> X
    {x=0, y=0, z=0, r=1, g=0, b=0}, -- C
    {x=1, y=0, z=0, r=1, g=0, b=0},
    {x=1, y=0, z=0, r=0, g=0, b=0}, -- blank

    -- C -> Y
    {x=0, y=0, z=0, r=0, g=1, b=0}, -- C
    {x=0, y=1, z=0, r=0, g=1, b=0},
    {x=0, y=1, z=0, r=0, g=0, b=0}, -- blank

    -- Z
    {x=0, y=0, z=0, r=0, g=0, b=1}, -- C
    {x=0, y=0, z=1, r=0, g=0, b=1},
    {x=0, y=0, z=1, r=0, g=0, b=0}, -- blank
  }

  self.xaxis_verts = {
    {x= 0, y=0, z=0, r=0, g=0, b=0}, -- blank

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

    {x= 0, y=0, z=0, r=0, g=0, b=0}, -- blank
  }

  return true
end




function T3D:in_1_bang(sel, atoms)
  local eos = require("eos")
  local m4 = require("mat4")
  local v2 = require("vec2")
  local v3 = require("vec3")
  local clipper = require("clipper")
  local s3d = require("scene3d")
  -- self.lookat.x = self.cam_pos.x

  local scene = s3d.scene({
    self.xaxis_verts,
    -- self.axis_verts,
    self.cube_verts,
    self.triangle_verts
  })

  -- for i, point in ipairs(scene) do
  --   print(v2.tostring(point))
  -- end


  local points = m4.camera(
    -- self.xaxis_verts,
    scene,
    -- v3.scale(self.cam_pos, 100),
    v3.scale(self.cam_pos, 1),
    v3.scale(self.lookat, 1),
    self.up,
    -- math.rad(self.fov) * 2.3333,
    math.rad(self.fov),
    self.aspect_ratio,
    self.near_clip,
    self.far_clip)

    local clipped_points = clipper.frustum.nearfar(points, self.near_clip, self.far_clip)
  -- print("AFTER CAMERA")
  -- for _, point in ipairs(points) do
  --   print(v2.tostring(point))
  -- end

  -- print("BEFORE SCALE")
  -- for i, point in ipairs(points) do
  --   local point_scaled = v2.scale(point, 0.1)
  --   points[i].x = point_scaled.x
  --   points[i].y = point_scaled.y
  --   -- print(v2.tostring(points[i]))
  -- end
  -- print("AFTER SCALE")


  local out = eos.points_to_xyrgb(clipped_points)

  -- print("AFTER TO XYRGB")
  -- print("out: ", #out)

  out = clipper.rect.clip(out, {x=0,y=0,w=1.9,h=1.9})
  if #out == 0 then eos.addpoint(out, 0, 0, 0, 0, 0) end
  -- print("AFTER CLIP: out: ", #out)
  -- for i=1,#out do
  --   local p = eos.pointatindex(out, i)
  --   print(v2.tostring(p))
  -- end
  -- print("AFTER CLIP")

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end


function T3D:in_2(sel, atoms)
  -- print(string.format("T3D: receive %s: %s", sel, atoms[1]))
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
  end
end
