local particlesys = {}
local v2 = require("vec2")
local pal = require("palettes")

particlesys.defaultconfig = {
  position = {x=0, y=0},
  maxparticles = 30,
  lifespan = 0.25,
  gravity = {x=0, y=2},
  emitprobability = 0.75, -- probability of emitting a particle on any given frame
  meanvelocity = 100.0,
  optbeampath = true,
  emitting = true
}

function particlesys.init(config)
  particlesys.config = {}
  for key, val in pairs(particlesys.defaultconfig) do
    if config[key] == nil then
      particlesys.config[key] = val -- particlesys.defaultconfig[key]
    else
      particlesys.config[key] = config[key]
    end
  end

  particlesys.particles = {}
end


function particlesys.createparticle()
  local l = math.random()
  local v = math.random()
  return {
    pos = particlesys.config.position,
    ppos = particlesys.config.position,
    vel = v2.scale(v2.randdir(), 1 + v*v*v * particlesys.config.meanvelocity),
    life = particlesys.config.lifespan * l*l*l*l,
    col = pal.blackbody(1)
  }
end


function particlesys.update(dt)
  for i,p in ipairs(particlesys.particles) do
    -- print(particlesys.particletostring(p))
    p.ppos = p.pos
    p.life = p.life - dt
    if p.life <= 0.0 then
      table.remove(particlesys.particles, i)
    elseif p.pos.x < -1 or p.pos.x > 1 or p.pos.y < -1 or p.pos.y > 1 then
      table.remove(particlesys.particles, i)
    else
      p.vel = v2.add(p.vel, v2.scale(particlesys.config.gravity, dt))
      p.pos = v2.add(p.pos, v2.scale(p.vel, dt))
      local intensity = p.life / particlesys.config.lifespan
      p.col.r = 0.8 * intensity
      p.col.g = 0.8 * intensity
      p.col.b = intensity

      -- p.col = pal.blackbody(p.life / particlesys.config.lifespan)
    end
  end
  if #particlesys.particles < particlesys.config.maxparticles
      and particlesys.config.emitting then
    local r = math.random()
    if r < particlesys.config.emitprobability then
      local p = particlesys.createparticle()
      table.insert(particlesys.particles, p)
    end
  end
  if particlesys.config.optbeampath then
      particlesys.particles = particlesys.sort_by_distance(particlesys.particles)
  end
end


function particlesys.sort_by_distance(particles)
    local sorted = {}
    local last_pos =particlesys.config.position --  {x = 0.0, y = 0.0}
    local remaining = {}

    for _, p in ipairs(particles) do
        table.insert(remaining, p)
    end

    while #remaining > 0 do
        local closest_index = particlesys.find_closest(remaining, last_pos)
        local closest = table.remove(remaining, closest_index)
        table.insert(sorted, closest)
        last_pos = closest.pos
    end

    return sorted
end


function particlesys.find_closest(particles, last_pos)
    local min_dist_squared = math.huge
    local closest_index = -1

    for i, p in ipairs(particles) do
        local dist_squared = v2.dist_sqr(last_pos, p.pos)
        if dist_squared < min_dist_squared then
            min_dist_squared = dist_squared
            closest_index = i
        end
    end

    return closest_index
end

function particlesys.particletostring(p)
  if p == nil then
    print("P: nil")
  else
    print(string.format("P: pos: %s, vel: %s, life: %.2f",
                      v2.tostring(p.pos), v2.tostring(p.vel), p.life))
  end
end

return particlesys
