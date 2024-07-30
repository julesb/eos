local sf = pd.Class:new():register("solarflare")
local v3 = require("vec3")
local sd = require("solar")
local eos = require("eos")

function sf:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.numagents = 200
  self.time = 0
  self.tprev = 0
  self.timestep = 1
  self.targetframerate = 60
  self.sphere_scale = 1
  self.optimize = true

  self.noise_scale = 1.3
  self.gradient_force = 0.05
  self.thrust_force = 0.5
  self.gravity_force = -3.0
  self.drag = 0.9
  self.phase = 0.1

  self.back_visible = true

  if type(atoms[1]) == "number" then
    self.numagents = math.max(1, atoms[1])
  end

  self.agents = self:init_agents(self.numagents)

  if G_CAMERA_POS == nil then
    G_CAMERA_POS = {x=0, y=0, z=-2}
  end

  return true
end

function sf:init_agents(numagents)
  local cs = require("colorspace")
  local agents = {}
  local colstep = 1 / numagents
  for i=1, numagents do
    local col = cs.hcl_gradient({r=1,g=1,b=0}, {r=0.25,g=0,b=1}, (i-1)*colstep)
    local agent = sd.make_agent(nil, nil, col, (i-1) / numagents)
    table.insert(agents, agent)
    print(self:agent_tostring(agent))
  end
  return agents
end


function sf:in_1_bang()
  local dt = (1/90) * self.timestep
  self.tprev = self.time
  self.time = self.time + dt

  self:update_agents(dt)

  local visible_agents = {}
  for i=1,#self.agents do
    if not self.back_visible then
      if self:is_visible(self.agents[i].pos, G_CAMERA_POS) then
        self.agents[i].visible = true
        table.insert(visible_agents, self.agents[i])
      else
        self.agents[i].visible = false
      end
    else
      if self:is_visible(self.agents[i].pos, G_CAMERA_POS) then
        self.agents[i].visible = true
      else
        self.agents[i].visible = false
      end
      table.insert(visible_agents, self.agents[i])
    end
  end

  local agents_sorted
    if self.optimize then
      agents_sorted = self:sort_by_distance(visible_agents)
    else
      agents_sorted = visible_agents
    end
  local points = {}

  if #agents_sorted > 0 then
    table.insert(points, {
      x=agents_sorted[1].pos.x,
      y=agents_sorted[1].pos.y,
      z=agents_sorted[1].pos.z,
      r=0,
      g=0,
      b=0}
    )

    local col
    local dim = 0.333
    for i=1,#agents_sorted do
      local a = agents_sorted[i]
      local p = v3.copy(agents_sorted[i].pos)

      if self.back_visible and not a.visible then
        col = {
          r = a.col.r * dim,
          g = a.col.g * dim,
          b = a.col.b * dim
        }
      else
        col = {r = a.col.r, g=a.col.g, b=a.col.b}
      end
      eos.setcolor(p, col)
      table.insert(points, {x=p.x, y=p.y, z=p.z, r=0, g=0, b=0})
      table.insert(points, p)
      table.insert(points, {x=p.x, y=p.y, z=p.z, r=0, g=0, b=0})
    end
  else
      table.insert(points, {x=0, y=0, z=0, r=1, g=0, b=0})
  end

  -- self:noisetest(points)

  local out = eos.points_to_xyzrgb(points)

  self:outlet(2, "float", { #out / 6 })
  self:outlet(1, "list", out)
end



function sf:update_agents(dt)
   sd.update_agents(self.agents, dt, self.time, self.noise_scale,
                    self.gradient_force, self.thrust_force,
                    self.gravity_force,self.drag, self.phase)
 end


function sf:is_visible(agent_pos, camera_pos)
    local dot = agent_pos.x * camera_pos.x +
                agent_pos.y * camera_pos.y +
                agent_pos.z * camera_pos.z
    return dot > 0
end


function sf:agent_tostring(p)
  return string.format("pos: [%.2f, %.2f, %.2f], col: [%.2f, %.2f, %.2f]",
                       p.pos.x, p.pos.y, p.pos.z, p.col.r, p.col.g, p.col.b)
end


function sf:in_2(sel, atoms)
  if sel == "timestep" then
    self.timestep = atoms[1]
  elseif sel == "optimize" then
    self.optimize = (atoms[1] ~= 0)
  elseif sel == "noisescale" then
    self.noise_scale = atoms[1]
  elseif sel == "gradientforce" then
    self.gradient_force = atoms[1]
  elseif sel == "thrustforce" then
    self.thrust_force = atoms[1]
  elseif sel == "gravityforce" then
    self.gravity_force = atoms[1]
  elseif sel == "drag" then
    self.drag = 1.0 - math.min(1.0, math.max(0, atoms[1]))
  elseif sel == "phase" then
    self.phase = atoms[1]
  elseif sel == "backvisible" then
    self.back_visible = (atoms[1] ~= 0)
  end
end


function sf:sort_by_distance(agents)
  local sorted_agents = {}
  local last_pos = {x = 1.0, y = 0.0, z=0.0}
  local remaining_agents = {}

  for _, agent in ipairs(agents) do
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


function sf:find_closest_agent(agents, last_pos)
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

