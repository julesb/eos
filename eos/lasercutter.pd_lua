local lasercutter = pd.Class:new():register("lasercutter")

local eos = require("eos")
local v2 = require("vec2")

function lasercutter:initialize(sel, atoms)
  self.inlets = 3
  self.outlets = 3
  self.npoints = 100
  self.aspectratio = 1.0
  self.time = 0.0
  self.trailstep = 0.01
  self.expand = 5
  self.headcol = { r=0.8, g=0.8, b=1.0 }
  self.blankcol = { r=0.25, g=0.0, b=0.0 }

  self.headrepeat = 1
  self.mirror = false

  self.headprev = v2.new(0, 0)
  self.drawtrail = false

  self.frame = nil
  self.currentindex = 1

  self.psys = require("particlesys")

  self.psysconfig = {
    maxparticles = 200,
    lifespan = 0.5,
    emitprobability = 0.975,
    meanvelocity = 0.25,
    gravity = {x=0, y=3}
  }
  self.psys.init(self.psysconfig)
  return true
end


function lasercutter:in_1_bang()
  local out = {}
  -- local t = self.time

  if self.frame == nil or #self.frame == 0 then
    eos.addpoint(out, 0, 0, 0, 0, 0)
    self:outlet(3, "float", { #out / 5})
    return
  end

  local head = eos.pointatindex(self.frame, self.currentindex)

  if eos.isblank(head) then
    eos.addpoint(out, head.x, head.y, self.blankcol.r, self.blankcol.g, self.blankcol.b, 4)
    eos.addpoint(out, head.x, head.y, 0, 0, 0)

    self.psys.config.emitting = false
  else
    eos.addpoint(out, head.x, head.y, head.r, head.g, head.b, 16)

    self.psys.config.position = head
    self.psys.config.emitting = true
  end

  self.psys.update(1.0/30.0)
  lasercutter:to_xyrgb(out, self.psys.particles)

  self.currentindex = self.currentindex + 1
  if self.currentindex > #self.frame/5 then
    self.currentindex = 1
    self:outlet(2, "bang", {1})
  end


  -- self.time = self.time + 1.0 / 30.0
  self:outlet(3, "float", { #out / 5})
  self:outlet(1, "list", out)
end


function lasercutter:in_2_list(frame)
  self.frame = frame
  if #self.frame > 4 then
    self.currentindex = 1
  else
    print("lasercutter: empty frame")
  end
end


function lasercutter:in_2_npoints(x)
  if x[1] >= 10 then
    self.npoints = x[1]
    -- self:outlet(2, "float", {self.npoints})
  end
end


function lasercutter:in_3(sel, atoms)
  if     sel == "x1freq"  then self.x1freq  = atoms[1]
  elseif sel == "x1amp"   then self.x1amp   = atoms[1]
  elseif sel == "x1phase" then self.x1phase = atoms[1] * math.pi * 2
  elseif sel == "y1freq"  then self.y1freq  = atoms[1]
  elseif sel == "y1amp"   then self.y1amp   = atoms[1]
  elseif sel == "y1phase" then self.y1phase = atoms[1] * math.pi * 2
  elseif sel == "time"    then self.time    = atoms[1]
  elseif sel == "trailstep" then self.trailstep = atoms[1]
  elseif sel == "expand" then self.expand = atoms[1]
  elseif sel == "headcolor" then self.headcol = eos.hsv2rgb(atoms[1], 0.1, 1)
  elseif sel == "trailcolor" then self.trailcol = eos.hsv2rgb(atoms[1], 1, 1)
  elseif sel == "headrepeat" then self.headrepeat = math.max(atoms[1], 0)
  elseif sel == "aspectratio" then self.aspectratio = math.max(atoms[1], 0.2)
  elseif sel == "mirror" then self.mirror = (atoms[1] ~= 0)
  elseif sel == "drawtrail" then self.drawtrail = (atoms[1] ~= 0)
  end
end


function lasercutter:to_xyrgb(out, particles)
  for i=1,#particles do
    local p = particles[i]
    eos.addpoint(out, p.pos.x, p.pos.y, 0, 0, 0, 4)
    eos.addpoint(out, p.ppos.x, p.ppos.y, p.col.r, p.col.g, p.col.b, 1)
    eos.addpoint(out, p.pos.x, p.pos.y, p.col.r, p.col.g, p.col.b, 1)
    eos.addpoint(out, p.pos.x, p.pos.y, 0, 0, 0, 4)
  end
end
