local noop = pd.Class:new():register("noop")

function noop:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 1
    self.outlets = 1
    return true
end

function noop:in_1_list(inp)
    self:outlet(1, "list", inp)
end
