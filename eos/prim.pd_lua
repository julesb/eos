local prim = pd.Class:new():register("prim")


function prim:initialize(sel, atoms)
    local pr = require("primitives")
    local eos = require("eos")
    self.screenunit = 1.0 / 2047.0
    self.inlets = 2
    self.outlets = 2
    self.prims = {
      box = true,
      axis3d = true
    }

    self.dim1 = 1
    self.dim2 = 1
    self.dim3 = 1
    self.points = {}
    self.points_xyzrgb = {}

    self.prim_type = "axis3d"

    if type(atoms[2]) == "number" then
      self.dim1 = atoms[2]
    end
    -- if type(atoms[3]) == "number" then
    --   self.dim2 = atoms[3]
    -- end
    -- if type(atoms[4]) == "number" then
    --   self.dim3 = atoms[4]
    -- end

    if self.prims[atoms[1]] ~= nil then
      self.prim_type = atoms[1]
      if self.prim_type == "box" then
        self.points = pr.cube(self.dim1)
        self.points_xyzrgb = eos.points_to_xyzrgb(self.points)
      end
    end

    -- default to axis
    if #self.points_xyzrgb == 0 then
      self.points = pr.axis3d(1)
      self.points_xyzrgb = eos.points_to_xyzrgb(self.points)
    end

    return true
end

function prim:in_1_bang()
   self:outlet(2, "float", { #self.points_xyzrgb / 6 })
  self:outlet(1, "list", self.points_xyzrgb)
end


