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
    self.color = {
        r = 1,
        g = 1,
        b = 1
    }
    self.blankcolor = {x=0.0,y=0.0,z=0.0}
    if type(atoms[1]) == "string" then
        if self.colors[atoms[1]] ~= nil then
            self.color = self.colors[atoms[1]]
        end
    end
    if type(atoms[2]) == "string" then
        if self.colors[atoms[1]] ~= nil then
            self.blankcolor = self.colors[atoms[1]]
        end
    end
    print(string.format("color: %s, %s, %s", self.color.r, self.color.g, self.color.b))
    return true
end


function color:in_1_list(inp)
    local v2 = require("vec2")
    local out = {}
    local idx = 1
    local npoints = #inp / 5
    local colunit = 1.0 / 255
    for i=0, npoints - 1 do
        local iidx = i * 5 + 1
        local x1 = inp[iidx]
        local y1 = inp[iidx+1]
        local r1 = inp[iidx+2]
        local g1 = inp[iidx+3]
        local b1 = inp[iidx+4]
        out[idx] = x1
        idx = idx + 1
        out[idx] = y1
        idx = idx + 1
        if r1 >= colunit or g1 >= colunit or b1 >= colunit then
            out[idx] = self.color.r
            idx = idx + 1
            out[idx] = self.color.g
            idx = idx + 1
            out[idx] = self.color.b
            idx = idx + 1
        else
            out[idx] = self.blankcolor.r
            idx = idx + 1
            out[idx] = self.blankcolor.g
            idx = idx + 1
            out[idx] = self.blankcolor.b
            idx = idx + 1
        end
    end
    self:outlet(1, "list", out)
end

