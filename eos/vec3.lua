
local vec3 = {}

function vec3.new(_x, _y, _z)
    return {
        x = _x or 0.0,
        y = _y or 0.0,
        z = _z or 0.0
    }
end

function vec3.add(v1, v2)
    return {
        x = v1.x + v2.x,
        y = v1.y + v2.y,
        z = v1.z + v2.z
    }
end

function vec3.sub(v1, v2)
    return {
        x = v1.x - v2.x,
        y = v1.y - v2.y,
        z = v1.z - v2.z
    }
end

function vec3.mul(v1, v2)
    return {
        x = v1.x * v2.x,
        y = v1.y * v2.y,
        z = v1.z * v2.z
    }
end

function vec3.div(v1, v2)
    return {
        x = v1.x / v2.x,
        y = v1.y / v2.y,
        z = v1.z / v2.z
    }
end

function vec3.scale(v, scale)
    return {
        x = v.x * scale,
        y = v.y * scale,
        z = v.z * scale
    }
end

function vec3.abs(v)
    return {
        x = math.abs(v.x),
        y = math.abs(v.y),
        z = math.abs(v.z)
    }
end


function vec3.len(v)
    return math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
end

function vec3.dist(v1, v2)
    return vec3.len(vec3.sub(v1, v2))
end

function vec3.normalize(v)
    local len = vec3.len(v)
    if len > 0 then
        return {
            x = v.x / len,
            y = v.y / len,
            z = v.z / len
        }
    else
        return {x=0.0, y=0.0, z=0.0}
    end
end

function vec3.copy(v)
    return {
        x = v.x or 0.0,
        y = v.y or 0.0,
        z = v.z or 0.0
    }
end

function vec3.tostring(v)
  if v == nil then
    return "nil vector"
  else
    local x = v.x and string.format("% 1.3f", v.x) or "nil"
    local y = v.y and string.format("% 1.3f", v.y) or "nil"
    local z = v.z and string.format("% 1.3f", v.z) or "nil"
    local r = v.r and string.format("%.3f", v.r) or "nil"
    local g = v.g and string.format("%.3f", v.g) or "nil"
    local b = v.b and string.format("%.3f", v.b) or "nil"
    return string.format("{x=%s, y=%s, z=%s, r=%s, g=%s, b=%s}",
                         x, y, z, r, g, b)
    -- return string.format("[% 1.3f, % 1.3f, % 1.3f][% 1.3f, % 1.3f, % 1.3f]", v.x, v.y, v.z)
  end
end

function vec3.rand()
    return {
        x = 2.0 * math.random() - 1.0,
        y = 2.0 * math.random() - 1.0,
        z = 2.0 * math.random() - 1.0
    }
end

function vec3.random_unit()
    local theta = math.random() * 2 * math.pi
    local phi = math.acos(2 * math.random() - 1)
    return {
      x = math.sin(phi) * math.cos(theta),
      y = math.sin(phi) * math.sin(theta),
      z = math.cos(phi)}
end


function vec3.dist_sqr(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

function vec3.dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

function vec3.cross(v1, v2)
    return {
        x = v1.y * v2.z - v1.z * v2.y,
        y = v1.z * v2.x - v1.x * v2.z,
        z = v1.x * v2.y - v1.y * v2.x
    }
end

function vec3.equal(v1, v2)
    return v1.x == v2.x and v1.y == v2.y and v1.z == v2.z
end

function vec3.rotate_axis_angle(v, axis, angle_rads)
  local c = math.cos(angle_rads)
  local s = math.sin(angle_rads)
  local t = 1 - c
  local x = axis.x
  local y = axis.y
  local z = axis.z

  local rx = x * (x * t + c)
  local ry = x * (y * t + s * z)
  local rz = x * (z * t - s * y)
  local vx = y * (x * t - s * z)
  local vy = y * (y * t + c)
  local vz = y * (z * t + s * x)
  local wx = z * (x * t + s * y)
  local wy = z * (y * t - s * x)
  local wz = z * (z * t + c)

  return {
    x = v.x * rx + v.y * vx + v.z * wx,
    y = v.x * ry + v.y * vy + v.z * wy,
    z = v.x * rz + v.y * vz + v.z * wz
  }
end

function vec3.cartesian_to_spherical(v)
    local r = math.sqrt(v.x^2 + v.y^2 + v.z^2)
    local azimuth = math.atan(v.y, v.x)
    if azimuth < 0 then
        azimuth = azimuth + 2 * math.pi  -- Normalize azimuth to 0 to 2*pi
    end
    local altitude = math.asin(v.z / r)
    return altitude, azimuth
end

return vec3
