
local camera = pd.Class:new():register("camera")

function camera:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.screenunit = 1.0 / 2047.0

  self.cam_pos = { x=0, y=0, z=-10 }
  self.lookat = { x=0, y=0, z=0 }
  self.up = {x=0, y=-1, z=0}
  self.aspect_ratio = 1.0
  self.fov = 60
  self.near_clip = 0.5
  self.far_clip = 100

  self.input_modes = {["2d"]=true, ["2D"]=true, ["3d"]=true, ["3D"]=true}
  self.input_mode = "3d"

  if self.input_modes[atoms[1]] then
    self.input_mode = string.lower(atoms[1])
  end

  G_CAMERA_POS = self.cam_pos
  return true
end


function camera:in_1_list(inp)
  local eos = require("eos")
  local m4 = require("mat4")
  local clipper = require("clipper")

  G_CAMERA_POS = self.cam_pos
  local inp3d = {}
  if self.input_mode == "2d" then
    -- XYRGB
    for i=1,#inp/5 do
      local p = eos.pointatindex(inp, i)
      p.z = 0
      table.insert(inp3d, p)
    end
  else
    -- XYZRGB
    for i=1,#inp/6 do
      table.insert(inp3d, eos.pointatindex3d(inp, i))
    end
  end

  local points = m4.camera(
    inp3d,
    self.cam_pos,
    self.lookat,
    self.up,
    math.rad(self.fov),
    self.aspect_ratio,
    self.near_clip,
    self.far_clip)

  -- local clipped_points = clipper.frustum.nearfar(points, self.near_clip, self.far_clip)
  -- local out = eos.points_to_xyrgb(clipped_points)
  local xyrgb = eos.points_to_xyrgb(points)
  local out = clipper.rect.clip(xyrgb, {x=0,y=0,w=1.999,h=1.999})
  if #out == 0 then eos.addpoint(out, 0, 0, 0, 0, 0) end

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end


function camera:in_2(sel, atoms)
  -- print(string.format("camera: receive %s: %s", sel, atoms[1]))
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
