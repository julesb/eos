local R = pd.Class:new():register("rotaxis")
local eos = require("eos")
local v3 = require("vec3")

function R:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.axis = {
    x = 0.0,
    y = 0.0,
    z = 1.0
  }
  self.axes = {
    X = {x=1, y=0, z=0},
    Y = {x=0, y=1, z=0},
    Z = {x=0, y=0, z=1}
  }
  self.angle = 0.0

  if #atoms == 2 and type(atoms[1]) == "string" and self.axes[atoms[1]] ~= nil then
    -- two args: axis_name, angleaaa
    self.axis = self.axes[atoms[1]]
    if type(atoms[2]) == "number" then
      self.angle = math.rad(atoms[2])
    end
  elseif #atoms == 4
  and type(atoms[1]) == "number"
  and type(atoms[2]) == "number"
  and type(atoms[3]) == "number"
  and type(atoms[4]) == "number" then
    -- four args: Ax AY Az, angle
    self.axis.x = atoms[1]
    self.axis.y = atoms[2]
    self.axis.z = atoms[3]
    self.axis = v3.normalize(self.axis)
    self.angle  = math.rad(atoms[4])
  end
  print(string.format("rotaxis: axis=%s, angle=%f",
                      v3.tostring(self.axis), self.angle))
  return true
end


function R:in_1_list(inp)
  local m4 = require("mat4")
  local out = {}
  local npoints = #inp / 6
  local p, pr
  local m = m4.rotate(self.angle, v3.normalize(self.axis))

  for i=1, npoints do
    p = eos.pointatindex3d(inp, i)
    pr = m4.transform(p, m)
    pr.r = p.r
    pr.g = p.g
    pr.b = p.b
    eos.addpoint3d(out, pr)
  end
  self:outlet(2, "float", {#out/6})
  self:outlet(1, "list", out)
end


function R:in_2(sel, atoms)
  if sel == "angle" then
    self.angle = math.rad(atoms[1])
  end
end

