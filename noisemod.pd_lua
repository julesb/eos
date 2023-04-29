local N = pd.Class:new():register("noisemod")

function N:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 1
    self.scalex = 1.0
    self.scaley = 1.0
    self.freqx = 1.0
    self.freqy = 1.0
    self.time = 0.0
    self.timestep = 1.0 / 30.0
    if #atoms > 0 then
        self.scalex = atoms[1]
        self.scaley = atoms[1]
    end
    if #atoms > 1 then
        self.scaley = atoms[2]
    end
    if #atoms > 2 then
        self.freqx = atoms[3]
    end
    if #atoms > 3 then
        self.freqy = atoms[4]
    end
    return true
end

function N:in_2(sel, atoms)
    if     sel == "scalex" then self.scalex = atoms[1]
    elseif sel == "scaley" then self.scaley = atoms[1]
    elseif sel == "freqx" then self.freqx = atoms[1]
    elseif sel == "freqy" then self.freqy = atoms[1]
    elseif sel == "timestep" then self.timestep = atoms[1]
    end
end


function N:in_1_list(inp)
    local eos = require("eos")
    local v2 = require("vec2")
    local simplex = require("simplex")
    local out = {}
    local npoints = #inp / 5
    local moisemode = 0
    for i=0, npoints - 1 do
        local iidx = i * 5 + 1
        local p1 = {
            x=inp[iidx],
            y=inp[iidx+1],
        }
        local r1 = inp[iidx+2]
        local g1 = inp[iidx+3]
        local b1 = inp[iidx+4]
        local xn, yn
        if self.scalex ~= 0.0 then
            if noisemode == 0 then
                xn = simplex.noise2d(123.461 + p1.y*self.freqx, self.time)
            else
                xn = simplex.noise2d(123.461 + self.time + p1.y*self.freqx, 0.0)
                   + simplex.noise2d(837.084 + self.time - p1.y*self.freqx, 0.0)
                xn = xn * 0.5
            end
            xn = xn * self.scalex
        else
            xn = 0.0
        end
        if self.scaley ~= 0.0 then
            if noisemode == 0 then
                yn = simplex.noise2d(123.461 + p1.x*self.freqy, self.time)
            else
                yn = simplex.noise2d(0.0, 321.345 + self.time + p1.x*self.freqy)
                   + simplex.noise2d(0.0, 913.559 + self.time - p1.x*self.freqy)
                yn = yn * 0.5
            end
            yn = yn * self.scaley
        else
            yn = 0
        end
        local pnew = v2.add(p1, v2.new(xn, yn))
        eos.addpoint(out, pnew.x, pnew.y, r1, g1, b1)
    end
    self.time = self.time + self.timestep * 0.1
    self:outlet(1, "list", out)
end

