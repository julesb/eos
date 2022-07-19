local rotate = pd.Class:new():register("rotate")

function rotate:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 1
    self.angle = 0.0
    return true
end

function rotate:in_2_float(x)
    if type(x == "number") then
        self.angle = x
    end
end

function rotate:in_1_list(inp)
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
        local pnew = v2.rotate(p1, self.angle)
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

