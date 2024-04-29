local ps = pd.Class:new():register("particlesphere")
local socket = require("socket")
local v3 = require("vec3")
local simplex = require("simplex")

function ps:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.numparticles = 100
  self.time = 0
  self.tprev = 0
  self.timestep = 1
  self.targetframerate = 60
  self.sphere_scale = 1
  self.optimize = true

  if type(atoms[1]) == "number" then
    self.numparticles = math.max(1, atoms[1])
  end

  self.particles = self:init_particles(self.numparticles)

  if G_CAMERA_POS == nil then
    G_CAMERA_POS = {x=0, y=0, z=-2}
  end

  return true
end


function ps:in_1_bang()
  local eos = require("eos")
  local dt = (1/90) * self.timestep
  self.tprev = self.time
  self.time = self.time + dt

  self:update_particles(dt)

  local visible_particles = {}
  for i=1,#self.particles do
    if self.particles[i] == nil then print("nil particle ", i) end
    if self:is_visible(self.particles[i].pos, G_CAMERA_POS) then
      table.insert(visible_particles, self.particles[i])
    end
  end

  local particles_sorted
    if self.optimize then
      particles_sorted = self:sort_by_distance(visible_particles)
    else
      particles_sorted = self.particles
    end
  local points = {}

  table.insert(points, {
    x=particles_sorted[1].pos.x,
    y=particles_sorted[1].pos.y,
    z=particles_sorted[1].pos.z,
    r=0,
    g=0,
    b=0}
  )
  for i=1,#particles_sorted do
    if particles_sorted[i] == nil then print("nil particle ", i) end
    if self:is_visible(particles_sorted[i].pos, G_CAMERA_POS) then
      local p = v3.copy(particles_sorted[i].pos)
      eos.setcolor(p, particles_sorted[i].col)
      table.insert(points, {x=p.x, y=p.y, z=p.z, r=0, g=0, b=0})
      -- table.insert(points, {x=0, y=0, z=0, r=p.r, g=p.g, b=p.b})
      table.insert(points, p)
      table.insert(points, {x=p.x, y=p.y, z=p.z, r=0, g=0, b=0})
    end
  end

  local out = eos.points_to_xyzrgb(points)

  self:outlet(2, "float", { #out / 6 })
  self:outlet(1, "list", out)
end


function ps:update_particles(dt)
  for i=1, self.numparticles do
    self:update_particle(self.particles[i], dt)
  end
end


function ps:update_particle(particle, dt)
    -- Update position
    local new_pos = v3.add(particle.pos, v3.scale(particle.vel, dt))
    particle.pos = v3.normalize(new_pos)

    -- Ensure velocity is tangential (project the velocity onto the tangent plane)
    local radialComponent = v3.scale(particle.pos, v3.dot(particle.vel, particle.pos))
    -- particle.vel = v3.scale(v3.normalize(v3.sub(particle.vel, radialComponent)), particle.speed)
    particle.vel = v3.sub(particle.vel, radialComponent)
end


function ps:steer(particle, rads)
    local axis = v3.normalize(particle.position)  -- Axis of rotation
    local v = particle.vel
    local cosTheta = math.cos(rads)
    local sinTheta = math.sin(rads)

    local term1 = v3.scale(v, cosTheta)
    local term2 = v3.scale(v3.cross(axis, v), sinTheta)
    local dot = v3.dot(axis, v)
    local term3 = v3.scale(axis, dot * (1 - cosTheta))

    particle.vel = v3.add(v3.add(term1, term2), term3)
end

function ps:is_visible(particle_pos, camera_pos)
    local dot = particle_pos.x * camera_pos.x +
                particle_pos.y * camera_pos.y +
                particle_pos.z * camera_pos.z
    return dot > 0
end

function ps:init_particles(numparticles)
  local parts = {}
  for _=1, numparticles do
    local p = {
      vel = v3.scale(v3.random_unit(), 0.1),
      pos = v3.random_unit(),
      col = {r=math.random(), g=math.random(), b=math.random()},
      speed = math.random() * 0.001
    }
    table.insert(parts, p)
    print(self:particle_tostring(p))
  end
  return parts
end

function ps:particle_tostring(p)
  return string.format("pos: [%.2f, %.2f, %.2f], col: [%.2f, %.2f, %.2f]",
                        p.pos.x, p.pos.y, p.pos.z, p.col.r, p.col.g, p.col.b)
end


function ps:in_2(sel, atoms)
  if sel == "timestep" then
    self.timestep = atoms[1]
  elseif sel == "optimize" then
    self.optimize = (atoms[1] ~= 0)
  end
end


function ps:sort_by_distance(agents)
  local sorted_agents = {}
  local last_pos = {x = 0.0, y = 0.0, z=0.0}
  local remaining_agents = {}

  for i, agent in ipairs(agents) do
    table.insert(remaining_agents, agent)
  end

  while #remaining_agents > 0 do
    local closest_index = self:find_closest_agent(remaining_agents, last_pos)
    local closest_agent = table.remove(remaining_agents, closest_index)
    table.insert(sorted_agents, closest_agent)
    last_pos = closest_agent.pos
  end

  return sorted_agents
end


function ps:find_closest_agent(agents, last_pos)
  local min_dist_squared = math.huge
  local closest_index = -1

  for i, agent in ipairs(agents) do
    local dist_squared = v3.dist_sqr(last_pos, agent.pos)
    if dist_squared < min_dist_squared then
      min_dist_squared = dist_squared
      closest_index = i
    end
  end

  return closest_index
end

