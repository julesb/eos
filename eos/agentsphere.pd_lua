local as = pd.Class:new():register("agentsphere")
local v3 = require("vec3")
local sd = require("surfacedwellers")
local simplex = require("simplex")
local simplex2 = require("simplex2")
local eos = require("eos")

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
  local cs = require("colorspace")
  local agents = {}
  local colstep = 1 / numagents
  for i=1, numagents do
    local col = cs.hcl_gradient({r=1,g=1,b=0}, {r=0.25,g=0,b=1}, (i-1)*colstep)
    local agent = sd.make_agent(nil, nil, col, i)
    -- local agent = sd.make_agent(nil, nil, {r=math.random(), g=math.random(), b=math.random()}, i)
    table.insert(agents, agent)
    print(self:agent_tostring(agent))
  end
  return agents
end


function as:in_1_bang()
  local dt = (1/90) * self.timestep
  self.tprev = self.time
  self.time = self.time + dt

  self:update_agents(dt)

  local visible_agents = {}
  for i=1,#self.agents do
    if self:is_visible(self.agents[i].pos, G_CAMERA_POS) then
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
    for i=1,#agents_sorted do
      local p = v3.copy(agents_sorted[i].pos)
      eos.setcolor(p, agents_sorted[i].col)
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


function as:noise4(x, y, z, w)
  local xoff = 12.3
  local yoff = 23.4
  local zoff = 34.5

  local n1 = simplex.noise2d(x, y)
  local n2 = simplex.noise2d(y, z)
  local n3 = simplex.noise2d(z, w)
  local n4 = simplex.noise2d(w, x)
  -- local n1 = simplex2.noise3d(x, yoff, zoff)
  -- local n2 = simplex2.noise3d(xoff, y, zoff)
  -- local n3 = simplex2.noise3d(xoff, yoff, z)
  -- local n4 = simplex2.noise3d(xoff, yoff, z)

  return (n1*n2*n3*n4) * 4
end

function as:noisetest(points)
  local ns = 1 -- noise scale
  local p1 = v3.new(0, 0, 0)
  local nc = { -- noise coord.
    x = p1.x*ns+12,
    y = p1.y*ns+23,
    z = p1.z*ns+34
  }
  eos.setcolor(p1, {r=1, g=1, b=1})

  -- -- noise gradient indicator
  local g = simplex2.dodgy_noise3_gradient(nc.x, nc.y, nc.z, self.time)
  -- g.z = 0
  g = v3.normalize(g)
  -- local g = v3.new(1, 0, 0)
  local p2 = v3.add(p1, g)

  eos.setcolor(p2, {r=1, g=1, b=1})

  table.insert(points, {x=p1.x, y=p1.y, z=p1.z, r=0, g=0, b=0})
  table.insert(points, p1)
  table.insert(points, p2)
  table.insert(points, {x=p2.x, y=p2.y, z=p2.z, r=0, g=0, b=0})


  -- noise value indicator
  -- local noise = simplex2.noise3d(nc.x, nc.y, self.time * 0.1)
  local noise = self:noise4(nc.x, nc.y, nc.z, self.time * 0.1)
  -- local noise = simplex2.noise4d(nc.x, nc.y, self.time * 0.1, nc.z)

  local np = {x=0, y=noise, z=0}
  eos.setcolor(np, {r=0, g=1, b=0})
  -- eos.setcolor(p1, {r=0, g=1, b=0})

  table.insert(points, {x=p1.x, y=p1.y, z=p1.z, r=0, g=0, b=0})
  table.insert(points, {x=p1.x, y=p1.y, z=p1.z, r=0, g=1, b=0})
  -- table.insert(points, p1)
  table.insert(points, np)
  table.insert(points, {x=np.x, y=np.y, z=np.z, r=0, g=0, b=0})


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

