local rangemap = pd.Class:new():register("rangemap")

function rangemap:initialize(sel, atoms)
    self.inlets = 7
    self.outlets = 1
    self.minr = 0.0
    self.maxr = 1.0
    self.ming = 0.0
    self.maxg = 1.0
    self.minb = 0.0
    self.maxb = 1.0
 
    if type(atoms[1]) == "number" then
        self.minr = atoms[1]
    end
    if type(atoms[2]) == "number" then
        self.maxr = atoms[2]
    end
    if type(atoms[3]) == "number" then
        self.ming = atoms[3]
    end
    if type(atoms[4]) == "number" then
        self.maxg = atoms[4]
    end
    if type(atoms[5]) == "number" then
        self.minb = atoms[5]
    end
    if type(atoms[6]) == "number" then
        self.maxb = atoms[6]
    end
    return true
end

function rangemap:in_2_float(x)
    if type(x == "number") then
        self.minr = math.max(0.0, x)
    end
end
function rangemap:in_3_float(x)
    if type(x == "number") then
        self.maxr = math.max(0.0, x)
    end
end
function rangemap:in_4_float(x)
    if type(x == "number") then
        self.ming = math.max(0.0, x)
    end
end
function rangemap:in_5_float(x)
    if type(x == "number") then
        self.maxg = math.max(0.0, x)
    end
end
function rangemap:in_6_float(x)
    if type(x == "number") then
        self.minb = math.max(0.0, x)
    end
end
function rangemap:in_7_float(x)
    if type(x == "number") then
        self.maxb = math.max(0.0, x)
    end
end

function rangemap:in_1_list(inp)
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
        local outcol = eos.colorramp(incol, self.minr, self.maxr, self.ming, self.maxg, self.minb, self.maxb)
        eos.addpoint(out, x, y, outcol.r, outcol.g, outcol.b)
    end
    self:outlet(1, "list", out)
end

