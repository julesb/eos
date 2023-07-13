local C = pd.Class:new():register("composite")


function C:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 2
    self.outlets = 2
    self.subdivide = 32 
    self.preblank = 10
    self.paths = {}
    self.prevframeexitpos = { x=0, y=0 }

    if type(atoms[1]) == "number" then
        self.subdivide = atoms[1]
    end
    if type(atoms[2]) == "number" then
        self.preblank = atoms[2]
    end
    return true
end

function C:in_2_preblank(p)
    if type(p[1]) ==  "number" then
        self.preblank = math.max(0, p[1])
    end
    pd.post(string.format("composite: preblank: %s", self.preblank))
end

function C:in_2_subdivide(s)
    if type(s[1]) ==  "number" then
        self.subdivide = math.max(0, s[1])
    end
    pd.post(string.format("composite: subdivide: %s", self.subdivide))
end

function C:wrapidx(idx, div)
    return ((idx-1) % div) + 1
end

function C:in_1_bang()
    local eos = require("eos")
    local out = eos.composite(self.paths, self.subdivide, self.preblank, self.prevframeexitpos)

    if #out >= 5 then
      self.prevframeexitpos = {
        x = out[#out-4],
        y = out[#out-3],
        r = 0,
        g = 0,
        b = 0
      }
    end

    self:outlet(2, "float", { #out / 5 })
    self:outlet(1, "list", out)
    self.paths = {}
end

function C:in_2_list(inp)
    local npaths = #self.paths
    local newpathidx = npaths + 1
    self.paths[newpathidx] = {}
    for i=1,#inp do
        self.paths[newpathidx][i] = inp[i]
    end
end
