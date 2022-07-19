local CS = pd.Class:new():register("colorscan")

function CS:initialize(sel, atoms)
    self.screenunit = 1.0 / 2048.0
    self.inlets = 2
    self.outlets = 2
    self.numpoints = 200
    self.rmod = 4
    self.gmod = 3
    self.bmod = 2
    self.framenumber = 0
    if type(atoms[1] == "number") then
        self.numpoints = atoms[1]
    end
 
    return true
end

function CS:in_2_npoints(s)
    pd.post(type(s[1]))
    if type(s[1]) == "number" and s[1] > 0 then
        self.numpoints = s[1]
        pd.post(string.format("colorscan: npoints: %d", self.numpoints))
    end
end
function CS:in_2_rmod(s)
    if type(s[1]) == "number" and s[1] > 0 then
        self.rmod = s[1]
    end
end
function CS:in_2_gmod(s)
    if type(s[1]) == "number" and s[1] > 0 then
        self.gmod = s[1]
    end
end
function CS:in_2_bmod(s)
    if type(s[1]) == "number" and s[1] > 0 then
        self.bmod = s[1]
    end
end

function CS:in_1_bang()
    local out = {}
    self.framenumber = self.framenumber + 1
    local idx = 1
    local step = 2.0 / self.numpoints
    if self.numpoints > 1 then
        for s = 1, self.numpoints do
            local r,g,b
            local p = {
                x = -1.0 + step * (s - 1),
                y = 0.0,
            }
            if (s+self.framenumber) % self.rmod == 0 then r=1 else r=0 end
            if (s+self.framenumber) % self.gmod == 0 then g=1 else g=0 end
            if (s+self.framenumber) % self.bmod == 0 then b=1 else b=0 end
            out[idx] = p.x
            idx = idx + 1
            out[idx] = p.y
            idx = idx + 1
            out[idx] = r
            idx = idx + 1
            out[idx] = g
            idx = idx + 1
            out[idx] = b
            idx = idx + 1
        end
        for s = self.numpoints, 1, -1 do
            local r,g,b
            local p = {
                x = -1.0 + step * (s - 1),
                y = 0.0,
            }
            if (s+self.framenumber) % self.rmod == 0 then r=1 else r=0 end
            if (s+self.framenumber) % self.gmod == 0 then g=1 else g=0 end
            if (s+self.framenumber) % self.bmod == 0 then b=1 else b=0 end
            out[idx] = p.x
            idx = idx + 1
            out[idx] = p.y
            idx = idx + 1
            out[idx] = r
            idx = idx + 1
            out[idx] = g
            idx = idx + 1
            out[idx] = b
            idx = idx + 1
        end
    end
    self:outlet(2, "float", { #out })
    self:outlet(1, "list", out)
end
