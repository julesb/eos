local cliprect = pd.Class:new():register("cliprect")

function cliprect:initialize(sel, atoms)
  self.screenunit = 1.0 / 2047.0
  self.inlets = 2
  self.outlets = 2
  self.x = 0
  self.y = 0
  self.w = 0.5
  self.h = 0.5

  self.originmode = 0 -- 0 = center, 1 = corner
  self.bypass = false
  self.originmodes = {
    center = 0,
    corner = 1
  }
  self.invert = false
  self.showbounds = true

  if atoms[1] and type(atoms[1]) == "number" then
      self.x = atoms[1] * self.screenunit
  end
  if atoms[2] and type(atoms[2]) == "number" then
      self.y = atoms[2] * self.screenunit
  end
  if atoms[3] and type(atoms[3]) == "number" then
      self.w = atoms[3] * self.screenunit
  end
  if atoms[4] and type(atoms[4]) == "number" then
      self.h = atoms[4] * self.screenunit
  end
  if type(atoms[5]) == "string" then
    if self.originmodes[atoms[5]] ~= nil then
      self.originmode = self.originmodes[atoms[5]]
    end
  end

  return true
end

function cliprect:in_2(sel, atoms)
  if sel == "x" then
    self.x = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "y" then
    self.y = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "width" then
    self.w = math.max(-4095, math.min(4095, atoms[1])) * self.screenunit
  elseif sel == "height" then
    self.h = math.max(-4095, math.min(4095, atoms[1])) * self.screenunit
  elseif sel == "originmode" then
    self.originmode = math.floor(math.max(0, math.min(1, atoms[1])))
  elseif sel == "bypass" then
    self.bypass = (atoms[1] ~= 0)
  elseif sel == "boundsvisible" then
    self.boundsvisible = (atoms[1] ~= 0)
  elseif sel == "invert" then
    self.invert = (atoms[1] ~= 0)
  end
end

function cliprect:draw_region(out)
  local eos = require("eos")
  local corners = self:get_corners()
  local col = {r=0.15, g=0.15, b=0.25}
  eos.setcolor(corners[1], col)
  eos.setcolor(corners[2], col)
  eos.setcolor(corners[3], col)
  eos.setcolor(corners[4], col)
  eos.addpoint(out, corners[1].x, corners[1].y, 0,0,0)
  eos.addpoint2(out, corners[1])
  eos.addpoint2(out, corners[2])
  eos.addpoint2(out, corners[3])
  eos.addpoint2(out, corners[4])
  eos.addpoint2(out, corners[1])
  eos.addpoint(out, corners[1].x, corners[1].y, 0,0,0)
end

function cliprect:get_corners()
  if self.originmode == 0 then
    -- center mode
    local w2 = self.w / 2.0
    local h2 = self.h / 2.0
    return {
      {x=self.x-w2, y = self.y-h2}, -- top left
      {x=self.x+w2, y = self.y-h2}, -- top right 
      {x=self.x+w2, y = self.y+h2}, -- bottom right 
      {x=self.x-w2, y = self.y+h2}, -- bottom left 
    }
  else
    -- corner mode
    return {
      {x=self.x,        y=self.y},
      {x=self.x+self.w, y=self.y },
      {x=self.x+self.w, y=self.y+self.h},
      {x=self.x,        y=self.y+self.h}
    }
  end
end


function cliprect:get_edges(corners)
  local c = corners
  return {
    {c[1], c[2]},
    {c[2], c[3]},
    {c[3], c[4]},
    {c[4], c[1]}
  }
end


function cliprect:region_contains(p, corners)
  return not (p.x < corners[1].x
           or p.x > corners[3].x
           or p.y < corners[1].y
           or p.y > corners[3].y)
end


function cliprect:line_intersection(p1, p2, q1, q2)
  local r_px, r_py = p2.x - p1.x, p2.y - p1.y
  local s_qx, s_qy = q2.x - q1.x, q2.y - q1.y
  local rxs = r_px * s_qy - r_py * s_qx
  local qpxr = (q1.x - p1.x) * r_py - (q1.y - p1.y) * r_px
  -- If rxs is 0, lines are parallel or coincident
  if rxs == 0 then return nil end
  local t = ((q1.x - p1.x) * s_qy - (q1.y - p1.y) * s_qx) / rxs
  local u = qpxr / rxs
  if (t >= 0 and t <= 1) and (u >= 0 and u <= 1) then
    -- Intersection point
    return {x = p1.x + t * r_px, y = p1.y + t * r_py}
  else
    return nil
  end
end


function cliprect:clip_array(inp)
  local eos = require("eos")
  local out = {}
  local npoints = #inp / 5
  local corners = self:get_corners()
  local edges = self:get_edges(corners)

  local function handleIntersection(from, to, color, from_inside)
    for edge_idx = 1, 4 do
      local edge = edges[edge_idx]
      local intersect = self:line_intersection(from, to, edge[1], edge[2])
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
    local inside = self:region_contains(p, corners)
    local next_inside = self:region_contains(p_next, corners)
    local col

    if self.invert then
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


function cliprect:in_1_list(inp)
  local eos = require("eos")
  local out
  if self.bypass then
    out = inp
  else
    out = self:clip_array(inp)
    if self.boundsvisible then
      self:draw_region(out)
    end
    if #out == 0 then eos.addblank(out, {x=0,y=0}) end
  end
  eos.addblank(out, eos.pointatindex(out, #out/5))

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end
