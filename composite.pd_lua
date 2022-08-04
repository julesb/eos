local C = pd.Class:new():register("composite")


function C:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 2
    self.outlets = 2
    self.subdivide = 32 
    self.preblank = 10
    self.paths = {}
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
    local v2 = require("vec2")
    local npaths = #self.paths
    local out = {}
    local idx = 1

    for i=1,npaths do
        local path = self.paths[i]
        local plen = #path
        if plen < 1 then
            break
        end

        local nextpathidx = self:wrapidx(i+1, npaths)
        local nextpath = self.paths[nextpathidx]
        
        -- Preblank 
        eos.addpoint(out, path[1], path[2], 0, 0, 0, self.preblank)

        for j=1,plen do
            table.insert(out, path[j])
        end

        -- p1 = last point in current path
        local p1idx = plen - 4
        local p1 = {
            x=path[p1idx],
            y=path[p1idx+1],
            r=path[p1idx+2],
            g=path[p1idx+3],
            b=path[p1idx+4],
        }
        -- p2 = first point in the next path
        local p2 = {
            x=nextpath[1],
            y=nextpath[2]
        }

        -- post dwell color - so we dont blank too early
        -- eos.addpoint(out, p1.x, p1.y, p1.r, p1.g, p1.b, 12)

        local tvec = v2.sub(p2, p1)
        local len = v2.len(tvec)
        local nsteps = math.ceil(len / (self.subdivide * self.screenunit))
        local stepvec = v2.scale(tvec, 1.0 / nsteps)
        for s=0,nsteps-1 do
            pnew = v2.add(p1, v2.scale(stepvec, s))
            eos.addpoint(out, pnew.x, pnew.y, 0, 0, 0)
        end
    end
    self:outlet(2, "list", { #out / 5 })
    self:outlet(1, "list", out)
    self.paths = {}
end

function C:in_2_list(inp)
    local npaths = #self.paths
    newpathidx = npaths + 1
    self.paths[newpathidx] = {}
    for i=1,#inp do
        self.paths[newpathidx][i] = inp[i]
    end
end
