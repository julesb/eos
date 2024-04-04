
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

function vec3.tostring(v)
    if v == nil then
        return "nil vector"
    else
        return string.format("[% 1.3f, % 1.3f, % 1.3f]", v.x, v.y, v.z)
    end
end

function vec3.rand()
    return {
        x = 2.0 * math.random() - 1.0,
        y = 2.0 * math.random() - 1.0,
        z = 2.0 * math.random() - 1.0
    }
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


function vec3.transform(v, m)
    local result = vec3.new(0, 0, 0)
    result.x = v.x*m[1][1] + v.y*m[2][1] + v.z*m[3][1] + m[4][1]
    result.y = v.x*m[1][2] + v.y*m[2][2] + v.z*m[3][2] + m[4][2]
    result.z = v.x*m[1][3] + v.y*m[2][3] + v.z*m[3][3] + m[4][3]
    local w = v.x*m[1][4] + v.y*m[2][4] + v.z*m[3][4] + m[4][4]

    -- Divide by w to normalize (homogeneous coordinates)
    if w ~= 0 then
        result.x = result.x / w
        result.y = result.y / w
        result.z = result.z / w
    end

    return result
end


return vec3
