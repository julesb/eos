local translate = pd.Class:new():register("translate")

function translate:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047
    self.inlets = 3
    self.outlets = 1
    self.offset = {
        x = 0.0,
        y = 0.0
    }
    if type(atoms[1]) == "number" then
        self.offset.x = atoms[1] * self.screenunit
    end
    if type(atoms[2]) == "number" then
        self.offset.y = atoms[2] * self.screenunit
    end
    return true
end

function translate:in_2_float(x)
    if type(x == "number") then
        self.offset.x = x * self.screenunit
    end
end

function translate:in_3_float(y)
    if type(y == "number") then
        self.offset.y = y * self.screenunit
    end
end

function translate:in_1_list(inp)
    local v2 = require("vec2")
    local out = {}
    local idx = 1
    local npoints = #inp / 5
    for i=0, npoints - 1 do
        local iidx = i * 5 + 1
        local p1 = {
            x=inp[iidx],
            y=inp[iidx+1],
        }
        local r1 = inp[iidx+2]
        local g1 = inp[iidx+3]
        local b1 = inp[iidx+4]
        local pnew = v2.add(p1, self.offset)
        out[idx] = pnew.x
        idx = idx + 1
        out[idx] = pnew.y
        idx = idx + 1
        out[idx] = r1
        idx = idx + 1
        out[idx] = g1
        idx = idx + 1
        out[idx] = b1
        idx = idx + 1
    end
    self:outlet(1, "list", out)
end

