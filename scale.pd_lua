local scale = pd.Class:new():register("scale")

function scale:initialize(sel, atoms)
    self.inlets = 3
    self.outlets = 1
    self.scale = {
        x = 1.0,
        y = 1.0,
        r = 1.0,
        g = 1.0,
        b = 1.0
    }
    if #atoms > 0 then
        self.scale.x = atoms[1]
        self.scale.y = atoms[1]
    end
    if #atoms > 1 then
        self.scale.y = atoms[2]
    end
    if #atoms > 2 then
        self.scale.r = atoms[3]
    end
    if #atoms > 3 then
        self.scale.g = atoms[4]
    end
    if #atoms > 4 then
        self.scale.b = atoms[5]
    end
    -- pd.post(string.format("scale: [%s, %d, %d, %d, %d]",
    --        self.scale.x, self.scale.y, self.scale.r, self.scale.g, self.scale.b))
    return true
end

function scale:in_2_float(x)
    if type(x == "number") then
        self.scale.x = x
    end
end

function scale:in_3_float(y)
    if type(y == "number") then
        self.scale.y = y
    end
end

function scale:in_1_list(inp)
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
        local r1 = inp[iidx+2] * self.scale.r
        local g1 = inp[iidx+3] * self.scale.g
        local b1 = inp[iidx+4] * self.scale.b
        local pnew = v2.mul(p1, self.scale)
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

