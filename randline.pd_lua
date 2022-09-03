local randline = pd.Class:new():register("randline")

function randline:initialize(sel, atoms)
    self.inlets = 1
    self.outlets = 1
    self.name = "randline"
    self.lifespan = 5.0
    return true
end

function randline:in_1_bang()
    local tp = require("triggerpool")
    local function update(tr)
        local eos = require("eos")
        local v2 = require("vec2")
        if tr.init then
            tr.p1 = eos.randompos()
            tr.p2 = eos.randompos()
            tr.hsv = { h=math.random(), s=1.0 , v=1.0}
            tr.init = false
        end
        local t = 1.0 - tr.life / tr.lifespan
        local t_exp = math.pow(t, 1.0 - math.pow(t, 0.3))
        local midp = v2.scale(v2.add(tr.p1, tr.p2), 0.5)
        local step1 = v2.sub((tr.p1), midp)
        local step2 = v2.sub((tr.p2), midp)
        local p12 = v2.add(midp, v2.scale(step1, t_exp))    
        local p22 = v2.add(midp, v2.scale(step2, t_exp))
        local col = eos.hsv2rgb(tr.hsv.h, tr.hsv.s, 1 - t)
        local dot = eos.hsv2rgb(tr.hsv.h+0.5, tr.hsv.s, 1 - t/2)
        local out = {}
        p12.r = col.r
        p12.g = col.g
        p12.b = col.b
        p22.r = col.r
        p22.g = col.g
        p22.b = col.b
        --eos.addpoint(out, p12.x, p12.y, col.r, col.g, col.b, 8)
        eos.addpoint(out, p12.x, p12.y, dot.r, dot.g, dot.b, 8)
        eos.subdivide(out, p12, p22, 32)
        eos.addpoint(out, p22.x, p22.y, col.r, col.g, col.b, 8)
        eos.addpoint(out, p22.x, p22.y, dot.r, dot.g, dot.b, 8)
        return out
    end
    tp.add(self.name, update, self.lifespan)
end
