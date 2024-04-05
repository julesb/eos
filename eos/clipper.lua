local clipper = {}

clipper.rect = {}
clipper.circle = {}

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

-- points: array {{x=0, y=1, r=1, g=1, b=1}, ...}
-- rect: {x, y, w, h}
-- originmode: 0 = center origin, 1 = topleft origin
-- invert: boolean, invert clip inside/outside of rect
function clipper.rect.clip(inp, rect, originmode, invert)
  local eos = require("eos")
  local v2 = require("vec2")
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
          -- inside to outside: add intersection, then blank
          eos.addpoint2(out, outp)
          eos.addblank(out, outp)
        else
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




return clipper
