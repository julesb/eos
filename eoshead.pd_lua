local eoshead = pd.Class:new():register("eoshead")


function eoshead:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.open = false
    return true
end


function eoshead:in_1_bang()
    if self.open then
        self:outlet(2, "bang", {})
    end
    self:outlet(1, "bang", {})
end

function eoshead:in_2_float(t)
    if t == 0 then self.open = false else self.open = true end
end

