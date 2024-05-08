
local surfacedwellers = {}
local sd = surfacedwellers -- short name
local v3 = require("vec3")
local simplex = require("simplex")

function sd.make_agent(pos, vel, col, id)
  pos = pos or v3.random_unit()
  local normalized_pos = v3.normalize(pos)
  local initial_vel = vel or v3.scale(v3.random_unit(), 1.0)
  return {
    id = id,
    pos = normalized_pos,
    vel = sd.make_tangent(normalized_pos, initial_vel),
    forward = v3.normalize(initial_vel),
    col = col or {r = 1, g = 1, b = 1}
  }
end

-- returns v projected onto the tangent plane at pos
function sd.make_tangent(pos, v)
  local parallel_component = v3.scale(pos, v3.dot(pos, v))
  local tangent_component = v3.sub(v, parallel_component)
  return v3.scale(tangent_component, v3.len(v) / v3.len(tangent_component))
end


function sd.move_forward(agent, speed)
  local step = v3.scale(agent.forward, speed)
  agent.vel = sd.make_tangent(agent.pos, v3.add(agent.vel, step))
  agent.forward = v3.normalize(agent.vel)
end


function sd.steer(agent, angle)
  local axis = agent.pos
  local cos_angle = math.cos(angle)
  local sin_angle = math.sin(angle)
  local forward = agent.forward

  -- Rodrigues rotation formula
  agent.forward = v3.normalize(v3.add(
    v3.add(
      v3.scale(forward, cos_angle),
      v3.scale(v3.cross(axis, forward), sin_angle)
    ),
    v3.scale(axis, v3.dot(axis, forward) * (1 - cos_angle))
  ))
end


function sd.wander(agent, globaltime)
  local steer_mag = 0.75
  local s = 0.2
  local p = agent.pos
  local steer = math.pi * simplex.noise3d(
                            p.x+s*globaltime,
                            p.y+s*globaltime,
                            p.z+s*globaltime
                          ) * steer_mag
  -- local steer = math.pi * simplex.noise3d(agent.id*100, 123.45, globaltime) * steer_mag
  sd.steer(agent, steer)
end


function sd.update_agents(agents, dt, globaltime)
  for _,agent in ipairs(agents) do
    sd.wander(agent, globaltime)
    sd.move_forward(agent, 0.2)
    agent.pos = v3.normalize(v3.add(agent.pos, v3.scale(agent.vel, dt)))
    agent.vel = sd.make_tangent(agent.pos, agent.vel)
    -- friction
    agent.vel = v3.scale(agent.vel, 0.75)
  end

end


return surfacedwellers
