
local mat4 = {}

function mat4.identity()
    return {
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 0, 1}
    }
end

function mat4.tostring(m)
    local rows = #m
    local result = {}
    for i = 1, rows do
        local row = m[i]
        -- Assuming each row is also a table with exactly 4 elements
        table.insert(result, string.format("{% 8.3f, % 8.3f, % 8.3f, % 8.3f}", row[1], row[2], row[3], row[4]))
    end
    return table.concat(result, "\n")
end


function mat4.multiply(m1, m2)
    local result = {}
    for i = 1, 4 do
        result[i] = {}
        for j = 1, 4 do
            result[i][j] = 0
            for k = 1, 4 do
                result[i][j] = result[i][j] + m1[i][k] * m2[k][j]
            end
        end
    end
    return result
end



function mat4.lookAt(view_pos, lookat_pos, up)
    local v3 = require("vec3")
    -- print(string.format("view: %s, lookat: %s, up: %s",
    --                     v3.tostring(view_pos),
    --                     v3.tostring(lookat_pos),
    --                     v3.tostring(up)))
    up  = v3.normalize(up)
    local zaxis = v3.normalize(v3.sub(lookat_pos, view_pos)) -- Forward
    local xaxis = v3.normalize(v3.cross(up, zaxis)) -- Right
    local yaxis = v3.cross(zaxis, xaxis) -- True up

    local view = mat4.identity()

    view[1][1], view[2][1], view[3][1] = xaxis.x, xaxis.y, xaxis.z
    view[1][2], view[2][2], view[3][2] = yaxis.x, yaxis.y, yaxis.z
    view[1][3], view[2][3], view[3][3] = zaxis.x, zaxis.y, zaxis.z

    view[4][1] = -v3.dot(xaxis, view_pos)
    view[4][2] = -v3.dot(yaxis, view_pos)
    view[4][3] = -v3.dot(zaxis, view_pos)

    return view
end


function mat4.perspective(fov, aspect, near, far)
    local tanHalfFOV = math.tan(math.rad(fov) / 2)
    local range = near - far

    local proj = {
        {1 / (aspect * tanHalfFOV), 0, 0, 0},
        {0, 1 / tanHalfFOV, 0, 0},
        {0, 0, (near + far) / range, (2 * near * far) / range},
        {0, 0, -1, 0}
    }

    return proj
end

        -- y = v.y or 0.0
function mat4.camera(points, view_pos, lookat_pos, up, fov, aspect, near, far)
  local v3 = require("vec3")
  local viewMatrix = mat4.lookAt(view_pos, lookat_pos, up)
  print("VIEW MATRIX\n", mat4.tostring(viewMatrix))
  local projectionMatrix = mat4.perspective(fov, aspect, near, far)
  -- print("PROJ MATRIX\n", mat4.tostring(projectionMatrix))
  local vpMatrix = mat4.multiply(projectionMatrix, viewMatrix)
  -- print("VP MATRIX\n", mat4.tostring(vpMatrix))

  local transformedPoints = {}

  -- print("BEFORE TRANSFORM POINTS")
  for _, point in ipairs(points) do
    -- print(v3.tostring(point))
    local point_tx = v3.transform(point, vpMatrix)
    table.insert(transformedPoints, {
      x = point_tx.x,
      y = point_tx.y,
      r = point.r,
      g = point.g,
      b = point.b
    })
  end

  -- print("AFTER TRANSFORM POINTS")
  return transformedPoints
end



return mat4

