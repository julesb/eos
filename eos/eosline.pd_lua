local eosline = pd.Class:new():register("eosline")
local eos = require("eos")

function eosline:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.p1 = { x=-1, y=0, r=1, g=1, b=1 }
    self.p2 = { x=-1, y=0, r=1, g=1, b=1 }
    self.npoints = 0

    if type(atoms[1]) == "number" then self.p1.x = atoms[1] * eos.screenunit end
    if type(atoms[2]) == "number" then self.p1.y = atoms[1] * eos.screenunit end
    if type(atoms[3]) == "number" then self.p2.x = atoms[1] * eos.screenunit end
    if type(atoms[4]) == "number" then self.p2.y = atoms[1] * eos.screenunit end
    if type(atoms[5]) == "number" then self.npoints = atoms[1] end
 
    return true
end

function eosline:in_2(sel, atoms)
    if sel == "npoints" then
        self.npoints = atoms[1]
    end
end

function eosline:in2_list(l)
    if #l == 4 then
        self.p1.x = l[1]
        self.p1.y = l[2]
        self.p2.x = l[3]
        self.p2.y = l[4]
    end
end

function eosline:in_1_bang()
    local v2 = require("vec2")
    local out = {}
    eos.addpoint(out, p1.x, p1.y, 1, 1, 1)
    if self.npoints > 0 then
        local subdiv = v2.dist(p1, p2) / self.npoints
        eos.subdivide(out, p1, p2, subdiv, "lines") 
    end
    eos.addpoint(out, p2.x, p2.y, 1, 1, 1)
    self:outlet(2, "float", { #out })
    self:outlet(1, "list", out)
end
