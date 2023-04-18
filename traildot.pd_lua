local traildot = pd.Class:new():register("traildot")

function traildot:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 2
   self.npoints = 100
   self.time = 0.0

   self.x1freq = 1.0
   self.x1amp = 1.0
   self.x1phase = 0.0

   self.y1freq = 1.0
   self.y1amp = 1.0
   self.y1phase = 0.0
   self.trailstep = 0.01
   self.expand = 5
   self.headcol = { r=1, g=1, b=0 }
   self.trailcol = { r=0, g=0, b=1 }

   return true
end

function traildot:in_1_bang()
    local eos = require("eos")
    local simplex = require("simplex")
    local v2 = require("vec2")
    local out = {}
    local t = self.time

    local head = {
        x = self.x1amp * simplex.noise2d(t*self.x1freq + self.x1phase, 2311.323),
        y = self.y1amp * simplex.noise2d(t*self.y1freq + self.y1phase, 1234.567)
    }
    eos.addpoint(out, head.x, head.y, self.headcol.r, self.headcol.g, self.headcol.b, 16)

    local trailx, traily
    local fader, fadeg, fadeb 

    for i=1,self.npoints do
        fader = self.trailcol.r * (1.0 - (i / self.npoints))
        fadeg = self.trailcol.g * (1.0 - (i / self.npoints))
        fadeb = self.trailcol.b * (1.0 - (i / self.npoints))
        t = t - self.trailstep
        trailx = self.x1amp * simplex.noise2d(t*self.x1freq + self.x1phase, 2311.323)
        traily = self.y1amp * simplex.noise2d(t*self.y1freq + self.y1phase, 1234.567)

        -- h scroll
        -- trailx = trailx + eos.screenunit * i * 80

        -- polar "scroll"
        local dir = v2.normalize(v2.new(trailx, traily))
        trailx = trailx + eos.screenunit * i * dir.x * self.expand
        traily = traily + eos.screenunit * i * dir.y * self.expand

        eos.addpoint(out, trailx, traily, fader, fadeg, fadeb)
    end
    
    eos.addpoint(out, trailx, traily, 0, 0, 0, 1)


    -- loop back to first point
    --eos.addpoint(out, out[1], out[2], 0, 0, 0, 12)

    self.time = self.time + 1.0 / 50.0
    self:outlet(2, "float", { #out / 5})
    self:outlet(1, "list", out)
end

function traildot:in_2_npoints(x)
    if x[1] >= 10 then
        self.npoints = x[1]
        self:outlet(2, "float", {self.npoints})
    end
end

function traildot:in_2(sel, atoms)
    if     sel == "x1freq"  then self.x1freq  = atoms[1]
    elseif sel == "x1amp"   then self.x1amp   = atoms[1]
    elseif sel == "x1phase" then self.x1phase = atoms[1] * math.pi * 2
    elseif sel == "y1freq"  then self.y1freq  = atoms[1]
    elseif sel == "y1amp"   then self.y1amp   = atoms[1]
    elseif sel == "y1phase" then self.y1phase = atoms[1] * math.pi * 2
    elseif sel == "time"    then self.time    = atoms[1]
    elseif sel == "trailstep" then self.trailstep = atoms[1]
    elseif sel == "expand" then self.expand = atoms[1]
    end
end

