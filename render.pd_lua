local render = pd.Class:new():register("render")

function render:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047
    self.inlets = 2
    self.outlets = 2
    self.mode = "lines" 
    self.dwell = 8 
    self.subdivide = 32 
    self.preblank = 0
    self.postblank = 0
    if type(atoms[1] == "string") then
        if atoms[1] == "points" then
            self.mode = "points"
        elseif atoms[1] == "lines" then
            self.mode = "lines"
        end
    else
        self.mode = "lines"
    end
    pd.post(string.format("render:initialize(): render mode: %s", self.mode))
    if type(atoms[2]) == "number" then
        self.dwell = math.max(0, atoms[2])
        pd.post(string.format("render:initialize(): dwell: %s", self.dwell))
    end
    if type(atoms[3]) == "number" then
        self.subdivide = math.max(0, atoms[3])
        pd.post(string.format("render:initialize(): subdivide: %s", self.subdivide))
    end
    if type(atoms[4]) == "number" then
        self.preblank = math.max(0, atoms[4])
        pd.post(string.format("render:initialize(): preblank: %s", self.preblank))
    end

    return true
end

function render:in_2_mode(m)
    if type(m[1]) ==  "string" and (m[1] == "lines" or m[1] == "points") then
        self.mode = m[1]
    end
    pd.post(string.format("render: mode: %s", self.mode))
end

function render:in_2_dwell(d)
    if type(d[1]) ==  "number" then
        self.dwell = math.max(0, d[1])
    end
    pd.post(string.format("render: dwell: %s", self.dwell))
end

function render:in_2_subdivide(s)
    if type(s[1]) ==  "number" then
        self.subdivide = math.max(0, s[1])
    end
    pd.post(string.format("render: subdivide: %s", self.subdivide))
end

function render:in_2_preblank(p)
    if type(p[1]) ==  "number" then
        self.preblank = math.max(0, p[1])
    end
    pd.post(string.format("render: preblank: %s", self.preblank))
end

function render:in_2_postblank(p)
    if type(p[1]) ==  "number" then
        self.postblank = math.max(0, p[1])
    end
    pd.post(string.format("render: postblank: %s", self.postblank))
end

function render:in_1_list(inp)
    if type(inp) ~= "table" then
        self:error("render:in_1_list(): not a list")
        self:error(type(inp))
        return false
    end
    --pd.post(string.format("IN: %s", tostring(#inp)))
    local eos = require("eos")
    local v2 = require("vec2")
    local out = {}
    -- local idx = 1
    local npoints = #inp / 5
    local ldwell = self.dwell
    local lsubdivide = self.subdivide
    local r1, g1, b1
    for i=0, npoints - 1 do
        local iidx = i * 5 + 1
        local p1 = {
            x=inp[iidx],
            y=inp[iidx+1],
        }
        r1 = inp[iidx+2] * 255
        g1 = inp[iidx+3] * 255
        b1 = inp[iidx+4] * 255
        
        -- Preblank 
        eos.addpoint(out, p1.x * 2047, p1.y * 2047, 0, 0, 0, self.preblank)

        -- The point
        eos.addpoint(out, p1.x * 2047, p1.y * 2047, r1, g1, b1)

        -- Dwell points
        eos.addpoint(out, p1.x * 2047, p1.y * 2047, r1, g1, b1, ldwell)

        -- Subdivision
        if lsubdivide > 0 and npoints > 1 then
            local p2 = {
                x=inp[((i+1) % npoints) * 5 + 1],
                y=inp[((i+1) % npoints) * 5 + 2]
            }
            local tvec = v2.sub(p2, p1)
            local len = v2.len(tvec)
            local subdivide_su = lsubdivide * self.screenunit
            local nsteps = math.ceil(len / subdivide_su)
            local stepvec = v2.scale(tvec, 1.0 / nsteps)
            if self.mode == "points" then
                r1 = 0
                g1 = 0
                b1 = 0
            end

            for s=0,nsteps-1 do
                local pnew = v2.add(p1, v2.scale(stepvec, s))
                eos.addpoint(out, pnew.x * 2047, pnew.y * 2047, r1, g1, b1)
            end 
        end
    end
    --pd.post(string.format("OUT: %s", tostring(#out)))
    --print(string.format("OUT: %s", table.concat(out, ", ") ))
    self:outlet(2, "float", { #out / 5 })
    self:outlet(1, "list", out)
    -- return out
end

