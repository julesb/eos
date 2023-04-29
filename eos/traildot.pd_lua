local traildot = pd.Class:new():register("traildot")

local eos = require("eos")
local v2 = require("vec2")

function traildot:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 2
   self.npoints = 100
   self.aspectratio = 1.0
   self.time = 0.0
   self.x1freq = 1.0
   self.x1amp = 1.0
   self.x1phase = 0.0
   self.y1freq = 1.0
   self.y1amp = 1.0
   self.y1phase = 0.0
   self.trailstep = 0.01
   self.expand = 5
   self.headcol = { r=1, g=0.25, b=0 }
   self.trailcol = { r=0, g=0, b=1 }
   self.headrepeat = 1
   self.mirror = false

   self.headprev = v2.new(0, 0)
   return true
end


function traildot:in_1_bang()
    local simplex = require("simplex")
    local out = {}
    local t = self.time

    local arscalex, arscaley

    if self.aspectratio >= 1.0 then
        arscalex = self.aspectratio
        arscaley = 1
    else
        arscalex = 1
        arscaley = (1 / self.aspectratio)
    end

    local head = {
        x = arscalex * self.x1amp * simplex.noise2d(t*self.x1freq*arscaley + self.x1phase, 2311.323),
        y = arscaley * self.y1amp * simplex.noise2d(t*self.y1freq*arscalex + self.y1phase, 1234.567)
    }



    eos.addpoint(out, head.x, head.y, 0, 0, 0, 12)
    for j = 1, self.headrepeat do
        eos.addpoint(out, head.x, head.y, self.headcol.r, self.headcol.g, self.headcol.b, 2)
        eos.addpoint(out, self.headprev.x, self.headprev.y, self.headcol.r, self.headcol.g, self.headcol.b, 2)
    end
    self.headprev.x = head.x
    self.headprev.y = head.y

    local trailx, traily
    local fader, fadeg, fadeb

    for i=1,self.npoints do
        fader = self.trailcol.r * (1.0 - (i / self.npoints))
        fadeg = self.trailcol.g * (1.0 - (i / self.npoints))
        fadeb = self.trailcol.b * (1.0 - (i / self.npoints))
        t = t - self.trailstep
        trailx = arscalex * self.x1amp * simplex.noise2d(t*self.x1freq*arscaley + self.x1phase, 2311.323)
        traily = arscaley * self.y1amp * simplex.noise2d(t*self.y1freq*arscalex + self.y1phase, 1234.567)

        -- horizontal scroll
        -- trailx = trailx + eos.screenunit * i * 80

        -- polar "scroll"
        trailx = trailx + eos.screenunit * i * trailx * self.expand
        traily = traily + eos.screenunit * i * traily * self.expand

        eos.addpoint(out, trailx, traily, fader, fadeg, fadeb)
    end
    

    eos.addpoint(out, trailx, traily, 0, 0, 0, 1)
    
    -- symmetry
    if self.mirror then
        local npts = #out
        for i = 1, npts, 5 do
            eos.addpoint(out, out[i]*-1, out[i+1]*-1, out[i+2], out[i+3], out[i+4])
        end
    end

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
    elseif sel == "headcolor" then self.headcol = eos.hsv2rgb(atoms[1], 1, 1)
    elseif sel == "trailcolor" then self.trailcol = eos.hsv2rgb(atoms[1], 1, 1)
    elseif sel == "headrepeat" then self.headrepeat = math.max(atoms[1], 0)
    elseif sel == "aspectratio" then self.aspectratio = math.max(atoms[1], 0.2)
    elseif sel == "mirror" then self.mirror = (atoms[1] ~= 0)
    end
end

