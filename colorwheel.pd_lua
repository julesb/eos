local colorwheel = pd.Class:new():register("colorwheel")

function colorwheel:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 4
    self.outlets = 2
    self.hue_offset = 0.0
    if type(atoms[1] == "number") then
        self.nsides = atoms[1]
    else
        self.nsides = 50 
    end
    if type(atoms[2] == "number") then
        self.radius = atoms[2] / 100 -- * self.screenunit
    else
        self.radius = 512 * self.screenunit
    end
    return true
end

function colorwheel:in_2_float(s)
    if type(s) == "number" and s > 0 then
        self.nsides = s
    end
end

function colorwheel:in_3_float(r)
    if type(r) == "number" then
        self.radius = r / 100 -- * self.screenunit
    end
end
function colorwheel:in_4_float(o)
    if type(o) == "number" then
        self.hue_offset = o
    end
end

function colorwheel:in_1_bang()
    local eos = require("eos")
    local out = {}
    local idx = 1
    local ang_step = (2.0 * math.pi) / self.nsides
    local xr, yr
    local hue = 0

    if self.nsides > 1 then
        local p = {
            x = 1.0,
            y = 0.0,
            r = 1.0,
            g = 0.0,
            b = 0.0
        }
        for s = 0, self.nsides do
            local cosr = math.cos(ang_step * s)
            local sinr = math.sin(ang_step * s)
            local basehue = s / self.nsides
            local hue = ((basehue+self.hue_offset)
                      - math.floor(basehue+self.hue_offset))
            local col = eos.hsv2rgb(hue, 1.0, 1.0)
            xr = self.radius * (p.x * cosr - p.y * sinr)
            yr = self.radius * (p.y * cosr + p.x * sinr)
            eos.addpoint(out, xr, yr, col.r, col.g, col.b)
        end
        -- back to first point and dwell
        local initcol = eos.hsv2rgb(0+self.hue_offset, 1, 1)
        eos.addpoint(out, p.x * self.radius, p.y * self.radius, initcol.r, initcol.g, initcol.b, 10)
    else
        eos.addpoint(out, 0, 0, 1, 0, 0)
    end
    self:outlet(2, "float", { #out/5 })
    self:outlet(1, "list", out)
end
