local color = pd.Class:new():register("color")

function color:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 1
    self.colors = {
        black =   {r=0, g=0, b=0},
        red =     {r=1, g=0, b=0},
        yellow =  {r=1, g=1, b=0},
        green =   {r=0, g=1, b=0},
        cyan =    {r=0, g=1, b=1},
        blue =    {r=0, g=0, b=1},
        magenta = {r=1, g=0, b=1},
        white =   {r=1, g=1, b=1}
    }
    self.color = {r=1, g=1, b=1}
    self.blankcolor = {r=0, g=0,b=0}
    if type(atoms[1]) == "string" then
        if self.colors[atoms[1]] ~= nil then
            self.color = self.colors[atoms[1]]
        end
    end
    if type(atoms[2]) == "string" then
        if self.colors[atoms[1]] ~= nil then
            self.blankcolor = self.colors[atoms[2]]
        end
    end
    print(string.format("color: [%.1f, %.1f, %.1f] blankcolor: [%.1f, %.1f, %.1f]",
                        self.color.r, self.color.g, self.color.b,
                        self.blankcolor.r, self.blankcolor.g, self.blankcolor.b))
    return true
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
        if incol.r == 0 and incol.g == 0 and incol.b == 0 then
            outcol = self.blankcolor
        else
            outcol = self.color
        end

        eos.addpoint(out, x, y, outcol.r, outcol.g, outcol.b)
    end
    self:outlet(1, "list", out)
end

