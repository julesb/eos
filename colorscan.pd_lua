local CS = pd.Class:new():register("colorscan")

function CS:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 2
    self.outlets = 2
    self.numpoints = 200
    self.rfreq = 20.0
    self.gfreq = 30.0
    self.bfreq = 2.5
    self.rphase = -0.25
    self.gphase = 0.4
    self.bphase = -0.1
    self.framenumber = 0
    if type(atoms[1] == "number") then
        self.numpoints = atoms[1]
    end
 
    return true
end

function CS:in_2_npoints(s)
    pd.post(type(s[1]))
    if type(s[1]) == "number" and s[1] > 0 then
        self.numpoints = s[1]
        pd.post(string.format("colorscan: npoints: %d", self.numpoints))
    end
end
function CS:in_2_rfreq(f)
    if type(f[1]) == "number" then
        self.rfreq = f[1]
    end
end
function CS:in_2_gfreq(f)
    if type(f[1]) == "number" then
        self.gfreq = f[1]
    end
end
function CS:in_2_bfreq(f)
    if type(f[1]) == "number" then
        self.bfreq = f[1]
    end
end
function CS:in_2_rphase(p)
    if type(p[1]) == "number" then
        self.rphase = p[1]
    end
end
function CS:in_2_gphase(p)
    if type(p[1]) == "number" then
        self.gphase = p[1]
    end
end
function CS:in_2_bphase(p)
    if type(p[1]) == "number" then
        self.bphase = p[1]
    end
end


function CS:in_1_bang()
    eos = require("eos")
    local out = {}
    self.framenumber = self.framenumber + 1
    local step = 2.0 / self.numpoints
    local colorunit = 1.0 / 255.0
    local p, r, g, b

    local function wave(time, f, p)
        return 0.5 + 0.5 * math.sin(time * f * (math.pi * 2) + p)
    end

    if self.numpoints > 1 then
        for s = 1, self.numpoints do
            p = {
                x = -1.0 + step * (s - 1),
                y = 0.0,
            }
            local t = s / self.numpoints
            r = wave(t, self.rfreq, self.rphase * self.framenumber)
            g = wave(t, self.gfreq, self.gphase * self.framenumber)
            b = wave(t, self.bfreq, self.bphase * self.framenumber)
            eos.addpoint(out, p.x, p.y, r, g, b)
        end
        for s = self.numpoints, 1, -1 do
            local r,g,b
            local p = {
                x = -1.0 + step * (s - 1),
                y = 0.0,
            }
            local t = s / self.numpoints
            r = wave(t, self.rfreq, self.rphase * self.framenumber)
            g = wave(t, self.gfreq, self.gphase * self.framenumber)
            b = wave(t, self.bfreq, self.bphase * self.framenumber)
            eos.addpoint(out, p.x, p.y, r, g, b)
        end
    end
    self:outlet(2, "float", { #out })
    self:outlet(1, "list", out)
end
