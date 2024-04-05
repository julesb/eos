local clip = pd.Class:new():register("clipcircle")

function clip:initialize(sel, atoms)
  self.screenunit = 1.0 / 2047.0
  self.inlets = 2
  self.outlets = 2
  self.center = {x=0, y=0}
  self.radius = 0.5
  self.bypass = false
  self.invert = false
  self.showbounds = true
  self.highlight = true

  if atoms[1] and type(atoms[1]) == "number" then
    self.center.x = atoms[1] * self.screenunit
  end
  if atoms[2] and type(atoms[2]) == "number" then
    self.center.y = atoms[1] * self.screenunit
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
  elseif sel == "highlight" then
    self.highlight = (atoms[1] ~= 0)
  end
end

function clip:draw_circle(out, center, radius, npoints, color)
  local eos = require("eos")
  local ang_step = (2.0 * math.pi) / npoints
  local xr, yr
  local cpoints = {}
  for s = 0, npoints-1 do
    local cosr = math.cos(ang_step * s)
    local sinr = math.sin(ang_step * s)
    local p = { x = 1.0, y = 0.0 }
    xr = center.x + radius * (p.x * cosr - p.y * sinr)
    yr = center.y + radius * (p.y * cosr + p.x * sinr)
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
  self:draw_circle(out, self.center, self.radius, npoints, col)
end


function clip:in_1_list(inp)
  local eos = require("eos")
  local clipper = require("clipper")
  local out = {}
  if self.bypass then
    out = inp or {}
  else
    out = clipper.circle.clip(inp, self.center, self.radius, self.invert, self.highlight)
    if self.boundsvisible then
      self:draw_region(out)
    end
    if #out == 0 then eos.addblank(out, {x=0,y=0}) end
  end
  eos.addblank(out, eos.pointatindex(out, #out/5))

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end
