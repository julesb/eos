local as = pd.Class:new():register("agentsphere")
local v3 = require("vec3")
local sd = require("surfacedwellers")

function as:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.numagents = 200
  self.time = 0
  self.tprev = 0
  self.timestep = 1
  self.targetframerate = 60
  self.sphere_scale = 1
  self.optimize = true

  if type(atoms[1]) == "number" then
    self.numagents = math.max(1, atoms[1])
  end

  self.agents = self:init_agents(self.numagents)

  if G_CAMERA_POS == nil then
    G_CAMERA_POS = {x=0, y=0, z=-2}
  end

  return true
end

function as:init_agents(numagents)
  local agents = {}
  for i=1, numagents do
    local agent = sd.make_agent(nil, nil, {r=math.random(), g=math.random(), b=math.random()}, i)
    table.insert(agents, agent)
    print(self:agent_tostring(agent))
  end
  return agents
end


function as:in_1_bang()
  local eos = require("eos")
  local dt = (1/90) * self.timestep
  self.tprev = self.time
  self.time = self.time + dt

  self:update_agents(dt)

  local visible_agents = {}
  for i=1,#self.agents do
    if self.agents[i] == nil then print("nil agent ", i) end
    if self:is_visible(self.agents[i].pos, G_CAMERA_POS) then
      table.insert(visible_agents, self.agents[i])
    end
  end

  local agents_sorted
    if self.optimize then
      agents_sorted = self:sort_by_distance(visible_agents)
    else
      agents_sorted = self.agents
    end
  local points = {}

  table.insert(points, {
    x=agents_sorted[1].pos.x,
    y=agents_sorted[1].pos.y,
    z=agents_sorted[1].pos.z,
    r=0,
    g=0,
    b=0}
  )
  for i=1,#agents_sorted do
    if agents_sorted[i] == nil then print("nil agent ", i) end
    if self:is_visible(agents_sorted[i].pos, G_CAMERA_POS) then
      local p = v3.copy(agents_sorted[i].pos)
      eos.setcolor(p, agents_sorted[i].col)
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


function as:update_agents(dt)
   sd.update_agents(self.agents, dt, self.time)
 end


function as:is_visible(agent_pos, camera_pos)
    local dot = agent_pos.x * camera_pos.x +
                agent_pos.y * camera_pos.y +
                agent_pos.z * camera_pos.z
    return dot > 0
end


function as:agent_tostring(p)
  return string.format("pos: [%.2f, %.2f, %.2f], col: [%.2f, %.2f, %.2f]",
                        p.pos.x, p.pos.y, p.pos.z, p.col.r, p.col.g, p.col.b)
end


function as:in_2(sel, atoms)
  if sel == "timestep" then
    self.timestep = atoms[1]
  elseif sel == "optimize" then
    self.optimize = (atoms[1] ~= 0)
  end
end


function as:sort_by_distance(agents)
  local sorted_agents = {}
  local last_pos = {x = 0.0, y = 0.0, z=0.0}
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


function as:find_closest_agent(agents, last_pos)
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

