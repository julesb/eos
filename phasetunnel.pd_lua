local phasetunnel = pd.Class:new():register("phasetunnel")

function phasetunnel:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.name = "phasetunnel"
    -- self.lifespan = 2.0
    self.numcircles = 5
    -- self.radiusstep = 0.2
    self.maxradius = 1.0 --0.33
    self.pointdensity = 30.0
    self.framenumber = 0
    self.speed = 0.33

    if type(atoms[1]) == "number" then
        self.lifespan = atoms[1]
    end
    if type(atoms[2]) == "number" then
        self.pointdensity = atoms[2]
    end
    return true
end

function phasetunnel:in_2_density(d)
    if type(d[1]) == "number" and d[1] >= 1 then
        self.pointdensity = d[1]
    end
end
function phasetunnel:in_2_speed(s)
    if type(s[1]) == "number" and s[1] > 0 then
        self.speed = s[1]
    end
end
function phasetunnel:in_2_radiusstep(r)
    if type(r[1]) == "number" and r[1] > 0 then
        self.radiusstep = r[1]
    end
end

function phasetunnel:in_2_numcircles(n)
    if type(n[1]) == "number" and n[1] >= 1 then
        self.numcircles = math.floor(n[1])
    end
end

function phasetunnel:in_1_bang()
    self.framenumber = self.framenumber + 1
    local eos = require("eos")
    --local v2 = require("vec2")
    local out = {}
    local tframe = self.framenumber / 50.0 * self.speed
    -- tframe = tframe * self.expandrate
    local paths = {}
    local startp = {
        x = 1.0,
        y = 0.0,
        r = 1.0,
        g = 1.0,
        b = 1.0
    }
    for i = 0, self.numcircles -1 do
        local t = (tframe + i / self.numcircles) % 1.0
        --local t_exp = t
        local t_exp = math.pow(t, 1.0 - math.pow(t, 0.3))
        local radius = t_exp * self.maxradius
        local npoints = 16 + 2.0 * math.pi * radius * self.pointdensity 
        --local hue = i / self.numcircles
        local hue = tframe * 0.01
        if i % 2 == 0 then hue = hue + 0.5 end
        local col = eos.hsv2rgb(hue, 1, 1 - t)
        local angstep = 2.0 * math.pi / npoints
        local path = {}
        local px, py
        if radius < 0.1 then
            local centerpoint = eos.addpoint({}, 0, 0, 1, 1, 1, 32)
            table.insert(paths, centerpoint)
        end
        for s = 0, npoints do
            local cosr = math.cos(angstep * s)
            local sinr = math.sin(angstep * s)
            px = radius * (startp.x * cosr - startp.y * sinr)
            py = radius * (startp.y * cosr + startp.x * sinr)
            eos.addpoint(path, px, py, col.r, col.g, col.b)
        end
        local dwellnum = math.floor(npoints / 8.0)
        if dwellnum > 0 then
            eos.addpoint(path, path[1], path[2], path[3], path[4], path[5], dwellnum)
        end
        table.insert(paths, path) 
    end
    
    out = eos.composite(paths, 32, 10)
    self:outlet(2, "float", { #out / 5})
    self:outlet(1, "list", out)

    return out
end
