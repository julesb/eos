local t2 = pd.Class:new():register("trigger2")

function t2:initialize(sel, atoms)
    self.inlets = 1
    self.outlets = 1
    self.name = "trigger2"
    self.framenumber = 0
    return true
end

function t2:in_1_bang()
    tp = require("triggerpool")
    local function update(dt)
        -- TODO
        return { 0, 0, 1, 1, 1 }
    end
    tp.add(self.name, update, 5.0)
end
