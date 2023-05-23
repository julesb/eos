local flock = {}
local v2 = require("vec2")
local simplex = require("simplex")
local eos = require("eos")
local pal = require("palettes")

flock.defaultconfig = {
    size = 30,
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
    mindistance = 0.05,
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

local COLORMODE_CONSTANT    = 0
local COLORMODE_CENTERDIST  = 1
local COLORMODE_NBCOUNT     = 2
local COLORMODE_INDEX       = 3
local COLORMODE_VEL         = 4
local COLORMODE_ACC         = 5
local COLORMODE_COH         = 6
local COLORMODE_SEP         = 7
local COLORMODE_ALI         = 8
local COLORMODE_DIRHUE      = 9


function flock.init(config)
    flock.config = {}
    for key, value in pairs(flock.defaultconfig) do
        if config[key] == nil then
            flock.config[key] = flock.defaultconfig[key]
        else
            flock.config[key] = config[key]
        end
    end

    flock.agents = flock.initagents(flock.config.size)
    --flock.optbeampath = 0
    flock.framecount = 0
end


function flock.initagents(size)
    local agents = {}
    for i = 1,size do
        agents[i] = flock.new(i, v2.rand())
    end
    return agents
end


function flock.new(id, pos)
    local h = 2.0 * flock.config.size / id
    return {
        id = id,
        pos = {x=pos.x, y=pos.y},
        vel = v2.rand(), --{x=0.0, y=0.0}
        acc = {x=0.0, y=0.0},
        col = eos.hsv2rgb(h, 1.0, 1.0)
    }
end


function flock.update(dt)
    for _,agent in ipairs(flock.agents) do
        local newacc, col  = flock.computebehaviors(agent)
        agent.acc = newacc
        agent.col = col
    end

    for _,agent in ipairs(flock.agents) do
        agent.vel = v2.add(agent.vel, v2.scale(agent.acc, dt))
        agent.vel = v2.scale(agent.vel, 1.0 - flock.config.friction)
        agent.vel = v2.limit(agent.vel, flock.config.maxspeed)
        agent.pos = v2.add(agent.pos, v2.scale(agent.vel, dt))
        agent.pos, agent.vel = flock.applyhardboundary(agent.pos, agent.vel)
    end

    if flock.config.optbeampath ~= 0 then
        flock.agents = sort_agents_by_distance(flock.agents)
    end
    flock.framecount = flock.framecount + 1
end


function flock.applyhardboundary(pos, vel)
    local newpos = {}
    local newvel = {}
    newpos.x = pos.x
    newpos.y = pos.y
    newvel.x = vel.x
    newvel.y = vel.y

    if pos.x <= flock.config.worldXmin then
        newpos.x = flock.config.worldXmin
        newvel.x = math.abs(newvel.x)
    end
    if pos.x >= flock.config.worldXmax then
        newpos.x = flock.config.worldXmax
        newvel.x = -math.abs(newvel.x)
    end
    if pos.y <= flock.config.worldYmin then
        newpos.y = -flock.config.worldYmin
        newvel.y = math.abs(newvel.y)
    end
    if pos.y >= flock.config.worldYmax then
        newpos.y = flock.config.worldYmax
        newvel.y = -math.abs(newvel.y)
    end
    return newpos, newvel
end


function flock.computebehaviors(agent)
    local coh = {x=0.0, y=0.0}
    local sep = {x=0.0, y=0.0}
    local ali = {x=0.0, y=0.0}
    local wall = {x=0.0, y=0.0}
    local totalacc = {x=0.0, y=0.0}
    local count = 0
    local centerofmass = {x=0.0, y=0.0}
    for _,other in ipairs(flock.agents) do
        if other ~= agent then
            local dist = v2.dist(agent.pos, other.pos)
            if dist < flock.config.visualrange then
                -- Add FOV check
                local angle = v2.angle_between(agent.vel, v2.sub(other.pos, agent.pos))
                if math.abs(angle) <= flock.config.agentfov / 2.0 then

                    -- Cohesion
                    centerofmass = v2.add(centerofmass, other.pos)

                    -- Separation - NOTE maybe shouldnt depend on FOV?
                    if dist < flock.config.mindistance then
                        local diff = v2.sub(agent.pos, other.pos)
                        sep = v2.add(sep, diff)
                    end

                    -- Alignment
                    ali = v2.add(ali, other.vel)

                    count = count + 1
                end
            end
        end
    end

    if count > 0 then
        local sc = 1.0 / count
        centerofmass = v2.scale(centerofmass, sc)
        coh = v2.scale(v2.sub(centerofmass, agent.pos), flock.config.cohesion)
        ali = v2.scale(ali, sc)
        ali = v2.scale(ali, flock.config.alignment)
        sep = v2.scale(sep, flock.config.separation)
    end


    -- Wall avoidance
    local ldisc, rdist, tdist, bdist
    ldist = v2.dist(v2.new(flock.config.worldXmin, agent.pos.y), agent.pos)
    if ldist ~= 0.0 and ldist < flock.config.walldetect then
        wall = v2.add(wall, v2.new(flock.config.walldetect / ldist, 0.0))
    end

    rdist = v2.dist(v2.new(flock.config.worldXmax, agent.pos.y), agent.pos)
    if rdist ~= 0.0 and rdist < flock.config.walldetect then
        wall = v2.sub(wall, v2.new(flock.config.walldetect / rdist, 0.0))
    end

    tdist = v2.dist(v2.new(agent.pos.x, flock.config.worldYmax), agent.pos)
    if tdist ~= 0.0 and tdist < flock.config.walldetect then
        wall = v2.sub(wall, v2.new(0.0, flock.config.walldetect / tdist))
    end

    bdist = v2.dist(v2.new(agent.pos.x, flock.config.worldYmin), agent.pos)
    if bdist ~= 0.0 and bdist < flock.config.walldetect then
        wall = v2.add(wall, v2.new(0.0, flock.config.walldetect / bdist))
    end

    wall = v2.scale(wall, flock.config.wallavoid)

    -- wander
    local wander = flock.wander_behavior(agent, flock.config.wanderfreq, flock.config.wandermag)

    totalacc = v2.add(totalacc, coh)
    totalacc = v2.add(totalacc, sep)
    totalacc = v2.add(totalacc, ali)
    totalacc = v2.add(totalacc, wall)
    totalacc = v2.add(totalacc, wander)
    totalacc = v2.limit(totalacc, flock.config.maxforce)

    -- color
    local colparam = 0.0
    if flock.config.colormode == COLORMODE_CONSTANT then
        colparam = 0.0
    elseif flock.config.colormode == COLORMODE_CENTERDIST then
        colparam = v2.len(v2.sub(centerofmass, agent.pos))
    elseif flock.config.colormode == COLORMODE_NBCOUNT then
        colparam = count / flock.config.size
    elseif flock.config.colormode == COLORMODE_INDEX then
        colparam = agent.id / flock.config.size
    elseif flock.config.colormode == COLORMODE_VEL then
        colparam = v2.len(agent.vel) / flock.config.maxspeed
    elseif flock.config.colormode == COLORMODE_ACC then
        colparam = v2.len(agent.acc) / flock.config.maxforce
    elseif flock.config.colormode == COLORMODE_COH then
        colparam = v2.len(coh) / flock.config.cohesion
    elseif flock.config.colormode == COLORMODE_SEP then
        colparam = v2.len(sep) / flock.config.separation
    elseif flock.config.colormode == COLORMODE_ALI then
        colparam = v2.len(ali) / flock.config.alignment
    elseif flock.config.colormode == COLORMODE_DIRHUE then
        colparam = v2.angle_between(agent.vel, v2.new(1,0)) / 360.0
    end
    local gc1 = {
        h = flock.config.gradcol1h + flock.config.hueoffset,
        s = flock.config.gradcol1s,
        v = flock.config.gradcol1v,
    }
    local gc2 = {
        h = flock.config.gradcol2h + flock.config.hueoffset,
        s = flock.config.gradcol2s,
        v = flock.config.gradcol2v,
    }
    local color = pal.gradient(gc1, gc2, colparam)

    return totalacc, color
end

function flock.wander_behavior(agent, freq, magnitude)
    --local noise_value = simplex.noise2d( agent.pos.x*freq,
     --                                    agent.pos.y*freq)
    local noise_value = simplex.noise2d( agent.pos.x*freq + flock.framecount / 3000.0,
                                         agent.pos.y*freq + flock.framecount / 3000.0)
    --local noise_value = simplex.noise2d( agent.pos.x*freq + agent.id * 10.0,
    --                                     agent.pos.y*freq + agent.id * 10.0)
    local angle_offset = noise_value * magnitude
    local desired_orientation = v2.rotate(agent.vel, angle_offset)
    desired_orientation = v2.normalize(desired_orientation)
    local wander_force = v2.scale(v2.sub(desired_orientation, agent.vel), flock.config.wander)
    return wander_force
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
