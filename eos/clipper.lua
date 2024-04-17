local clipper = {}

clipper.rect = {}
clipper.circle = {}
clipper.frustum = {}

function clipper.rect.rect_contains(p, corners)
  return not (p.x < corners[1].x
           or p.x > corners[3].x
           or p.y < corners[1].y
           or p.y > corners[3].y)
end

function clipper.rect.get_corners(rect, originmode)
  local x = rect.x
  local y = rect.y
  local w = rect.w
  local h = rect.h
  if originmode == 0 then
    -- center mode
    local w2 = w / 2.0
    local h2 = h / 2.0
    return {
      {x=x-w2, y = y-h2}, -- top left
      {x=x+w2, y = y-h2}, -- top right 
      {x=x+w2, y = y+h2}, -- bottom right 
      {x=x-w2, y = y+h2}, -- bottom left 
    }
  else
    -- corner mode
    return {
      {x=x,   y=y},
      {x=x+w, y=y },
      {x=x+w, y=y+h},
      {x=x,   y=y+h}
    }
  end
end


function clipper.rect.get_edges(corners)
  local c = corners
  return {
    {c[1], c[2]},
    {c[2], c[3]},
    {c[3], c[4]},
    {c[4], c[1]}
  }
end

-- inp: points array {x, y, r, g, b, ...}
-- rect: {x, y, w, h}
-- originmode: 0 = center origin, 1 = topleft origin
-- invert: boolean, invert clip inside/outside of rect
function clipper.rect.clip1(inp, rect, originmode, invert)
  local eos = require("eos")
  local v2 = require("vec2")
  originmode = originmode or 0
  invert = invert or false
  local out = {}
  local npoints = #inp / 5
  local corners = clipper.rect.get_corners(rect, originmode)
  local edges = clipper.rect.get_edges(corners)

  local function handleIntersection(from, to, color, from_inside)
    for edge_idx = 1, 4 do
      local edge = edges[edge_idx]
      local intersect = v2.line_intersection(from, to, edge[1], edge[2])
      if intersect then
        local outp = {x = intersect.x, y = intersect.y, r = color.r, g = color.g, b = color.b}
        if from_inside then
          assert(outp ~= nil, "clip from_inside: outp is nil")
          -- inside to outside: add intersection, then blank
          eos.addpoint2(out, outp)
          eos.addblank(out, outp)
        else
          assert(outp ~= nil, "clip from outside: outp is nil")
          -- outside to inside: add blank, then intersection
          eos.addblank(out, intersect)
          eos.addpoint2(out, outp)
        end
        -- break -- Assuming only one intersection point is relevant per segment
      end
    end
  end

  for i = 1, npoints do
    local p = eos.pointatindex(inp, i)
    local p_next = eos.pointatindex(inp, math.min(npoints, i + 1))
    local inside = clipper.rect.rect_contains(p, corners)
    local next_inside = clipper.rect.rect_contains(p_next, corners)
    local col
    -- print("IN CLIP: ", i, v2.tostring(p))
    if invert then
      inside = not inside
      next_inside = not next_inside
    end

    if inside then
      eos.addpoint2(out, p) -- point is inside so keep it
      if not next_inside then
        -- segment goes from inside to outside
        col = eos.getcolor(p)
        handleIntersection(p, p_next, col, true)
      end
    else
      if next_inside then
        -- segment goes from outside to inside
        col = eos.getcolor(p_next)
        handleIntersection(p, p_next, col, false)
      else
        -- both points are outside
        -- TODO
      end
    end
  end
  -- print("out " , #out)
  return out
end



function clipper.rect.clip(inp, rect, originmode, invert)
  local eos = require("eos")
  local v2 = require("vec2")
  originmode = originmode or 0
  invert = invert or false
  local out = {}
  local npoints = #inp / 5
  local corners = clipper.rect.get_corners(rect, originmode)
  local edges = clipper.rect.get_edges(corners)

  local function handleIntersection(from, to, color, from_inside)
    local intersections = {}
    for edge_idx = 1, 4 do
      local edge = edges[edge_idx]
      local intersect = v2.line_intersection(from, to, edge[1], edge[2])
      if intersect and v2.is_point_on_segment(intersect, from, to) then
        table.insert(intersections, intersect)
      end
    end
    -- Sort intersections by distance from 'from' point to ensure correct order of insertion
    table.sort(intersections, function(a, b)
      return v2.len(v2.sub(a, from)) < v2.len(v2.sub(b, from))
    end)
    for _, intersection in ipairs(intersections) do
      local outp = {x = intersection.x, y = intersection.y, r = color.r, g = color.g, b = color.b}
      if from_inside then
        eos.addpoint2(out, outp)
        eos.addblank(out, outp) -- End the segment here
      else
        eos.addblank(out, intersection) -- Start the segment here
        eos.addpoint2(out, outp)
      end
    end
  end

  for i = 1, npoints do
    local p = eos.pointatindex(inp, i)
    local p_next = eos.pointatindex(inp, math.min(npoints, i + 1))
    local inside = clipper.rect.rect_contains(p, corners)
    local next_inside = clipper.rect.rect_contains(p_next, corners)
    local col = eos.getcolor(p) or eos.getcolor(p_next)
    if invert then
      inside = not inside
      next_inside = not next_inside
    end

    if inside and not next_inside then
      -- Inside to outside
      eos.addpoint2(out, p)
      handleIntersection(p, p_next, col, true)
    elseif not inside and next_inside then
      -- Outside to inside
      handleIntersection(p, p_next, col, false)
    elseif not inside and not next_inside then
      -- Both points are outside, still need to check if the line crosses the clipping area
      handleIntersection(p, p_next, col, false)
    else
      -- Both points are inside
      eos.addpoint2(out, p)
    end
  end
  return out
end




function clipper.circle.clip(inp, center, radius, invert, highlight)
  local eos = require("eos")
  local v2 = require("vec2")
  local out = {}
  local npoints = #inp / 5

  local function handleIntersection(from, to, color, from_inside)
    local intersects = v2.line_circle_intersection(from, to, center, radius)
    local intersect = intersects[1] or {}
    if #intersects > 0 then
      local outp = {
        x = intersect.x,
        y = intersect.y,
        r = color.r,
        g = color.g,
        b = color.b
      }
      if from_inside then
        -- inside to outside: add intersection, then blank
        eos.addpoint2(out, outp)
        if highlight then
          eos.addpoint(out, outp.x, outp.y, 1, 1, 1)
        end
        eos.addblank(out, outp)
      else
        -- outside to inside: add blank, then intersection
        eos.addblank(out, intersect)
        if highlight then
          eos.addpoint(out, outp.x, outp.y, 1, 1, 1)
        end
        eos.addpoint2(out, outp)
      end
      -- break -- Assuming only one intersection point is relevant per segment
    end
  end

  for i = 1, npoints do
    local p = eos.pointatindex(inp, i)
    local p_next = eos.pointatindex(inp, math.min(npoints, i + 1))
    local inside = v2.circle_contains(p, center, radius)
    local next_inside = v2.circle_contains(p_next, center, radius)
    local col

    if invert then
      inside = not inside
      next_inside = not next_inside
    end

    if inside then
      eos.addpoint2(out, p)
      if not next_inside then
        -- segment goes from inside to outside
        col = eos.getcolor(p)
        handleIntersection(p, p_next, col, true)
      end
    else
      if next_inside then
        -- segment goes from outside to inside
        col = eos.getcolor(p_next)
        handleIntersection(p, p_next, col, false)
      end
    end
  end

  return out
end


function clipper.frustum.nearfar(inpoints, near, far)
  local npoints = #inpoints
  local outpoints = {}
  local near_n = 1 / (far * near)  -- near / (near+far) -- (far - near)
  local far_n = 1.0 -- (far - near) / far

  local function inrange(z)
    -- return z <= near and z >= far
    return z >= near_n and z <= far_n
  end
  local function makeblank(p)
    return {
      x = p.x,
      y = p.y,
      z = p.z,
      r=0, g=0, b=0
    }
  end

  for i = 1, npoints-1 do
    local p1 = inpoints[i]
    local p2 = inpoints[i + 1]



    if inrange(p1.z) then
      table.insert(outpoints, p1)
    end

    -- Check if line crosses the near or far plane
    local crossesNear = (p1.z < near_n and p2.z > near_n)
                     or (p1.z > near_n and p2.z < near_n)
    local crossesFar = (p1.z < far_n and p2.z > far_n)
                    or (p1.z > far_n and p2.z < far_n)
    -- local crossesNear = (p1.z < near and p2.z > near) or (p1.z > near and p2.z < near)
    -- local crossesFar = (p1.z < far and p2.z > far) or (p1.z > far and p2.z < far)

    if crossesNear then
      local t = (near_n - p1.z) / (p2.z - p1.z)
      -- local t = (near - p1.z) / (p2.z - p1.z)
      local intersect = {
        x = p1.x + t * (p2.x - p1.x),
        y = p1.y + t * (p2.y - p1.y),
        z = near_n,
        -- z = near,
        r = p1.r, g=p1.g, b=p1.b
      }

      if inrange(p1.z) and not inrange(p2.z) then
        -- in -> out
        table.insert(outpoints, intersect)
        table.insert(outpoints, makeblank(intersect))
      else
        -- out -> in
        table.insert(outpoints, makeblank(intersect))
        table.insert(outpoints, intersect)
      end
      -- table.insert(outpoints, intersect)

    elseif crossesFar then
      local t = (far_n - p1.z) / (p2.z - p1.z)
      -- local t = (far - p1.z) / (p2.z - p1.z)
      local intersect = {
        x = p1.x + t * (p2.x - p1.x),
        y = p1.y + t * (p2.y - p1.y),
        z = far,
        r = p1.r, g=p1.g, b=p1.b
      }
      if inrange(p1.z) and not inrange(p2.z) then
        -- in -> out
        table.insert(outpoints, intersect)
        table.insert(outpoints, makeblank(intersect))
      else
        -- out -> in
        table.insert(outpoints, makeblank(intersect))
        table.insert(outpoints, intersect)
      end

      -- table.insert(outpoints, intersect)
    end
  end

  local pfinal = inpoints[npoints]
  if inrange(pfinal.z) then
    table.insert(outpoints, pfinal)
  end

  return outpoints
end


