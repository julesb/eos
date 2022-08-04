local poly = pd.Class:new():register("polygon")

function poly:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 4
    self.outlets = 2
    self.stride = 1
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
    if type(atoms[3] == "number") then
        self.stride = atoms[3]
    else
        self.stride = 1
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
        self.radius = (r/100) -- * self.screenunit
    end
end

function poly:in_4_float(s)
    if type(s) == "number" then
        self.stride = math.floor(s)
    end
end

function poly:in_1_bang()
    local eos = require("eos")
    local out = {}
    local idx = 1
    local ang_step = (2.0 * math.pi) / self.nsides * self.stride
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
            eos.addpoint(out, xr, yr, p.r, p.g, p.b)
        end
    else
        eos.addpoint(out, 0, 0, 1, 1, 1)
    end
    self:outlet(2, "float", { #out })
    self:outlet(1, "list", out)
end
