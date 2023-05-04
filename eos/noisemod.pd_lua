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
    self.mapmode = 0 -- 0 = point index, 1 = point coordinate

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
    elseif sel == "mapmode" then self.mapmode = atoms[1]
    end
end


function N:in_1_list(inp)
    local eos = require("eos")
    local v2 = require("vec2")
    local simplex = require("simplex")
    local out = {}
    local npoints = #inp / 5
    local noiseoffset = 123.461 -- const
    local indexscale = 1.0 / 1500.0 -- const

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
        local noisecoord
        if self.scalex ~= 0.0 then
            if self.mapmode == 0 then
                noisecoord = noiseoffset + i*indexscale * self.freqx
            else
                noisecoord = noiseoffset + p1.y * self.freqx
            end
            xn = self.scalex * simplex.noise2d(noisecoord, self.time)
        else
            xn = 0.0
        end
        if self.scaley ~= 0.0 then
            if self.mapmode == 0 then
                noisecoord = noiseoffset + i*indexscale * self.freqy
            else
                noisecoord = noiseoffset + p1.x * self.freqy
            end
            yn = self.scaley * simplex.noise2d(noisecoord, self.time)
        else
            yn = 0
        end
        local pnew = v2.add(p1, v2.new(xn, yn))
        eos.addpoint(out, pnew.x, pnew.y, r1, g1, b1)
    end
    self.time = self.time + self.timestep * 0.1
    self:outlet(1, "list", out)
end

