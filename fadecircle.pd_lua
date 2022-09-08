local fadecircle = pd.Class:new():register("fadecircle")

function fadecircle:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 1
    self.name = "fadecircle"
    self.lifespan = 2.0
    self.maxradius = 0.33
    self.pointdensity = 50.0
    if type(atoms[1]) == "number" then
        self.lifespan = atoms[1]
    end
    if type(atoms[2]) == "number" then
        self.pointdensity = atoms[2]
    end
    return true
end

function fadecircle:in_2_float(d)
    if type(d) == "number" then
        self.pointdensity = math.floor(d)
    end
end

function fadecircle:in_1_bang()
    local tp = require("triggerpool")

    local function update(tr)
        local eos = require("eos")
        local v2 = require("vec2")
        if tr.init then
            local minc = -1 + self.maxradius
            tr.center = {
                x = minc + 2.0 * math.random() * (1.0 - self.maxradius),
                y = minc + 2.0 * math.random() * (1.0 - self.maxradius)
            }
            tr.hsv = { h=math.random(), s=1.0 , v=1.0}
            tr.init = false
        end
        local t = 1.0 - tr.life / tr.lifespan
        local t_exp = math.pow(t, 1.0 - math.pow(t, 0.3))
        local radius = t_exp * self.maxradius
        local npoints = 2.0 * math.pi * radius * self.pointdensity 
        local col = eos.hsv2rgb(tr.hsv.h, tr.hsv.s, 1 - t)
        local out = {}
        if npoints > 1 then
            local angstep = 2.0 * math.pi / npoints
            for s = 0, npoints do
                local cosr = math.cos(angstep * s)
                local sinr = math.sin(angstep * s)
                local p = {
                    x = 1.0,
                    y = 0.0,
                    r = 1.0,
                    g = 1.0,
                    b = 1.0
                }
                xr = tr.center.x + radius * (p.x * cosr - p.y * sinr)
                yr = tr.center.y + radius * (p.y * cosr + p.x * sinr)
                eos.addpoint(out, xr, yr, col.r, col.g, col.b)
            end
            local dwellnum = math.floor(npoints / 7.0)
            if dwellnum > 0 then
                eos.addpoint(out, out[1], out[2], out[3], out[4], out[5], dwellnum)
            end
        end
        return out
    end
    tp.add(self.name, update, self.lifespan)
end
