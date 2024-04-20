
local E = pd.Class:new():register("embed3d")

-- TODO: choose embed plane with initialize arg - XY, XZ, YZ

function E:initialize(sel, atoms)
  self.inlets = 1
  self.outlets = 2
  return true
end


function E:in_1_list(inp)
  local eos = require("eos")
  local out = {}
  for i=1, #inp/5 do
    eos.addpoint3d(out, eos.pointatindex(inp, i))
  end

  self:outlet(2, "float", { #out / 6 })
  self:outlet(1, "list", out)
end
