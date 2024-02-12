
local CH = pd.Class:new():register("convexhull")

function CH:initialize(sel, atoms)
    self.inlets = 1
    self.outlets = 1
    return true
end

local function cross(o, a, b)
  return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
end

local function convex_hull(points)
  table.sort(points,
             function(a, b) return a.y < b.y or (a.y == b.y and a.x < b.x) end)
  local n = #points
  if n < 3 then return points end

  local lower = {}
  for i = 1, n do
    while (#lower >= 2
           and cross(lower[#lower - 1], lower[#lower], points[i]) <= 0) do
      table.remove(lower)
    end
    table.insert(lower, points[i])
  end

  local upper = {}
  for i = n, 1, -1 do
    while (#upper >= 2
           and cross(upper[#upper - 1], upper[#upper], points[i]) <= 0) do
      table.remove(upper)
    end
    table.insert(upper, points[i])
  end

  -- Concatenate the lower and upper hulls to form the convex hull.
  -- Remove the last point of each list since it's the same as the first point of the other list.
  table.remove(lower)
  table.remove(upper)
  for _, p in ipairs(upper) do
    table.insert(lower, p)
  end

  return lower
end

function CH:in_1_list(inp)
    local eos = require("eos")
    local in_points = eos.xyrgb_to_points(inp)
    local hull = convex_hull(in_points)
    if #hull > 2 then -- loop back to first point
      table.insert(hull, hull[1])
    end
    for i=1, #hull do
      hull[i].r = 1
      hull[i].g = 1
      hull[i].b = 1
    end
    local out = eos.points_to_xyrgb(hull)
    self:outlet(1, "list", out)
end


