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




function vec2.line_circle_intersection(line_p1, line_p2,
                                       circle_pos, circle_rad)
  local function vec(from, to)
    return {x = to.x - from.x, y = to.y - from.y}
  end

  local function is_point_on_segment(p, seg_p1, seg_p2)
    return math.min(seg_p1.x, seg_p2.x) <= p.x
           and p.x <= math.max(seg_p1.x, seg_p2.x)
           and math.min(seg_p1.y, seg_p2.y) <= p.y
           and p.y <= math.max(seg_p1.y, seg_p2.y)
  end

  -- Vector from line_p1 to line_p2
  local line_vec = vec(line_p1, line_p2)
  -- Vector from line_p1 to circle_pos
  local to_circle_vec = vec(line_p1, circle_pos)
  -- Project to_circle_vec onto line_vec
  local line_dir = vec2.normalize(line_vec)
  local proj_length = vec2.dot(to_circle_vec, line_dir)
  local proj_point = {
    x = line_p1.x + line_dir.x * proj_length,
    y = line_p1.y + line_dir.y * proj_length
  }

  -- Distance from the circle's center to the projection point
  local dist_to_circle = vec2.len(vec(circle_pos, proj_point))

  local intersections = {}
  if dist_to_circle < circle_rad then
    -- Calculate the distance from the projection point to the intersection points
    local offset = math.sqrt(circle_rad^2 - dist_to_circle^2)

    -- First intersection point
    local int_point1 = {
      x = proj_point.x + line_dir.x * offset,
      y = proj_point.y + line_dir.y * offset
    }
    -- Check if the intersection point is on the segment
    if is_point_on_segment(int_point1, line_p1, line_p2) then
      table.insert(intersections, int_point1)
    end

    -- Second intersection point (if offset is not zero)
    if offset > 0 then
      local int_point2 = {
        x = proj_point.x - line_dir.x * offset,
        y = proj_point.y - line_dir.y * offset
      }
      -- Check if the intersection point is on the segment
      if is_point_on_segment(int_point2, line_p1, line_p2) then
        table.insert(intersections, int_point2)
      end
    end
  elseif dist_to_circle == circle_rad then
    -- The line is tangent to the circle, check if the tangent point is on the segment
    if is_point_on_segment(proj_point, line_p1, line_p2) then
      table.insert(intersections, proj_point)
    end
  end
  -- No else case needed, as no intersections would mean an empty table is returned

  return intersections
end

return vec2
