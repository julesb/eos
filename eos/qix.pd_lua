local qix = pd.Class:new():register("qix")

function qix:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 2
   self.npoints = 1
   self.tau = 2 * math.pi

   self.x1freq = 1.0
   self.x1amp = 0.5
   self.x1phase = 0.0

   self.y1freq = 1.0
   self.y1amp = 0.5
   self.y1phase = 0.25

   self.x2freq = 1.0
   self.x2amp = 0.5
   self.x2phase = 0.0

   self.y2freq = 1.0
   self.y2amp = 0.5
   self.y2phase = 0.25
   self.col = { r=1, g=1, b=1}

   self.framenumber = 0
   return true
end

function qix:in_1_bang()
    local eos = require("eos")
    local simplex = require("simplex")
    local out = {}
    local tstep = 1.0 / 60.0
    local t = self.framenumber * tstep
    for i=0, self.npoints-1 do

        local t2 = t + tstep * i
        local x1 = self.x1amp * simplex.noise2d((t2+121.204)
                 * self.x1freq + self.x1phase, 0)
        local y1 = self.y1amp * simplex.noise2d((t2+327.833)
                 * self.y1freq + self.y1phase, 0)
        local x2 = self.x2amp * simplex.noise2d((t2+230.091)
                 * self.x2freq + self.x2phase, 0)
        local y2 = self.y2amp * simplex.noise2d((t2+501.992)
                 * self.y2freq + self.y2phase, 0)

--         local x1 = self.x1amp * math.sin(t2 * self.x1freq * self.tau + self.x1phase)
--         local x2 = self.x2amp * math.sin(t2 * self.x2freq * self.tau + self.x2phase)
--         local y1 = self.y1amp * math.sin(t2 * self.y1freq * self.tau + self.y1phase)
--         local y2 = self.y2amp * math.sin(t2 * self.y2freq * self.tau + self.y2phase)

        if i % 2 == 0 then
          eos.addpoint(out, x1, y1, 0, 0, 0, 4)
          eos.addpoint(out, x1, y1, self.col.r, self.col.g, self.col.b, 4)
          eos.addpoint(out, x2, y2, self.col.r, self.col.g, self.col.b, 4)
          eos.addpoint(out, x2, y2, 0, 0, 0, 4)
        else
          eos.addpoint(out, x2, y2, 0, 0, 0, 4)
          eos.addpoint(out, x2, y2, self.col.r, self.col.g, self.col.b, 4)
          eos.addpoint(out, x1, y1, self.col.r, self.col.g, self.col.b, 4)
          eos.addpoint(out, x1, y1, 0, 0, 0, 4)
        end
    end
    -- loop back to first point
    --eos.addpoint(out, out[1], out[2], out[3], out[4], out[5], 12)
    self.framenumber = self.framenumber + 1
    self:outlet(2, "float", { #out / 5})
    self:outlet(1, "list", out)
end

function qix:in_2_npoints(x)
    if x[1] >= 0 then
        self.npoints = x[1]
        self:outlet(2, "float", {self.npoints})
    end
end

function qix:in_2(sel, atoms)
    if     sel == "x1freq"  then self.x1freq  = atoms[1]
    elseif sel == "x1amp"   then self.x1amp   = atoms[1]
    elseif sel == "x1phase" then self.x1phase = atoms[1] * math.pi * 2
    elseif sel == "x2freq"  then self.x2freq  = atoms[1]
    elseif sel == "x2amp"   then self.x2amp   = atoms[1]
    elseif sel == "x2phase" then self.x2phase = atoms[1] * math.pi * 2
    elseif sel == "y1freq"  then self.y1freq  = atoms[1]
    elseif sel == "y1amp"   then self.y1amp   = atoms[1]
    elseif sel == "y1phase" then self.y1phase = atoms[1] * math.pi * 2
    elseif sel == "y2freq"  then self.y2freq  = atoms[1]
    elseif sel == "y2amp"   then self.y2amp   = atoms[1]
    elseif sel == "y2phase" then self.y2phase = atoms[1] * math.pi * 2
    end
end

