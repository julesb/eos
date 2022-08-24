local CC = pd.Class:new():register("colorcurves")

function CC:initialize(sel, atoms)
    self.inlets = 1
    self.outlets = 1
    self.aname_r = nil
    self.aname_g = nil
    self.aname_b = nil

    if type(atoms[1]) == "string" then
        self.aname_r = atoms[1]
        print("red curve array:", self.aname_r)
    end
    if type(atoms[2]) == "string" then
        self.aname_g = atoms[2]
        print("green curve array:", self.aname_g)
    end
    if type(atoms[3]) == "string" then
        self.aname_b = atoms[3]
        print("blue curve array:", self.aname_b)
    end
    return true
end

function CC:in_1_list(inp)
    local eos = require("eos")
    local out = {}
    local npoints = #inp / 5
    local rcurve, gcurve, bcurve

    if self.aname_r ~= nil then
        rcurve = pd.Table:new():sync(self.aname_r)
    end
    if self.aname_g ~= nil then
        gcurve = pd.Table:new():sync(self.aname_g)
    end
    if self.aname_b ~= nil then
        bcurve = pd.Table:new():sync(self.aname_b)
    end


    for i=0, npoints - 1 do
        local iidx = i * 5 + 1
        local x = inp[iidx]
        local y = inp[iidx+1]
        local incol = {
            r = inp[iidx+2],
            g = inp[iidx+3],
            b = inp[iidx+4]
        }
        local outcol = { r=incol.r, g=incol.g, b=incol.b }
        if rcurve ~= nil then
            local idx = math.min(math.max(incol.r * 255, 0), 255)
            outcol.r = rcurve:get(idx)
        end
        if gcurve ~= nil then
            local idx = math.min(math.max(incol.g * 255, 0), 255)
            outcol.g = gcurve:get(idx)
        end
        if bcurve ~= nil then
            local idx = math.min(math.max(incol.b * 255, 0), 255)
            outcol.b = bcurve:get(idx)
        end
        -- TODO
        eos.addpoint(out, x, y, outcol.r, outcol.g, outcol.b)
    end
    self:outlet(1, "list", out)
end

