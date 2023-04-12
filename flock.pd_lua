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
        friction = 0.01,
        worldXmin = -1.0,
        worldXmax = 1.0,
        worldYmin = -1.0,
        worldYmax = 1.0,
        colormode = 0,
        hueoffset = 0.0,
        gradcol1h = 0.0,
        gradcol1s = 1.0,
        gradcol1v = 1.0,
        gradcol2h = 1.0,
        gradcol2s = 1.0,
        gradcol2v = 1.0,
        optbeampath = 1
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
    elseif sel == "worldXmin" then
        self.flock.config.worldXmin = math.max(atoms[1], -1.0)
    elseif sel == "worldXmax" then
        self.flock.config.worldXmax = math.min(atoms[1], 1.0)
    elseif sel == "worldYmin" then
        self.flock.config.worldYmin = math.max(atoms[1], -1.0)
    elseif sel == "worldYmax" then
        self.flock.config.worldYmax = math.min(atoms[1], 1.0)
    elseif self.flock.defaultconfig[sel] ~= nil then
        self.flock.config[sel] = atoms[1]
    end
end
