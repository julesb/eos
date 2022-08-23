local gradients = pd.Class:new():register("gradients")

function gradients:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 2
    self.outlets = 2
    self.npoints = 256
    self.vspace = 512 
    if type(atoms[1] == "number") then
        self.npoints = atoms[1]
    end
    return true
end

function gradients:in_2_float(n)
    if type(n) == "number" and n > 0 then
        self.npoints = n
    end
end


function gradients:in_1_bang()
    local eos = require("eos")
    local out = {}
    local x, y, c
    local xstep = 2.0 / self.npoints
    y = (0 - self.vspace * 1.5) * self.screenunit

    -- Red gradient
    eos.addpoint(out, -1, y, 0, 0, 0, 8)
    for i=0, self.npoints-1 do
        c = i / (self.npoints-1)
        x = -1.0 + i * xstep
        eos.addpoint(out, x, y, c, 0, 0)
    end
    eos.addpoint(out, x, y, c, 0, 0, 8)
    eos.addpoint(out, x, y, 0, 0, 0, 8)

    -- Green gradient
    y = (0 - self.vspace * 0.5) * self.screenunit
    for i=0, self.npoints-1 do
        c = i / (self.npoints-1)
        x = -1.0 + i * xstep
        eos.addpoint(out, x, y, 0, c, 0)
    end
    eos.addpoint(out, x, y, 0, c, 0, 8)
    eos.addpoint(out, x, y, 0, 0, 0)
    
    -- Blue gradient
    y = (0 + self.vspace * 0.5) * self.screenunit
    for i=0, self.npoints-1 do
        c = i / (self.npoints-1)
        x = -1.0 + i * xstep
        eos.addpoint(out, x, y, 0, 0, c)
    end
    eos.addpoint(out, x, y, 0, 0, c, 8)
    eos.addpoint(out, x, y, 0, 0, 0)

    -- Hue gradient
    y = (0 + self.vspace * 1.5) * self.screenunit
    eos.addpoint(out, -1, y, 0, 0, 0, 8)
    for i=0, self.npoints-1 do
        local hue = i / (self.npoints-1)
        c = eos.hsv2rgb(hue, 1, 1)
        x = -1.0 + i * xstep
        eos.addpoint(out, x, y, c.r, c.g, c.b)
    end
    eos.addpoint(out, x, y, c.r, c.g, c.b, 8)
    eos.addpoint(out, x, y, 0, 0, 0)

    self:outlet(2, "list", { #out/5 })
    self:outlet(1, "list", out)
end

