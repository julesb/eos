local flock = {}
local v2 = require("vec2")

function flock.init(size, c, s, a, w, ca, range, maxforce, maxspeed)
    flock.size = size
    flock.cohesion = c
    flock.separation = s
    flock.alignment = a
    flock.wallavoid = w
    flock.centerattract = ca
    flock.range = range
    flock.maxforce = maxforce
    flock.maxspeed = maxspeed
    flock.agents = flock.initagents(size)
end


function flock.initagents(size)
    local agents = {}
    for i = 1,size do
        agents[i] = flock.new(i, v2.rand())
    end
    return agents
end

function flock.new(id, pos)
    return {
        id = id,
        pos = {x=pos.x, y=pos.y},
        vel = {x=0.0, y=0.0},
        acc = {x=0.0, y=0.0}
    }
end


function flock.update(dt)
    for i,agent in ipairs(flock.agents) do
        local newacc = flock.computebehaviors(agent)
        agent.acc = newacc
    end

    for i,agent in ipairs(flock.agents) do
        agent.vel = v2.add(agent.vel, v2.scale(agent.acc, dt))
        agent.vel = v2.limit(agent.vel, flock.maxspeed)
        agent.pos = v2.add(agent.pos, v2.scale(agent.vel, dt))
    end
end

function flock.computebehaviors(agent)
    local coh = {x=0.0, y=0.0}
    local sep = {x=0.0, y=0.0}
    local ali = {x=0.0, y=0.0}
    local wall = {x=0.0, y=0.0}
    local totalacc = {x=0.0, y=0.0}  
    local count = 0
    for i,other in ipairs(flock.agents) do
        if other ~= agent then
            local dist = v2.dist(agent.pos, other.pos)
            if dist < flock.range then
                local diff = v2.sub(agent.pos, other.pos)
                sep = v2.add(sep, diff)
                ali = v2.add(ali, other.vel)
                coh = v2.add(coh, other.pos)
                count = count + 1
            end
        end
    end

    -- Wall avoidance
    local walldetect = flock.wallavoid
    local ldisc, rdist, tdist, bdist
    ldist = v2.dist(v2.new(-1.0, agent.pos.y), agent.pos)
    if ldist < walldetect then wall = v2.add(wall, v2.new(walldetect / ldist - 1.0, 0.0)) end

    rdist = v2.dist(v2.new(1.0, agent.pos.y), agent.pos)
    if rdist < walldetect then wall = v2.sub(wall, v2.new(walldetect / rdist - 1.0, 0.0)) end

    tdist = v2.dist(v2.new(agent.pos.x, 1.0), agent.pos)
    if tdist < walldetect then wall = v2.sub(wall, v2.new(0.0, walldetect / tdist - 1.0)) end
    
    bdist = v2.dist(v2.new(agent.pos.x, -1.0), agent.pos)
    if bdist < walldetect then wall = v2.add(wall, v2.new(0.0, walldetect / bdist - 1.0)) end

    wall = v2.scale(wall, flock.wallavoid)
    
    local cdist = v2.dist(v2.new(0.0, 0.0), agent.pos)
    local centerattract = v2.scale(v2.normalize(agent.pos), -flock.centerattract * cdist*cdist)

    if count > 0 then
        local sc = 1.0 / count
        coh = v2.scale(coh, sc)
        coh = v2.scale(coh, flock.cohesion)
        ali = v2.scale(ali, sc)
        ali = v2.scale(ali, flock.alignment)
        sep = v2.scale(sep, sc)
        sel = v2.scale(sep, flock.separation)
    end

    totalacc = v2.add(totalacc, coh)
    totalacc = v2.add(totalacc, sep)
    totalacc = v2.add(totalacc, ali)
    totalacc = v2.add(totalacc, wall)
    totalacc = v2.add(totalacc, centerattract)
    return totalacc
end


function flock.agenttostring(a)
    return string.format("id: %02d\tpos: %s\tvel: %s\tacc: %s",
            a.id,
            v2.tostring(a.pos),
            v2.tostring(a.vel),
            v2.tostring(a.acc)
            )
end

return flock
