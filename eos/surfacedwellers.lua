
local surfacedwellers = {}
local sd = surfacedwellers -- short name
local v3 = require("vec3")
local osimplex = require("opensimplex2s")

sd.Simplex = osimplex.new()

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


function sd.wander1(agent, globaltime)
  local simplex = require("simplex")
  local steer_mag = 0.05
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

function sd.wander(agent, globaltime)
  local simplex = require("simplex2")
  local steer_mag = 1.75
  local s = 0.2
  local p = agent.pos
  local steer = math.pi * simplex.noise4d(
                            p.x*s,
                            p.y*s,
                            p.z*s,
                            globaltime * 0.1
                          ) * steer_mag
  sd.steer(agent, steer)
end



function sd.update_agents(agents, dt, globaltime)
  for _,agent in ipairs(agents) do
    sd.follow_gradient2(agent, globaltime)
    -- sd.align_to_gradient(agent, globaltime)
    -- sd.wander1(agent, globaltime)
    sd.move_forward(agent, 0.1)
    agent.pos = v3.normalize(v3.add(agent.pos, v3.scale(agent.vel, dt)))
    agent.vel = sd.make_tangent(agent.pos, agent.vel)
    -- friction
    agent.vel = v3.scale(agent.vel, 0.9)
  end

end


-- function sd.noise_gradient3d(pos, forward, epsilon, time)
--   local simplex = require("simplex2")
--   -- Calculate the perpendicular vector to forward within the tangent plane
--   local perpendicular = v3.cross(forward, pos)
--   perpendicular = v3.normalize(perpendicular)
--
--   -- Define the sampling points
--   local p0 = pos
--   local p1 = v3.add(pos, v3.scale(forward, epsilon))
--   local p2 = v3.add(pos, v3.scale(perpendicular, epsilon))
--
--   -- print("P0:", v3.tostring(p0))
--   -- print("P1:", v3.tostring(p1))
--   -- print("P2:", v3.tostring(p2))
--
--   -- print("noise_gradient3d: time", time)
--   -- Sample noise values at these points
--   local n0 = simplex.noise4d(p0.x, p0.y, p0.z, time)
--   local n1 = simplex.noise4d(p1.x, p1.y, p1.z, time)
--   local n2 = simplex.noise4d(p2.x, p2.y, p2.z, time)
--
--   -- Form vectors between the noise values
--   local p0p1 = v3.scale(forward, n1 - n0)
--   local p0p2 = v3.scale(perpendicular, n2 - n0)
--
--   -- Calculate the gradient via cross product
--   local grad = v3.cross(p0p1, p0p2)
--   return v3.normalize(grad)
-- end


function sd.align_to_gradient(agent, globaltime)
  local simplex = require("simplex2")
  local noise_scale =2.2
  local epsilon = 0.01
  local p = v3.scale(agent.pos, noise_scale)
  local id = 0 -- agent.id * 0.03
  -- p = v3.scale(p, agent.id)

  local grad = simplex.dodgy_noise3_gradient(p.x+id, p.y+id, p.z+id, globaltime*0.05)
  -- local grad = simplex.dodgy_noise3_gradient(p.x+id, p.y+id, p.z+id, globaltime*0.00)

  -- local grad = sd.noise_gradient3d(
  --   v3.add(p, v3.scale(p, noise_scale * globaltime)),
  --   agent.forward,
  --   epsilon,
  --   globaltime
  -- )
  -- print("grad:", v3.tostring(grad))

  local pgrad = sd.make_tangent(p, grad)
  if not (pgrad.x == 0 and pgrad.y == 0 and pgrad.z == 0) then
    agent.forward = v3.normalize(pgrad)
  end
end


function sd.follow_gradient(agent, globaltime)
  local simplex = require("simplex2")
  local noise_scale = 1.2
  local p = agent.pos
  local np = v3.scale(p, noise_scale)
  local steering_scale = 0.1

  -- local ids = (math.floor(agent.id / 300.0) * 6) * 5
  -- np = v3.add(np, {x=ids, y=ids, z=ids})

  local grad = sd.Simplex:noise4d_gradient(np.x, np.y, np.z, globaltime*0.05 - ids)
  -- local grad = simplex.dodgy_noise3_gradient(np.x, np.y, np.z, globaltime*0.05)

  -- local grad = sd.noise_gradient3d(
  --   v3.add(p, v3.scale(p, noise_scale * globaltime)),
  --   agent.forward,
  --   0.1
  -- )

  -- Project the gradient to the tangent plane at the agent's position
  local projected_grad = sd.make_tangent(p, grad)
  -- if agent.id < 150 == 0 then projected_grad = v3.scale(projected_grad, -1) end

  -- Determine the steering angle to align the forward vector with the projected gradient
  local axis = v3.normalize(p)
  local cos_theta = v3.dot(v3.normalize(agent.forward), v3.normalize(projected_grad))
  local theta = math.acos(cos_theta)

  -- Determine the sign of the rotation by using the cross product
  local sign = v3.dot(v3.cross(agent.forward, projected_grad), axis) < 0 and -1 or 1

  -- Apply steering towards the gradient direction
  sd.steer(agent, sign * theta * steering_scale)
end


function sd.follow_gradient2(agent, globaltime)
  local noise_scale = 2.3
  local p = agent.pos
  local np = v3.scale(p, noise_scale)
  local steering_scale = 0.05
  local ids = (math.floor(agent.id / 300.0) * 6) * 250
  np = v3.add(np, {x=ids, y=ids, z=ids})

  -- local ids = agent.id * 0.005
  -- np = v3.add(agent.pos, {x=ids, y=ids, z=ids})

  local grad = sd.Simplex:noise4d_gradient(np.x, np.y, np.z, globaltime*0.2)

  -- Project the gradient to the tangent plane at the agent's position
  local projected_grad = sd.make_tangent(p, grad)

  local diff = v3.sub(agent.vel, projected_grad)
  agent.vel = v3.add(agent.vel, v3.scale(diff, steering_scale))
  agent.forward = v3.normalize(sd.make_tangent(agent.pos, agent.vel))
end


return surfacedwellers
