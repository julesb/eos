local s3d = pd.Class:new():register("scale3d")

function s3d:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.scale = {
    x = 1.0,
    y = 1.0,
    z = 1.0
  }

  if #atoms == 1 then
    self.scale.x = atoms[1]
    self.scale.y = atoms[1]
    self.scale.z = atoms[1]
  elseif #atoms == 2 then
    self.scale.x = atoms[1]
    self.scale.y = atoms[2]
  elseif #atoms == 3 then
    self.scale.x = atoms[1]
    self.scale.y = atoms[2]
    self.scale.z = atoms[3]
  end
  return true
end


function s3d:in_1_list(inp)
  local eos = require("eos")
  local out = {}
  local npoints = #inp / 6
  local p

  for i=1, npoints do
    p = eos.pointatindex3d(inp, i)
    p.x = p.x * self.scale.x
    p.y = p.y * self.scale.y
    p.z = p.z * self.scale.z
    eos.addpoint3d(out, p)
  end
  self:outlet(2, "float", {#out/6})
  self:outlet(1, "list", out)
end


function s3d:in_2(sel, atoms)
  if sel == "scale" then
    self.scale.x = atoms[1]
    self.scale.y = atoms[1]
    self.scale.z = atoms[1]
  end
end

