local color = pd.Class:new():register("color")

function color:initialize(sel, atoms)
    self.inlets = 4
    self.outlets = 1
    self.mode = "rgb" -- rgb, hsv, name
    self.rgb = {r=1, g=0, b=0}
    self.hsv = {h=0, s=1, v=1}
    self.blankcolor = {r=0, g=0,b=0}
    self.namedcolors = {
        black =   {r=0, g=0, b=0},
        grey =    {r=0.5, g=0.5, b=0.5},
        red =     {r=1, g=0, b=0},
        orange =  {r=1, g=0.647, b=0},
        yellow =  {r=1, g=1, b=0},
        green =   {r=0, g=1, b=0},
        cyan =    {r=0, g=1, b=1},
        blue =    {r=0, g=0, b=1},
        purple =  {r=0.5, g=0, b=0.5},
        violet =  {r=0.541, g=0.168, b=0.886},
        magenta = {r=1, g=0, b=1},
        white =   {r=1, g=1, b=1}
    }

    if type(atoms[1]) == "string" then
        if atoms[1] == "hsv" then self.mode = "hsv"
        elseif atoms[1] == "rgb" then self.mode = "rgb"
        else
            if self.namedcolors[atoms[1]] ~= nil then
                self.mode = "rgb"
                self.rgb = self.namedcolors[atoms[1]]
            else
                pd.post("ERROR: unknown mode or color: ", atoms[1])
                return false
            end
        end
    end
    if type(atoms[2]) == "number" then
        if self.mode == "rgb" then self.rgb.r = atoms[2]
        elseif self.mode == "hsv" then self.hsv.h = atoms[2]
        end
    end
    if type(atoms[3]) == "number" then
        if self.mode == "rgb" then self.rgb.g = atoms[3]
        elseif self.mode == "hsv" then self.hsv.s = atoms[3]
        end
    end
    if type(atoms[4]) == "number" then
        if self.mode == "rgb" then self.rgb.b = atoms[4]
        elseif self.mode == "hsv" then self.hsv.v = atoms[4]
        end
    end

--      print(string.format("color: [%.1f, %.1f, %.1f] blankcolor: [%.1f, %.1f, %.1f]",
--                          self.color.r, self.color.g, self.color.b,
--                          self.blankcolor.r, self.blankcolor.g, self.blankcolor.b))
    return true
end

function color:in_2_float(c)
    if self.mode == "rgb" then self.rgb.r = c
    elseif self.mode == "hsv" then self.hsv.h = c
    end
end
function color:in_3_float(c)
    if self.mode == "rgb" then self.rgb.g = c
    elseif self.mode == "hsv" then self.hsv.s = c
    end
end
function color:in_4_float(c)
    if self.mode == "rgb" then self.rgb.b = c
    elseif self.mode == "hsv" then self.hsv.v = c
    end
end

function color:in_1_list(inp)
    local eos = require("eos")
    local out = {}
    local npoints = #inp / 5
    for i=0, npoints - 1 do
        local iidx = i * 5 + 1
        local x = inp[iidx]
        local y = inp[iidx+1]
        local incol = {
            r = inp[iidx+2],
            g = inp[iidx+3],
            b = inp[iidx+4]
        }
        local outcol
        if eos.isblank(incol) then
            outcol = self.blankcolor
        else
            if self.mode == "hsv" then
                outcol = eos.hsv2rgb(self.hsv.h, self.hsv.s, self.hsv.v)
            else
                outcol = self.rgb
            end
        end

        eos.addpoint(out, x, y, outcol.r, outcol.g, outcol.b)
    end
    self:outlet(1, "list", out)
end

