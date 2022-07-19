local S = pd.Class:new():register("symmetry")

function S:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.symmetry = 1
    return true
end

function S:in_2_float(s)
    if type(s) == "number" and s > 0 then
        self.symmetry = s
    end
end

function S:in_1_list(inp)
    --local v2 = require("vec2")
    local out = {}
    local idx = 1
    local npoints = #inp / 5
    local ang_step = (2.0 * 3.1415926) / self.symmetry
    for i=0, npoints-1 do
        iidx = i * 5 + 1
        local p = {
            x = inp[iidx],
            y = inp[iidx+1],
            r = inp[iidx+2],
            g = inp[iidx+3],
            b = inp[iidx+4]
        }
        for s = 0,self.symmetry-1 do
            cosr = math.cos(ang_step * s)
            sinr = math.sin(ang_step * s)
            xr = p.x * cosr - p.y * sinr
            yr = p.y * cosr + p.x * sinr
            out[idx] = xr
            idx = idx + 1
            out[idx] = yr
            idx = idx + 1
            out[idx] = p.r
            idx = idx + 1
            out[idx] = p.g
            idx = idx + 1
            out[idx] = p.b
            idx = idx + 1
        end
    end
    self:outlet(2, "float", { #out  / 5})
    self:outlet(1, "list", out)
end
