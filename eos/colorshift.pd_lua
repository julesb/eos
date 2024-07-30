local colorshift = pd.Class:new():register("colorshift")

function colorshift:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047
    self.inlets = 2
    self.outlets = 1
    self.offset = 0
    if type(atoms[1]) == "number" then
        self.offset = math.modf(atoms[1]) -- modf trick to round towards 0
    end
    return true
end

function colorshift:in_2_float(x)
    if type(x == "number") then
        self.offset = math.modf(x)  -- modf trick to round towards 0
    end
end

function colorshift:in_1_list(inp)
  local e = require("eos")
  local out = {}

  if self.offset == 0 then
    out = inp
  else
    local p, shift_p
    local npoints = #inp / 5
    for i=1, npoints do
      p = e.pointatindex(inp, i)
      shift_p = e.pointatindex(inp, math.max(1, math.min(npoints, i+self.offset)))
      p.r = shift_p.r
      p.g = shift_p.g
      p.b = shift_p.b
      e.addpoint2(out, p)
    end

  end

  self:outlet(1, "list", out)
end

