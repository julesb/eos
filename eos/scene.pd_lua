
local S = pd.Class:new():register("scene")


function S:initialize(sel, atoms)
  self.screenunit = 1.0 / 2047.0
  self.inlets = 2
  self.outlets = 2
  self.paths = {} -- TODO: not really paths

  return true
end

function S:in_1_bang()
  local eos = require("eos")
  local out = {}
  local p
  for pidx=1,#self.paths do
    local path = self.paths[pidx]
    for i=1, #path/6 do
      p = eos.pointatindex3d(path, i)
      eos.addpoint3d(out, p)
    end
    eos.addpoint3d(out, {x=p.x, y=p.y, z=p.z, r=0, g=0, b=0})
  end

  self:outlet(2, "float", { #out / 6 })
  self:outlet(1, "list", out)
  self.paths = {}
end


function S:in_2_list(inp)
  table.insert(self.paths, inp)
end
