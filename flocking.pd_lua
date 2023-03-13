local flocking = pd.Class:new():register("flocking")
local socket = require("socket")

function flocking:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.framerate = 30
    self.size = 10
    self.cohesion = 0.1
    self.separation = 1.5
    self.alignment = 0.5
    self.wallavoid = 0.5
    self.centerattract = 1.0
    self.range = 0.5
    self.maxforce = 0.1 
    self.maxspeed = 0.3 
    self.flock = require("flock")
    self.flock.init(
        self.size,
        self.cohesion,
        self.separation,
        self.alignment,
        self.wallavoid,
        self.centerattract,
        self.range,
        self.maxforce,
        self.maxspeed
    )
    return true
end



 function flocking:in_1_bang()
    local t_prev = t or 0.0
    local t = socket.gettime()
    local dt = t - t_prev
    if dt > 1.0 then dt = 1.0 / self.framerate end
    self.flock.update(dt)
    local xyrgb = flocking:to_xyrgb(self.flock.agents)
    self:outlet(2, "float", { #xyrgb / 5 })
    self:outlet(1, "list", xyrgb)
 end


function flocking:to_xyrgb(agents)
    local out = {}
    local idx = 1
    local v2 = require("vec2")
    local r, g, b
    for i=1,#agents do
        r = 0
        g = 0
        b = 1
        out[idx] = agents[i].pos.x
        idx = idx + 1
        out[idx] = agents[i].pos.y
        idx = idx + 1
        out[idx] = r
        idx = idx + 1
        out[idx] = g
        idx = idx + 1
        out[idx] = b
        idx = idx + 1
    end
    return out
end

function flocking:in_2_init(i)
    self.flock.init(
        self.size,
        self.cohesion,
        self.separation,
        self.alignment,
        self.wallavoid,
        self.centerattract,
        self.range,
        self.maxforce,
        self.maxspeed
    )
end

function flocking:in_2(sel, atoms)
    if sel == "size" then self.flock.size = atoms[1]
    elseif sel == "range" then self.flock.range = atoms[1]
    elseif sel == "cohesion" then self.flock.cohesion = atoms[1]
    elseif sel == "alignment" then self.flock.alignment = atoms[1]
    elseif sel == "separation" then self.flock.separation = atoms[1]
    elseif sel == "wallavoid" then self.flock.wallavoid = atoms[1]
    elseif sel == "maxforce" then self.flock.maxforce = atoms[1]
    elseif sel == "maxspeed" then self.flock.maxspeed = atoms[1]
    elseif sel == centerattract then self.flock.centerattract = atoms[1]
    end
end
