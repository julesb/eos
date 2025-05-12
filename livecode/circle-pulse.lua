-- test.lua
local  amplitude = 0.8
local  frequency = 2.5
local  points = 1000

function init()
  print("init")
  -- amplitude = 0.8
  -- frequency = 2.5
  -- points = 900
end



function animate(time)
  local laserPoints = {}

  -- Create a circle that pulses with time
  for i = 1, points do
    local angle = (i-1) * (2 * math.pi / points)
    local minrad = 0.1
    local radius = minrad + (amplitude-minrad) * (0.5 + 0.5 * math.sin(time * frequency))

    local x = radius * math.cos(angle)
    local y = radius * math.sin(angle)

    -- RGB based on position
    local r = 0.5 + 0.5 * math.sin(time)
    local g = 0.5 + 0.5 * math.sin(time + math.pi/2)
    local b = 0.5 + 0.5 * math.sin(time + math.pi)

    -- Add point (x, y, r, g, b)
    table.insert(laserPoints, x)
    table.insert(laserPoints, y)
    table.insert(laserPoints, r)
    table.insert(laserPoints, g)
    table.insert(laserPoints, b)
  end

  laser.send(laserPoints)
end

function cleanup()
  print("cleanup")
  laser.send({0, 0, 0, 0, 0}) -- blank at 0,0
end
