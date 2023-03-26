local flocking = pd.Class:new():register("flocking")
local socket = require("socket")

function flocking:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.framerate = 30
    self.size = 3
    self.cohesion = 2.3
    self.separation = 3.2
    self.alignment = 1.5
    self.wander = 24.0
    self.wanderfreq = 1.5
    self.wandermag = 6.0
    self.walldetect = 0.2
    self.wallavoid = 0.5
    self.visualrange = 0.3
    self.agentfov = 90.0
    self.mindistance = 0.03
    self.maxforce = 1.6
    self.maxspeed = 0.4
    self.flock = require("flock")
    self.flock.init(
        self.size,
        self.cohesion,
        self.separation,
        self.alignment,
        self.wander,
        self.wanderfreq,
        self.wandermag,
        self.walldetect,
        self.wallavoid,
        self.visualrange,
        self.agentfov,
        self.mindistance,
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
    local v2 = require("vec2")
    local eos = require("eos")
    local out = {}
    local c
    for i=1,#agents do
        c = agents[i].col
        eos.addpoint(out, agents[i].pos.x, agents[i].pos.y, c.r, c.g, c.b)
    end
    return out
end

function flocking:in_2_init(i)
    self.flock.init(
        self.size,
        self.cohesion,
        self.separation,
        self.alignment,
        self.wander,
        self.wanderfreq,
        self.wandermag,
        self.walldetect,
        self.wallavoid,
        self.visualrange,
        self.agentfov,
        self.mindistance,
        self.maxforce,
        self.maxspeed
    )
end

function flocking:in_2(sel, atoms)
    if sel == "size" then
        self.flock.size = atoms[1]
        self.flock.agents = self.flock.initagents(self.flock.size)
    elseif sel == "visualrange" then self.flock.visualrange = atoms[1]
    elseif sel == "agentfov" then self.flock.agentfov = atoms[1]
    elseif sel == "mindistance" then self.flock.mindistance = atoms[1]
    elseif sel == "cohesion" then self.flock.cohesion = atoms[1]
    elseif sel == "alignment" then self.flock.alignment = atoms[1]
    elseif sel == "wander" then self.flock.wander = atoms[1]
    elseif sel == "wanderfreq" then self.flock.wanderfreq = atoms[1]
    elseif sel == "wandermag" then self.flock.wandermag = atoms[1]
    elseif sel == "separation" then self.flock.separation = atoms[1]
    elseif sel == "mindistance" then self.flock.mindistance = atoms[1]
    elseif sel == "walldetect" then self.flock.walldetect = atoms[1]
    elseif sel == "wallavoid" then self.flock.wallavoid = atoms[1]
    elseif sel == "maxforce" then self.flock.maxforce = atoms[1]
    elseif sel == "maxspeed" then self.flock.maxspeed = atoms[1]
    elseif sel == "optbeampath" then self.flock.optbeampath = atoms[1]
    elseif sel == centerattract then self.flock.centerattract = atoms[1]
    end
end
