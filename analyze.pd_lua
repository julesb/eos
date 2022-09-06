local analyze = pd.Class:new():register("analyze")

function analyze:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047
    self.inlets = 2
    self.outlets = 4
    self.enabled = true

    return true
end

function analyze:in_2_float(e)
    if type(e[1]) ==  "number" and e[1] == 0 then
        self.enabled = false
    else
        self.enabled = true
    end
    pd.post(string.format("analyze:: enabled: %s", self.enabled))
end


function analyze:in_1_list(inp)
    if type(inp) ~= "table" then
        self:error("render:in_1_list(): not a list")
        self:error(type(inp))
        return false
    end
    local eos = require("eos")
    -- local v2 = require("vec2")
    -- local out = {}
    local npoints = #inp / 5
    local blankcount = 0
    local colorcount = 0
    -- local ldwell = self.dwell
    -- local lsubdivide = self.subdivide
    -- local r1, g1, b1
    local i = 0
    for i=0, npoints - 1 do
    -- while (i < npoints) do
        local iidx = i * 5 + 1
        local p1 = {
            x=inp[iidx],
            y=inp[iidx+1],
            r = inp[iidx+2],
            g = inp[iidx+3],
            b = inp[iidx+4]
        }
        if eos.isblank(p1) then
            blankcount = blankcount + 1
        else
            colorcount = colorcount + 1
        end

        --if not eos.isblank(p1) then
--             local dwellnum = eos.getdwellnum(iidx, inp)
--                 pd.post(string.format("[%d]: %s\tdwell=%d",
--                         i, v2.tostring(p1), dwellnum))
--             if dwellnum == 0 then
--                 i = i + 1
--             else
--                 i = i + dwellnum
--             end
--         --end
    end
    self:outlet(4, "float", { npoints })
    self:outlet(3, "float", { colorcount })
    self:outlet(2, "float", { blankcount })
    self:outlet(1, "list", inp)
end

