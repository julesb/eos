local gradient = pd.Class:new():register("gradient")

function gradient:initialize(sel, atoms)
    self.inlets = 3
    self.outlets = 2
    self.hsv1 = { 0, 1, 1 }
    self.hsv2 = { 1, 1, 1 }

    if type(atoms[1]) == "number" then
        self.hsv1.h = atoms[1]
    end
    if type(atoms[2]) == "number" then
        self.hsv2.h = atoms[2]
    end
    return true
end

function gradient:in_2_float(c)
    self.hsv1.h = c
end
function gradient:in_3_float(c)
    self.hsv2.h = c
end

function gradient:in_1_list(inp)
    local eos = require("eos")
    local out = {}
    local npoints = #inp / 5
    local huestep = (2.0 / npoints)
    local x, y, t, hue, incol, outcol
    for i=0, npoints - 1 do
        local iidx = i * 5 + 1
        x = inp[iidx]
        y = inp[iidx+1]
        incol = {
            r = inp[iidx+2],
            g = inp[iidx+3],
            b = inp[iidx+4]
        }
        if i < npoints/2 then
            t = i / npoints
        else
            t = (1.0 - i / npoints)
        end
        hue = self.hsv1.h + t * (self.hsv2.h - self.hsv1.h) 
        if eos.isblank(incol) then
            outcol = incol
        else
            if t > 0.5 then
                outcol = eos.hsv2rgb(hue, 1, 1 )

            else
                outcol = eos.hsv2rgb(1-hue, 1, 1)
            end
        end

        eos.addpoint(out, x, y, outcol.r, outcol.g, outcol.b)
    end
    self:outlet(1, "list", out)
end
