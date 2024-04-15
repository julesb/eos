
local scene3d = {}


-- objects = {
--   { -- object 1
--     {x=0, y=0, z=0, r=0, g=0,b=0},
--     {x=0, y=0, z=0, r=0, g=0,b=0},
--     ...
--   },
--   { -- object 2
--      ...
--   }
-- }

function scene3d.scene(objects)
  local eos = require("eos")
  local v3 = require("vec3")
  local out = {}

  -- local firstvert = objects[1][1]
  -- eos.setcolor(firstvert, {r=0, g=0, b=0})
  -- table.insert(out, firstvert)

  for _, object in ipairs(objects) do

    -- local firstvert = object[1]
    -- eos.setcolor(firstvert, {r=0, g=0, b=0})
    -- table.insert(out, firstvert)

    for _, vert in ipairs(object) do
      table.insert(out, vert)
    end
    -- insert a blank at object final vert position
    local finalvert = v3.copy(object[#object])
    eos.setcolor(finalvert, {r=0, g=0, b=0})
    table.insert(out, finalvert)
  end

  local finalvert = v3.copy(out[#out])
  eos.setcolor(finalvert, {r=0, g=0, b=0})
  table.insert(out, finalvert)

  return out
end

function scene3d.add_object(scene, object)
  local eos = require("eos")
  local v3 = require("vec3")
  for _, point in ipairs(object) do
    table.insert(scene, point)
  end

  local finalp = v3.copy(object[#object])
  if not eos.isblank(finalp) then
    finalp.r = 0
    finalp.g = 0
    finalp.b = 0
    table.insert(scene, finalp)
  end
end







return scene3d
