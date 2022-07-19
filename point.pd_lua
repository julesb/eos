local point = pd.Class:new():register("point")

function point:initialize(sel, atoms)
    self.screenunit = 1.0 / 2048.0
    self.inlets = 3
    self.outlets = 2
    self.position = {
        x = 0.0,
        y = 0.0
    }
    if type(atoms[1]) == "number" then
        self.position.x = atoms[1] * self.screenunit
    end
    if type(atoms[2]) == "number" then
        self.position.y = atoms[2] * self.screenunit
    end
 
    return true
end

function point:in_2_float(x)
    if type(x) == "number" then
        self.position.x = x * self.screenunit
    end
end

function point:in_3_float(y)
    if type(y) == "number" then
        self.position.y = y * self.screenunit
    end
end


function point:in_1_bang()
    local out = {}
    out[1] = self.position.x
    out[2] = self.position.y
    out[3] = 1 
    out[4] = 1 
    out[5] = 1 
    self:outlet(2, "float", { #out })
    self:outlet(1, "list", out)
end
