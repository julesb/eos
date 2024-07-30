
local solar = {}
local sol = solar -- short name
local v3 = require("vec3")
local osimplex = require("opensimplex2s")

sol.Simplex = osimplex.new()

function sol.make_agent(pos, vel, col, id)
  pos = pos or v3.random_unit()
  local normalized_pos = v3.normalize(pos)
  local initial_vel = vel or v3.scale(v3.random_unit(), 1.0)
  return {
    id = id,
    pos = normalized_pos,
    vel = sol.make_tangent(normalized_pos, initial_vel),
    forward = v3.normalize(initial_vel),
    col = col or {r = 1, g = 1, b = 1}
  }
end

-- returns v projected onto the tangent plane at pos
function sol.make_tangent(pos, v)
  local parallel_component = v3.scale(pos, v3.dot(pos, v))
  local tangent_component = v3.sub(v, parallel_component)
  return v3.scale(tangent_component, v3.len(v) / v3.len(tangent_component))
end


function sol.move_forward(agent, speed)
  local step = v3.scale(agent.forward, speed)
  agent.vel = v3.add(agent.vel, step)
  -- agent.vel = sol.make_tangent(agent.pos, v3.add(agent.vel, step))
  agent.forward = v3.normalize(agent.vel)
end


-- function sol.steer(agent, angle)
--   local axis = agent.pos
--   local cos_angle = math.cos(angle)
--   local sin_angle = math.sin(angle)
--   local forward = agent.forward
--
--   -- Rodrigues rotation formula
--   agent.forward = v3.normalize(v3.add(
--     v3.add(
--       v3.scale(forward, cos_angle),
--       v3.scale(v3.cross(axis, forward), sin_angle)
--     ),
--     v3.scale(axis, v3.dot(axis, forward) * (1 - cos_angle))
--   ))
-- end


function sol.update_agents(agents, dt, globaltime, noise_scale,
                           gradient_force, thrust_force, gravity_force,
                           drag, phase)
  for _,agent in ipairs(agents) do
    local d = v3.len(agent.pos)
    sol.follow_flowfield(agent, globaltime, noise_scale,
                        gradient_force/(d*d), phase)
    -- sol.follow_gradient(agent, globaltime, noise_scale, gradient_force, phase)
    -- sol.align_to_gradient(agent, globaltime)
    -- sol.wander1(agent, globaltime)

    sol.move_forward(agent, thrust_force)
    sol.apply_gravity(agent, gravity_force)
    agent.pos = v3.add(agent.pos, v3.scale(agent.vel, dt))
    -- agent.pos = v3.normalize(v3.add(agent.pos, v3.scale(agent.vel, dt)))
    -- agent.vel = sol.make_tangent(agent.pos, agent.vel)
    -- sol.steer(agent, math.random(-1.0, 1.0) * 0.01)

    d = v3.len(agent.pos)
    if d > 10 then
      agent.pos = {x=0, y=0, z=0}
    end

    if v3.len(agent.pos) < 1 then
      agent.pos = v3.normalize(agent.pos)
    end

    -- friction
    agent.vel = v3.scale(agent.vel, drag)

  end
end

function sol.follow_flowfield(agent, time, noise_scale, gradient_force, phase)
  local o1 = 123.45
  local o2 = 64.12
  local o3 = 12.65
  local p = agent.pos
  local np = v3.scale(p, noise_scale)
  local ids =  agent.id * phase
  np = v3.add(np, v3.scale(p, ids))
  local nv = {
    x = sol.Simplex:noise4_Classic(np.x+o1, np.y+o2, np.z+o3, time*0.2),
    y = sol.Simplex:noise4_Classic(np.x+o2, np.y+o3, np.z+o1, time*0.2),
    z = sol.Simplex:noise4_Classic(np.x+o3, np.y+o1, np.z+o2, time*0.2)
  }
  -- local nv = { x = nx, y = ny, z = nz }
  -- nv = sol.make_tangent(p, nv)
  agent.vel = v3.add(agent.vel, v3.scale(nv, gradient_force))
  -- agent.vel = sol.make_tangent(p, v3.add(agent.vel, v3.scale(nv, gradient_force)))
  -- agent.vel = sol.make_tangent(p, v3.scale(nv, gradient_force))
  agent.forward = v3.normalize(agent.vel)
end


function sol.apply_gravity(agent, gravity_force)
  local d = v3.len(agent.pos)

  local f = v3.scale(v3.normalize(agent.pos), gravity_force / (d*d))
  agent.vel = v3.add(agent.vel, f)
end


return solar
