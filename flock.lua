local flock = {}
local v2 = require("vec2")

function flock.init(size, c, s, a,
                    walldetect, wallavoid, visualrange,
                    mindistance, maxforce, maxspeed)
    flock.size = size
    flock.cohesion = c
    flock.separation = s
    flock.alignment = a
    flock.walldetect = walldetect
    flock.wallavoid = wallavoid
    flock.visualrange = visualrange
    flock.mindistance = mindistance
    flock.maxforce = maxforce
    flock.maxspeed = maxspeed
    flock.agents = flock.initagents(size)
    flock.optbeampath = 0
end


function flock.initagents(size)
    local agents = {}
    for i = 1,size do
        agents[i] = flock.new(i, v2.rand())
    end
    return agents
end

function flock.new(id, pos)
    local eos = require("eos")
    local h = 2.0 * flock.size / id

    return {
        id = id,
        pos = {x=pos.x, y=pos.y},
        vel = {x=0.0, y=0.0},
        acc = {x=0.0, y=0.0},
        col = eos.hsv2rgb(h, 1.0, 1.0)
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
        agent.pos, agent.vel = flock.applyhardboundary(agent.pos, agent.vel)
    end

    if flock.optbeampath ~= 0 then
        flock.agents = sort_agents_by_distance(flock.agents)
    end
end


function flock.applyhardboundary(pos, vel)
    local newpos = {}
    local newvel = {}
    newpos.x = pos.x
    newpos.y = pos.y
    newvel.x = vel.x
    newvel.y = vel.y

    if pos.x <= -1.0 then
        newpos.x = -1.0
        newvel.x = math.abs(newvel.x) -- Reverse velocity along the x-axis
    end
    if pos.x >= 1.0 then
        newpos.x = 1.0
        newvel.x = -math.abs(newvel.x) -- Reverse velocity along the x-axis
    end
    if pos.y <= -1.0 then
        newpos.y = -1.0
        newvel.y = math.abs(newvel.y) -- Reverse velocity along the y-axis
    end
    if pos.y >= 1.0 then
        newpos.y = 1.0
        newvel.y = -math.abs(newvel.y) -- Reverse velocity along the y-axis
    end
    return newpos, newvel
end


-- function flock.applyhardboundary(pos)
--     local newpos = {}
--     newpos.x = pos.x
--     newpos.y = pos.y
--     if pos.x < -1.0 then newpos.x = -1.0 end
--     if pos.x >  1.0 then newpos.x =  1.0 end
--     if pos.y < -1.0 then newpos.y = -1.0 end
--     if pos.y >  1.0 then newpos.y =  1.0 end
--     return newpos
-- end

function flock.computebehaviors(agent)
    local coh = {x=0.0, y=0.0}
    local sep = {x=0.0, y=0.0}
    local ali = {x=0.0, y=0.0}
    local wall = {x=0.0, y=0.0}
    local totalacc = {x=0.0, y=0.0}  
    local count = 0
    local centerofmass = {x=0.0, y=0.0}
    for i,other in ipairs(flock.agents) do
        if other ~= agent then
            local dist = v2.dist(agent.pos, other.pos)
            if dist < flock.visualrange then
                -- Cohesion
                centerofmass = v2.add(centerofmass, other.pos)

                -- Separation
                if dist < flock.mindistance then
                    local diff = v2.sub(agent.pos, other.pos)
                    sep = v2.add(sep, diff)
                end

                -- Alignment
                ali = v2.add(ali, other.vel)

                count = count + 1
            end
        end
    end

    if count > 0 then
        local sc = 1.0 / count
        centerofmass = v2.scale(centerofmass, sc)
        coh = v2.scale(v2.sub(centerofmass, agent.pos), flock.cohesion)
        ali = v2.scale(ali, sc)
        ali = v2.scale(ali, flock.alignment)
        sep = v2.scale(sep, flock.separation)
    end


    -- Wall avoidance
    local ldisc, rdist, tdist, bdist
    ldist = v2.dist(v2.new(-1.0, agent.pos.y), agent.pos)
    if ldist ~= 0.0 and ldist < flock.walldetect then wall = v2.add(wall, v2.new(flock.walldetect / ldist, 0.0)) end

    rdist = v2.dist(v2.new(1.0, agent.pos.y), agent.pos)
    if rdist ~= 0.0 and rdist < flock.walldetect then wall = v2.sub(wall, v2.new(flock.walldetect / rdist, 0.0)) end

    tdist = v2.dist(v2.new(agent.pos.x, 1.0), agent.pos)
    if tdist ~= 0.0 and tdist < flock.walldetect then wall = v2.sub(wall, v2.new(0.0, flock.walldetect / tdist)) end
    
    bdist = v2.dist(v2.new(agent.pos.x, -1.0), agent.pos)
    if bdist ~= 0.0 and bdist < flock.walldetect then wall = v2.add(wall, v2.new(0.0, flock.walldetect / bdist)) end

    wall = v2.scale(wall, flock.wallavoid)

    totalacc = v2.add(totalacc, coh)
    totalacc = v2.add(totalacc, sep)
    totalacc = v2.add(totalacc, ali)
    totalacc = v2.add(totalacc, wall)
    totalacc = v2.limit(totalacc, flock.maxforce)
    return totalacc
end

function sort_agents_by_distance(agents)
    local sorted_agents = {}
    local last_pos = {x = 0.0, y = 0.0}
    local remaining_agents = {}

    for i, agent in ipairs(agents) do
        table.insert(remaining_agents, agent)
    end

    while #remaining_agents > 0 do
        local closest_index = find_closest_agent(remaining_agents, last_pos)
        local closest_agent = table.remove(remaining_agents, closest_index)
        table.insert(sorted_agents, closest_agent)
        last_pos = closest_agent.pos
    end

    return sorted_agents
end

function find_closest_agent(agents, last_pos)
    local v2 = require("vec2")
    local min_dist_squared = math.huge
    local closest_index = -1

    for i, agent in ipairs(agents) do
        local dist_squared = v2.dist_sqr(last_pos, agent.pos)
        if dist_squared < min_dist_squared then
            min_dist_squared = dist_squared
            closest_index = i
        end
    end

    return closest_index
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
