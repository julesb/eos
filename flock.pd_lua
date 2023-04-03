local flock = pd.Class:new():register("flock")
local socket = require("socket")

function flock:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.framerate = 30

    self.config = {
        size = 3,
        cohesion = 2.3,
        separation = 3.2,
        alignment = 1.5,
        wander = 24.0,
        wanderfreq = 1.5,
        wandermag = 6.0,
        walldetect = 0.2,
        wallavoid = 0.5,
        visualrange = 0.3,
        agentfov = 90.0,
        mindistance = 0.03,
        maxforce = 1.6,
        maxspeed = 0.4,
        friction = 0.01
    }
    self.flock = require("flock")
    self.flock.init(self.config)
    return true
end



function flock:in_1_bang()
    local t_prev = t or 0.0
    local t = socket.gettime()
    local dt = t - t_prev
    if dt > 1.0 then dt = 1.0 / self.framerate end
    self.flock.update(dt)
    local xyrgb = flock:to_xyrgb(self.flock.agents)
    self:outlet(2, "float", { #xyrgb / 5 })
    self:outlet(1, "list", xyrgb)
end


function flock:to_xyrgb(agents)
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

function flock:in_2_init(i)
    self.flock.init(self.config)
end

function flock:in_2(sel, atoms)
    if sel == "size" then
        self.flock.config.size = atoms[1]
        self.flock.agents = self.flock.initagents(self.flock.config.size)
    elseif sel == "visualrange" then self.flock.config.visualrange = atoms[1]
    elseif sel == "agentfov" then self.flock.config.agentfov = atoms[1]
    elseif sel == "mindistance" then self.flock.config.mindistance = atoms[1]
    elseif sel == "cohesion" then self.flock.config.cohesion = atoms[1]
    elseif sel == "alignment" then self.flock.config.alignment = atoms[1]
    elseif sel == "wander" then self.flock.config.wander = atoms[1]
    elseif sel == "wanderfreq" then self.flock.config.wanderfreq = atoms[1]
    elseif sel == "wandermag" then self.flock.config.wandermag = atoms[1]
    elseif sel == "separation" then self.flock.config.separation = atoms[1]
    elseif sel == "mindistance" then self.flock.config.mindistance = atoms[1]
    elseif sel == "walldetect" then self.flock.config.walldetect = atoms[1]
    elseif sel == "wallavoid" then self.flock.config.wallavoid = atoms[1]
    elseif sel == "maxforce" then self.flock.config.maxforce = atoms[1]
    elseif sel == "maxspeed" then self.flock.config.maxspeed = atoms[1]
    elseif sel == "friction" then self.flock.config.friction = atoms[1]
    elseif sel == "optbeampath" then self.flock.optbeampath = atoms[1]
    end
end
