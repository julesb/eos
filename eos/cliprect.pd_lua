local cliprect = pd.Class:new():register("cliprect")

function cliprect:initialize(sel, atoms)
  self.screenunit = 1.0 / 2047.0
  self.inlets = 2
  self.outlets = 2

  self.rect = {
    x = 0,
    y=0,
    w=0.5,
    h=0.5
  }

  self.originmode = 0 -- 0 = center, 1 = corner
  self.invert = false
  self.showbounds = true
  self.bypass = false

  self.originmodes = {
    center = 0,
    corner = 1
  }

  if atoms[1] and type(atoms[1]) == "number" then
      self.rect.x = atoms[1] * self.screenunit
  end
  if atoms[2] and type(atoms[2]) == "number" then
      self.rect.y = atoms[2] * self.screenunit
  end
  if atoms[3] and type(atoms[3]) == "number" then
      self.rect.w = atoms[3] * self.screenunit
  end
  if atoms[4] and type(atoms[4]) == "number" then
      self.rect.h = atoms[4] * self.screenunit
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
    self.rect.x = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "y" then
    self.rect.y = math.max(-2047, math.min(2047, atoms[1])) * self.screenunit
  elseif sel == "width" then
    self.rect.w = math.max(-4095, math.min(4095, atoms[1])) * self.screenunit
  elseif sel == "height" then
    self.rect.h = math.max(-4095, math.min(4095, atoms[1])) * self.screenunit
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
  local clipper = require("clipper")
  local corners = clipper.rect.get_corners( self.rect, self.originmode)
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


function cliprect:in_1_list(inp)
  local eos = require("eos")
  local clipper = require("clipper")
  local out
  if self.bypass then
    out = inp
  else
    out = clipper.rect.clip( inp, self.rect, self.originmode, self.invert)
    if self.boundsvisible then
      self:draw_region(out)
    end
    if #out == 0 then eos.addblank(out, {x=0,y=0}) end
  end
  eos.addblank(out, eos.pointatindex(out, #out/5))

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end
