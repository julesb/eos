
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


function sd.update_agents(agents, dt, globaltime, noise_scale, steer_force, drag, phase)
  for _,agent in ipairs(agents) do
    sd.follow_gradient(agent, globaltime, noise_scale, steer_force, phase)
    -- sd.align_to_gradient(agent, globaltime)
    -- sd.wander1(agent, globaltime)
    agent.pos = v3.normalize(v3.add(agent.pos, v3.scale(agent.vel, dt)))
    agent.vel = sd.make_tangent(agent.pos, agent.vel)
    -- sd.steer(agent, math.random(-1.0, 1.0) * 0.01)
    -- sd.move_forward(agent, 0.1)
    -- friction
    agent.vel = v3.scale(agent.vel, drag)
  end
end


function sd.follow_gradient(agent, globaltime, noise_scale, steering_scale, phase)
  noise_scale = noise_scale or 2.3
  steering_scale = steering_scale or 0.05
  local p = agent.pos
  local np = v3.scale(p, noise_scale)
  local ids =  agent.id * phase --  / 400.0 --  * 6 * 250
  np = v3.add(np, {x=ids, y=ids, z=ids})
  local grad = sd.Simplex:noise4d_gradient(np.x, np.y, np.z, globaltime*0.2+ids, 0.001)
  -- Project the gradient to the tangent plane at the agent's position
  local projected_grad = sd.make_tangent(np, grad)
  local diff = v3.sub(agent.vel, projected_grad)
  agent.vel = v3.add(agent.vel, v3.scale(diff, steering_scale))
  agent.forward = v3.normalize(sd.make_tangent(agent.pos, agent.vel))
end



-- function sd.wander(agent, globaltime)
--   local simplex = require("simplex2")
--   local steer_mag = 1.75
--   local s = 0.2
--   local p = agent.pos
--   local steer = math.pi * simplex.noise4d(
--                             p.x*s,
--                             p.y*s,
--                             p.z*s,
--                             globaltime * 0.1
--                           ) * steer_mag
--   sd.steer(agent, steer)
-- end

-- function sd.align_to_gradient(agent, globaltime)
--   local simplex = require("simplex2")
--   local noise_scale =2.2
--   local epsilon = 0.01
--   local p = v3.scale(agent.pos, noise_scale)
--   local id = 0 -- agent.id * 0.03
--   -- p = v3.scale(p, agent.id)
--
--   local grad = simplex.dodgy_noise3_gradient(p.x+id, p.y+id, p.z+id, globaltime*0.05)
--   -- local grad = simplex.dodgy_noise3_gradient(p.x+id, p.y+id, p.z+id, globaltime*0.00)
--
--   -- local grad = sd.noise_gradient3d(
--   --   v3.add(p, v3.scale(p, noise_scale * globaltime)),
--   --   agent.forward,
--   --   epsilon,
--   --   globaltime
--   -- )
--   -- print("grad:", v3.tostring(grad))
--
--   local pgrad = sd.make_tangent(p, grad)
--   if not (pgrad.x == 0 and pgrad.y == 0 and pgrad.z == 0) then
--     agent.forward = v3.normalize(pgrad)
--   end
-- end


-- function sd.follow_gradient(agent, globaltime)
--   local simplex = require("simplex2")
--   local noise_scale = 1.2
--   local p = agent.pos
--   local np = v3.scale(p, noise_scale)
--   local steering_scale = 0.1
--
--   -- local ids = (math.floor(agent.id / 300.0) * 6) * 5
--   -- np = v3.add(np, {x=ids, y=ids, z=ids})
--
--   local grad = sd.Simplex:noise4d_gradient(np.x, np.y, np.z, globaltime*0.05 - ids)
--   -- local grad = simplex.dodgy_noise3_gradient(np.x, np.y, np.z, globaltime*0.05)
--
--   -- local grad = sd.noise_gradient3d(
--   --   v3.add(p, v3.scale(p, noise_scale * globaltime)),
--   --   agent.forward,
--   --   0.1
--   -- )
--
--   -- Project the gradient to the tangent plane at the agent's position
--   local projected_grad = sd.make_tangent(p, grad)
--   -- if agent.id < 150 == 0 then projected_grad = v3.scale(projected_grad, -1) end
--
--   -- Determine the steering angle to align the forward vector with the projected gradient
--   local axis = v3.normalize(p)
--   local cos_theta = v3.dot(v3.normalize(agent.forward), v3.normalize(projected_grad))
--   local theta = math.acos(cos_theta)
--
--   -- Determine the sign of the rotation by using the cross product
--   local sign = v3.dot(v3.cross(agent.forward, projected_grad), axis) < 0 and -1 or 1
--
--   -- Apply steering towards the gradient direction
--   sd.steer(agent, sign * theta * steering_scale)
-- end

-- function sd.wander1(agent, globaltime)
--   local simplex = require("simplex")
--   local steer_mag = 0.05
--   local s = 0.2
--   local p = agent.pos
--   local steer = math.pi * simplex.noise3d(
--                             p.x+s*globaltime,
--                             p.y+s*globaltime,
--                             p.z+s*globaltime
--                           ) * steer_mag
--   -- local steer = math.pi * simplex.noise3d(agent.id*100, 123.45, globaltime) * steer_mag
--   sd.steer(agent, steer)
-- end





return surfacedwellers
