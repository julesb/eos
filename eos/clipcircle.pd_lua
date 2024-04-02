local clip = pd.Class:new():register("clipcircle")

function clip:initialize(sel, atoms)
  self.screenunit = 1.0 / 2047.0
  self.inlets = 2
  self.outlets = 2
  self.x = 0
  self.y = 0
  self.radius = 0.5
  self.bypass = false
  self.invert = false
  self.showbounds = true

  if atoms[1] and type(atoms[1]) == "number" then
      self.x = atoms[1] * self.screenunit
  end
  if atoms[2] and type(atoms[2]) == "number" then
      self.y = atoms[2] * self.screenunit
  end
  if atoms[3] and type(atoms[3]) == "number" then
      self.radius = atoms[3] * self.screenunit
  end

  return true
end

function clip:in_2(sel, atoms)
  if sel == "x" then
    self.x = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "y" then
    self.y = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "radius" then
    self.radius = atoms[1] * self.screenunit
  elseif sel == "bypass" then
    self.bypass = (atoms[1] ~= 0)
  elseif sel == "boundsvisible" then
    self.boundsvisible = (atoms[1] ~= 0)
  elseif sel == "invert" then
    self.invert = (atoms[1] ~= 0)
  end
end

function clip:draw_circle(out, x, y, radius, npoints, color)
  local eos = require("eos")
  local ang_step = (2.0 * math.pi) / npoints
  local xr, yr
  local cpoints = {}
  for s = 0, npoints-1 do
    local cosr = math.cos(ang_step * s)
    local sinr = math.sin(ang_step * s)
    local p = { x = 1.0, y = 0.0 }
    xr = x + radius * (p.x * cosr - p.y * sinr)
    yr = y + radius * (p.y * cosr + p.x * sinr)
    -- blank before first point
    if s == 0 then
      eos.addpoint(cpoints, xr, yr, 0,0,0)
    end
    eos.addpoint(cpoints, xr, yr, color.r, color.g, color.b)
  end

  -- loop back to first point
  eos.addpoint(cpoints, cpoints[1], cpoints[2], color.r, color.g, color.b)
  -- final blank
  eos.addpoint(cpoints, cpoints[1], cpoints[2], 0,0,0)

  for i=1,#cpoints do
    table.insert(out, cpoints[i])
  end

end


function clip:draw_region(out)
  local npoints = 32
  local col = {r=0, g=0.5, b=0}
  self:draw_circle(out, self.x, self.y, self.radius, npoints, col)
end


function clip:circle_contains(p, c, r)
  local v2 = require("vec2")
  return (v2.len(v2.sub(p, c)) < r)
end

function clip:clip_array(inp)
  local eos = require("eos")
  local v2 = require("vec2")
  local out = {}
  local npoints = #inp / 5
  local c = {x=self.x, y=self.y}
  -- local corners = self:get_corners()
  -- local edges = self:get_edges(corners)

  local function handleIntersection(from, to, color, from_inside)

    local intersects = v2.line_circle_intersection(from, to, c, self.radius)
    local intersect = intersects[1] or {}
    if #intersects > 0 then
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

  for i = 1, npoints do
    local p = eos.pointatindex(inp, i)
    local p_next = eos.pointatindex(inp, math.min(npoints, i + 1))
    local c = {x = self.x, y = self.y}
    local inside = self:circle_contains(p, c, self.radius)
    local next_inside = self:circle_contains(p_next, c, self.radius)
    -- local inside = self:region_contains(p, corners)
    -- local next_inside = self:region_contains(p_next, corners)
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


function clip:in_1_list(inp)
  local eos = require("eos")
  local out = {}
  if self.bypass then
    out = inp or {}
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
