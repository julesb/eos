
local v3 = require("vec3")

local function make_tangent(pos, dir)
  local p1 = v3.normalize(v3.add(pos, dir))
  local p2 = v3.normalize(v3.sub(pos, dir))
  return v3.normalize(v3.sub(p2, p1))
end

local function make_tangent_gpt(pos, dir)
  -- Normalize the position vector to get the radial direction from the sphere's center
  local radial = v3.normalize(pos)
  -- Project 'dir' onto 'radial' to find the component of 'dir' that points towards the center
  local projection = v3.scale(radial, v3.dot(dir, radial))
  -- Subtract this component from 'dir' to get the component orthogonal to 'radial'
  local tangent = v3.sub(dir, projection)
  -- Normalize and scale back to the original magnitude of 'dir'
  tangent = v3.normalize(tangent)
  return tangent
end

local num_tests = 100

for _=1, num_tests do
  local pos = v3.random_unit();
  local dir = v3.scale(v3.random_unit(), 0.01);
  local me_tangent = v3.normalize(make_tangent(pos, dir))
  local gpt_tangent = v3.normalize(make_tangent_gpt(pos, dir))
  -- local up = v3.normalize(pos)
  print(" ME:", v3.dot(pos, me_tangent))
  print("GPT:", v3.dot(pos, gpt_tangent))
end
