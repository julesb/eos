local t1 = pd.Class:new():register("trigger1")

function t1:initialize(sel, atoms)
    self.inlets = 1
    self.outlets = 1
    self.name = "trigger1"
    self.framenumber = 0
    return true
end

function t1:in_1_bang()
    tp = require("triggerpool")
    local function update(dt)
        return { 0, 0, 1, 1, 1 }
    end
    tp.add(self.name, update, 5.0)

end
