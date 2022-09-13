local CS = pd.Class:new():register("colorscan")

function CS:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 2
    self.outlets = 2
    self.numpoints = 200
    self.rfreq = 20.0
    self.gfreq = 30.0
    self.bfreq = 2.5
    self.ramp = 1.0
    self.gamp = 1.0
    self.bamp = 1.0
    self.rphase = -0.25
    self.gphase = 0.4
    self.bphase = -0.1
    self.sqrthresh = 0.0
    self.framenumber = 0
    self.mode = 0 -- 0=sine, 1=square
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
function CS:in_2_ramp(x)
    if type(x[1]) == "number" then
        self.ramp = x[1]
    end
end
function CS:in_2_gamp(x)
    if type(x[1]) == "number" then
        self.gamp = x[1]
    end
end
function CS:in_2_bamp(x)
    if type(x[1]) == "number" then
        self.bamp = x[1]
    end
end
function CS:in_2_thresh(x)
    if type(x[1]) == "number" then
        self.sqrthresh = x[1]
    end
end
function CS:in_2_mode(p)
    if type(p[1]) == "number" and p[1] == 0 or p[1] == 1 then
        self.mode = p[1]
    end
end


function CS:in_1_bang()
    eos = require("eos")
    local out = {}
    self.framenumber = self.framenumber + 1
    local step = 2.0 / self.numpoints
    local colorunit = 1.0 / 255.0
    local p, r, g, b
    local wave

    local function sinewave(time, f, p)
        return 0.5 + 0.5 * math.sin(time * f * (math.pi * 2) + p)
    end

    local function sqrwave(time, f, p)
        local w = math.sin(time * f * (math.pi * 2) + p) >= self.sqrthresh
        if w then return 1 else return 0 end
    end

    if self.mode == 0 then
        wave = sinewave
    else
        wave = sqrwave
    end
    if self.numpoints > 1 then
        for s = 1, self.numpoints do
            p = {
                x = -1.0 + step * (s - 1),
                y = 0.0,
            }
            local t = s / self.numpoints
            r = self.ramp * wave(t, self.rfreq, self.rphase * self.framenumber)
            g = self.gamp * wave(t, self.gfreq, self.gphase * self.framenumber)
            b = self.bamp * wave(t, self.bfreq, self.bphase * self.framenumber)
            eos.addpoint(out, p.x, p.y, r, g, b)
        end

        self.framenumber = self.framenumber + 1
        for s = self.numpoints, 1, -1 do
            local r,g,b
            local p = {
                x = -1.0 + step * (s - 1),
                y = 0.0,
            }
            local t = s / self.numpoints
            r = self.ramp * wave(t, self.rfreq, self.rphase * self.framenumber)
            g = self.gamp * wave(t, self.gfreq, self.gphase * self.framenumber)
            b = self.bamp * wave(t, self.bfreq, self.bphase * self.framenumber)
            eos.addpoint(out, p.x, p.y, r, g, b)
        end
    end
    self:outlet(2, "float", { #out })
    self:outlet(1, "list", out)
end
