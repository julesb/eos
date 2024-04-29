
local E = pd.Class:new():register("embed3d")

-- TODO: choose embed plane with initialize arg - XY, XZ, YZ

function E:initialize(sel, atoms)
  self.inlets = 1
  self.outlets = 2

  self.valid_planes = {
    XY = true,
    XZ = true,
    YZ = true
  }
  self.plane = "XY"

  if self.valid_planes[atoms[1]] then
    self.plane = atoms[1]
    print("plane:", self.plane)
  end

  return true
end


function E:in_1_list(inp)
  local eos = require("eos")
  local out = {}
  local p
  if self.plane == "XZ" then
    for i=1, #inp/5 do
      p = eos.pointatindex(inp, i)
      eos.addpoint3d(out, {x=p.x, y=0, z=p.y, r=p.r, g=p.g, b=p.b})
    end
  elseif self.plane == "XY" then
    for i=1, #inp/5 do
      p = eos.pointatindex(inp, i)
      eos.addpoint3d(out, {x=p.x, y=p.y, z=0, r=p.r, g=p.g, b=p.b})
    end
  elseif self.plane == "YZ" then
    for i=1, #inp/5 do
      p = eos.pointatindex(inp, i)
      eos.addpoint3d(out, {x=0, y=p.x, z=p.y, r=p.r, g=p.g, b=p.b})
    end
  end

  self:outlet(2, "float", { #out / 6 })
  self:outlet(1, "list", out)
end
