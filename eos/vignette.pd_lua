local V = pd.Class:new():register("vignette")

function V:initialize(sel, atoms)
  self.screenunit = 1.0 / 2047.0
  self.inlets = 2
  self.outlets = 2
  self.x = 0
  self.y = 0
  self.inner_rad = 0.75
  self.outer_rad = 1.0
  self.bypass = false
  self.invert = false
  self.showbounds = true
  self.removeblanks = true

  if atoms[1] and type(atoms[1]) == "number" then
      self.x = atoms[1] * self.screenunit
  end
  if atoms[2] and type(atoms[2]) == "number" then
      self.y = atoms[2] * self.screenunit
  end
  if atoms[3] and type(atoms[3]) == "number" then
      self.inner_rad = atoms[3] * self.screenunit
  end
  if atoms[4] and type(atoms[4]) == "number" then
      self.outer_rad = atoms[4] * self.screenunit
  end

  return true
end

function V:in_2(sel, atoms)
  if sel == "x" then
    self.x = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "y" then
    self.y = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "innerrad" then
    self.inner_rad = math.max(-4095, math.min(4095, atoms[1])) * self.screenunit
  elseif sel == "outerrad" then
    self.outer_rad = math.max(-4095, math.min(4095, atoms[1])) * self.screenunit
  elseif sel == "bypass" then
    self.bypass = (atoms[1] ~= 0)
  elseif sel == "showbounds" then
    self.showbounds = (atoms[1] ~= 0)
  elseif sel == "invert" then
    self.invert = (atoms[1] ~= 0)
  elseif sel == "removeblanks" then
    self.removeblanks = (atoms[1] ~= 0)
  end
end

function V:draw_circle(out, x, y, radius, npoints, color)
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

function V:draw_radiii(out)
  local npoints = 100
  local innercol = {r=0, g=0.5, b=0}
  local outercol = {r=0.5, g=0, b=0}
  self:draw_circle(out, self.x, self.y, self.inner_rad, npoints, innercol)
  self:draw_circle(out, self.x, self.y, self.outer_rad, npoints, outercol)
end


function V:apply_vignette(inp)
  local eos = require("eos")
  local v2 = require("vec2")
  local cs = require("colorspace")
  local npoints = #inp/5
  local origin = {x = self.x, y = self.y}
  local p, d, alpha, incolor, outcolor
  local black = {r=0,g=0,b=0}
  local out = {}

  for i=1,npoints do
    p = eos.pointatindex(inp, i)
    d = v2.dist(origin, p)
    alpha = 1.0 - eos.smoothstep2(self.inner_rad, self.outer_rad, d)
    incolor = eos.getcolor(p)
    outcolor = cs.alpha_blend(incolor, black, alpha)
    eos.setcolor(p, outcolor)
    eos.addpoint2(out, p)
  end

  return out
end

function V:remove_dead_points(inp)
  local eos = require("eos")
  local npoints = #inp/5
  local p, p_prev, p_next
  local out = {}
  for i = 1, npoints do
    p_prev = eos.pointatindex(inp, math.max(1, i-1))
    p = eos.pointatindex(inp, i)
    p_next = eos.pointatindex(inp, math.min(npoints, i+1))

    if i == 1 or i == npoints or not eos.isblank(p) then
      eos.addpoint2(out, p)
    else
      if not (eos.isblank(p_prev) and eos.isblank(p_next)) then
        eos.addpoint2(out, p)
      end
    end
  end
  return out
end


function V:in_1_list(inp)
  local out
  if self.bypass then
    out = inp
  else
    out = self:apply_vignette(inp)
    if self.removeblanks then
      out = self:remove_dead_points(out)
    end
    if self.showbounds then
      self:draw_radiii(out)
    end
  end
  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end
