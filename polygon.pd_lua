local poly = pd.Class:new():register("polygon")

function poly:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 3
    self.outlets = 2
    if type(atoms[1] == "number") then
        self.nsides = atoms[1]
    else
        self.nsides = 3
    end
    if type(atoms[2] == "number") then
        self.radius = atoms[2] * self.screenunit
    else
        self.radius = 512 * self.screenunit
    end
 
    return true
end

function poly:in_2_float(s)
    if type(s) == "number" and s > 0 then
        self.nsides = s
    end
end

function poly:in_3_float(r)
    if type(r) == "number" then
        self.radius = r * self.screenunit
    end
end

function poly:in_1_bang()
    local out = {}
    local idx = 1
    local ang_step = (2.0 * 3.1415926) / self.nsides
    local xr, yr
    if self.nsides > 1 then
        for s = 0, self.nsides do
            local cosr = math.cos(ang_step * s)
            local sinr = math.sin(ang_step * s)
            local p = {
                x = 1.0,
                y = 0.0,
                r = 1.0,
                g = 1.0,
                b = 1.0
            }
            xr = self.radius * (p.x * cosr - p.y * sinr)
            yr = self.radius * (p.y * cosr + p.x * sinr)
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
    else
        out[idx] = 0
        out[idx+1] = 0
        out[idx+2] = 1
        out[idx+3] = 1
        out[idx+4] = 1
    end
    self:outlet(2, "float", { #out })
    self:outlet(1, "list", out)
end
