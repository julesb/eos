local vec2 = {}

function vec2.new(_x, _y)
    return {
        x = _x or 0.0,
        y = _y or 0.0
    }
end

function vec2.add(v1, v2)
    return {
        x = v1.x + v2.x,
        y = v1.y + v2.y
    }
end

function vec2.sub(v1, v2)
    return {
        x = v1.x - v2.x,
        y = v1.y - v2.y
    }
end

function vec2.mul(v1, v2)
    return {
        x = v1.x * v2.x,
        y = v1.y * v2.y
    }
end

function vec2.div(v1, v2)
    return {
        x = v1.x / v2.x,
        y = v1.y / v2.y
    }
end

function vec2.scale(v, scale)
    return {
        x = v.x * scale,
        y = v.y * scale
    }
end

function vec2.len(v)
    return math.sqrt(v.x*v.x + v.y*v.y)
end

function vec2.dist(v1, v2)
    return vec2.len(vec2.sub(v1, v2))
end

function vec2.normalize(v)
    local len = vec2.len(v)
    if len > 0 then
        return {
            x = v.x / len,
            y = v.y / len
        }
    else
        return {x=0.0, y=0.0}
    end
end

function vec2.tostring(v)
    if v == nil then
      return "nil vector"
    else
      return string.format("[% 1.3f, % 1.3f]", v.x, v.y)
    end

end

function vec2.rotate(p, deg)
    local rads = math.rad(deg)
    local cosr = math.cos(rads)
    local sinr = math.sin(rads)
    return {
        x = (p.x * cosr - p.y * sinr),
        y = (p.y * cosr + p.x * sinr)
    }
end

function vec2.limit(v, max)
    local mag = vec2.len(v)
    if mag > max then
        return vec2.scale(v, max / mag)
    else
        return v
    end
end

function vec2.rand()
    return {
        x = 2.0 * math.random() - 1.0,
        y = 2.0 * math.random() - 1.0
    }
end

function vec2.randdir()
  local a = math.random() * math.pi * 2.0
  return {
    x = math.cos(a),
    y = math.sin(a)
  }
end

function vec2.dist_sqr(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx * dx + dy * dy
end

function vec2.dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end


function vec2.angle_between(v1, v2)
    local v1_norm = vec2.normalize(v1)
    local v2_norm = vec2.normalize(v2)
    local dot_product = vec2.dot(v1_norm, v2_norm)
    local angle_rad = math.acos(dot_product)
    return math.deg(angle_rad) -- Return the angle in degrees
end

function vec2.equal(v1, v2)
  return v1.x == v2.x and v1.y == v2.y
end

return vec2
