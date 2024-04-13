
local mat4 = {}

function mat4.identity()
  return {
    {1, 0, 0, 0},
    {0, 1, 0, 0},
    {0, 0, 1, 0},
    {0, 0, 0, 1}
  }
end

function mat4.translate(x, y, z)
    return {
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {x, y, z, 1}
    }
end

function mat4.scale(sx, sy, sz)
  return {
    {sx, 0,  0,  0},
    {0,  sy, 0,  0},
    {0,  0,  sz, 0},
    {0,  0,  0,  1}
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

function mat4.transform(v, m)
  local vec3 = require("vec3")
  -- print("transform(): V: ", vec3.tostring(v))
  -- print("transform(): M:")
  -- print(mat4.tostring(m))

  local result = vec3.new(0, 0, 0)
  result.x = v.x*m[1][1] + v.y*m[2][1] + v.z*m[3][1] + m[4][1]
  result.y = v.x*m[1][2] + v.y*m[2][2] + v.z*m[3][2] + m[4][2]
  result.z = v.x*m[1][3] + v.y*m[2][3] + v.z*m[3][3] + m[4][3]

  local w = v.x*m[1][4] + v.y*m[2][4] + v.z*m[3][4] + m[4][4]
  -- print ("transform(): W: ", w)
  -- Divide by w to normalize (homogeneous coordinates)
  if w ~= 0 then
    result.x = result.x / w
    result.y = result.y / w
    result.z = result.z / w
  end
  -- print ("transform(): RESULT: ", vec3.tostring(result))
  return result
end






function mat4.lookat(view_pos, lookat_pos, up)
  local v3 = require("vec3")
  print(string.format("view: %s\nlookat: %s\nup: %s",
                      v3.tostring(view_pos),
                      v3.tostring(lookat_pos),
                      v3.tostring(up)))
  up  = v3.normalize(up)
  local zaxis = v3.normalize(v3.sub(lookat_pos, view_pos)) -- Forward
  local xaxis = v3.normalize(v3.cross(up, zaxis)) -- Right
  local yaxis = v3.normalize(v3.cross(zaxis, xaxis)) -- True up
  local dpx = -v3.dot(xaxis, view_pos)
  local dpy = -v3.dot(yaxis, view_pos)
  local dpz = -v3.dot(zaxis, view_pos)

return {
    { xaxis.x, yaxis.x, zaxis.x, 0 },
    { xaxis.y, yaxis.y, zaxis.y, 0 },
    { xaxis.z, yaxis.z, zaxis.z, 0 },
    { dpx,     dpy,     dpz,     1 }
  }
end




function mat4.perspective (fov, aspect, near, far)
  local f = 1.0 / math.tan(fov / 2.0);
  local xpr = f / aspect;
  local ypr = f;
  local fmn = (far - near);
  local zpr = (far + near) / fmn;
  local zhpr = (2.0 * far * near) / fmn;
  local proj = {
    {xpr,   0,    0,    0},
    {  0, ypr,    0,    0},
    {  0,   0,  zpr, zhpr},
    {  0,   0,   -1,    1}
  }

  return proj
end


function mat4.camera(points, view_pos, lookat_pos, up, fov,
                     aspect, near, far)
  local view_matrix = mat4.lookat(view_pos, lookat_pos, up)
  print("VIEW MATRIX")
  print(mat4.tostring(view_matrix))
  local proj_matrix = mat4.perspective(fov, aspect, near, far)
  print("PROJ MATRIX")
  print(mat4.tostring(proj_matrix))

  local vp_matrix = mat4.multiply(view_matrix, proj_matrix)
  -- local vp_matrix = mat4.multiply(proj_matrix, view_matrix)
  -- print("VP MATRIX\n", mat4.tostring(vpMatrix))

  local transformedPoints = {}

  -- print("BEFORE TRANSFORM POINTS")
  for _, point in ipairs(points) do
    -- print("IN CAMERA", v3.tostring(point))
    local point_tx = mat4.transform(point, vp_matrix)
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

