local v2 = require("vec2")

local SpringSystem = {}
SpringSystem.__index = SpringSystem

-- Constants for the spring system
local DEFAULT_SPRING_CONSTANT = 0.5
local DEFAULT_DAMPING = 0.1
local DEFAULT_MASS = 0.5
local DEFAULT_REST_LENGTH = nil -- Will be calculated based on point distribution
local DEFAULT_GRAVITY = {x = 0, y = 0}
local DEFAULT_TIME_STEP = 1/60

function SpringSystem.new(num_points)
  local self = setmetatable({}, SpringSystem)

  -- Initialize system properties
  self.points = {}
  self.velocities = {}
  self.anchored = {}
  self.forces = {}
  self.springs = {}
  self.num_points = num_points
  self.spring_constant = DEFAULT_SPRING_CONSTANT
  self.damping = DEFAULT_DAMPING
  self.gravity = DEFAULT_GRAVITY
  self.time_step = DEFAULT_TIME_STEP

  -- Create points with initial positions distributed between -1 and 1
  for i = 1, num_points do
    local t = (i - 1) / (num_points - 1)
    local x = -1 + 2 * t

    self.points[i] = {x = x, y = 0, r = 1, g = 1, b = 1}
    self.velocities[i] = {x = 0, y = 0}
    self.forces[i] = {x = 0, y = 0}
    self.anchored[i] = (i == 1 or i == num_points) -- Anchor first and last points
  end

  -- Calculate default rest length based on point distribution
  local rest_length = (2 / (num_points - 1)) * 0.5

  -- Create springs between adjacent points
  for i = 1, num_points - 1 do
    table.insert(self.springs, {
      p1 = i,
      p2 = i + 1,
      k = self.spring_constant,
      rest_length = rest_length
    })
  end

  return self
end

-- Initialize the spring system with the specified number of points
function SpringSystem:init(num_points)
  return SpringSystem.new(num_points)
end

-- Apply an external force to a specific point
function SpringSystem:apply_force(point_index, force)
  if point_index < 1 or point_index > self.num_points then
    error("Point index out of bounds")
  end

  -- Add the force to the current force on the point
  self.velocities[point_index] = v2.add(self.velocities[point_index], force)
end

-- Reset all accumulated forces
function SpringSystem:reset_forces()
  for i = 1, self.num_points do
    self.forces[i] = {x = 0, y = 0}
  end
end

-- Calculate spring forces between connected points
function SpringSystem:calculate_spring_forces()
  for _, spring in ipairs(self.springs) do
    local p1 = self.points[spring.p1]
    local p2 = self.points[spring.p2]

    -- Calculate direction and current length of spring
    local direction = v2.sub(p2, p1)
    local length = v2.len(direction)

    if length > 0 then
      direction = v2.normalize(direction)

      -- Calculate spring force (Hooke's Law: F = -k * (length - rest_length))
      local displacement = length - spring.rest_length
      local force_magnitude = spring.k * displacement
      local force = v2.scale(direction, force_magnitude)

      -- Apply force to both points in opposite directions
      if not self.anchored[spring.p1] then
        self.forces[spring.p1] = v2.add(self.forces[spring.p1], force)
      end

      if not self.anchored[spring.p2] then
        self.forces[spring.p2] = v2.sub(self.forces[spring.p2], force)
      end
    end
  end
end

-- Update the system for one time step
function SpringSystem:update(dt)
  dt = dt or self.time_step

  -- Reset forces
  self:reset_forces()

  -- Calculate spring forces
  self:calculate_spring_forces()


  -- Apply gravity and update positions
  for i = 1, self.num_points do
    if not self.anchored[i] then
      -- Apply gravity
      self.forces[i] = v2.add(self.forces[i], {x=0, y=self.gravity.y * DEFAULT_MASS})
      -- self.forces[i] = v2.add(self.forces[i], v2.scale(self.gravity, DEFAULT_MASS))

      -- Apply damping to velocity
      self.velocities[i] = v2.scale(self.velocities[i], 1 - self.damping)

      -- Update velocity using F = ma
      local acceleration = v2.scale(self.forces[i], 1 / DEFAULT_MASS)
      self.velocities[i] = v2.add(self.velocities[i], v2.scale(acceleration, dt))

      -- Update position
      local position_delta = v2.scale(self.velocities[i], dt)

      -- Preserve color values when updating position
      local r, g, b = self.points[i].r, self.points[i].g, self.points[i].b
      self.points[i] = v2.add(self.points[i], position_delta)
      self.points[i].r, self.points[i].g, self.points[i].b = r, g, b
    end
  end
end

-- Get all points
function SpringSystem:get_points()
  local result = {}
  for i = 1, #self.points do
    local p = self.points[i]
    result[i] = {
      x = p.x,
      y = p.y,
      r = p.r or 1,
      g = p.g or 1,
      b = p.b or 1
    }
  end
    return result
  -- return self.points
end

-- Set spring constant for all springs
function SpringSystem:set_spring_constant(k)
  self.spring_constant = k
  for _, spring in ipairs(self.springs) do
    spring.k = k
  end
end

-- Set damping coefficient
function SpringSystem:set_damping(damping)
  self.damping = damping
end

-- Set gravity
function SpringSystem:set_gravity(gravity)
  self.gravity = gravity
end

-- Set time step
function SpringSystem:set_time_step(dt)
  self.time_step = dt
end

-- Set the color of a specific point
function SpringSystem:set_point_color(index, r, g, b)
  if index >= 1 and index <= self.num_points then
    self.points[index].r = r
    self.points[index].g = g
    self.points[index].b = b
  end
end



function SpringSystem:set_size(num_points)
  -- Store current system parameters
  local spring_constant = self.spring_constant
  local damping = self.damping
  local gravity = self.gravity
  local time_step = self.time_step

  -- Create new points array
  local new_points = {}
  local new_velocities = {}
  local new_anchored = {}
  local new_forces = {}

  -- Create points with initial positions distributed between -1 and 1
  for i = 1, num_points do
    local t = (i - 1) / (num_points - 1)
    local x = -1 + 2 * t

    -- Try to maintain color from existing points if possible
    local r, g, b = 1, 1, 1

    -- Find the corresponding point in the old system (based on relative position)
    if self.num_points > 1 then
      local old_index = math.floor((t * (self.num_points - 1)) + 0.5) + 1
      old_index = math.min(old_index, self.num_points)

      if self.points[old_index] then
        r = self.points[old_index].r or 1
        g = self.points[old_index].g or 1
        b = self.points[old_index].b or 1
      end
    end

    new_points[i] = {x = x, y = 0, r = r, g = g, b = b}
    new_velocities[i] = {x = 0, y = 0}
    new_forces[i] = {x = 0, y = 0}
    new_anchored[i] = (i == 1 or i == num_points) -- Anchor first and last points
  end

  -- Update system properties
  self.points = new_points
  self.velocities = new_velocities
  self.anchored = new_anchored
  self.forces = new_forces
  self.num_points = num_points

  -- Recreate springs
  self.springs = {}
  local rest_length = 2 / (num_points - 1)

  for i = 1, num_points - 1 do
    table.insert(self.springs, {
      p1 = i,
      p2 = i + 1,
      k = spring_constant,
      rest_length = rest_length
    })
  end

  -- Restore user parameters
  self:set_spring_constant(spring_constant)
  self:set_damping(damping)
  self:set_gravity(gravity)
  self:set_time_step(time_step)

  return self
end

return SpringSystem
