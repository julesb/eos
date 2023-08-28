local psys = pd.Class:new():register("particlesys")
local socket = require("socket")


function psys:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.config = {
    maxparticles = 30,
    lifespan = 0.5,
    emitprobability = 0.5
  }
  self.tprev = 0.0
  self.targetframerate = 60
  self.particlesys = require("particlesys")
  self.particlesys.init(self.config)
  return true
end

function psys:in_1_bang()
    local t = socket.gettime()
    local dt = t - self.tprev
    self.tprev = t
    if dt > 1.0 then dt = 1.0 / self.targetframerate end
    self.particlesys.update(dt)
    local xyrgb = psys:to_xyrgb(self.particlesys.particles)
    self:outlet(2, "float", { #xyrgb / 5 })
    self:outlet(1, "list", xyrgb)
end


function psys:to_xyrgb(particles)
    local v2 = require("vec2")
    local eos = require("eos")
    local out = {}
    for i=1,#particles do
      local p = particles[i]
      eos.addpoint(out, p.pos.x, p.pos.y, 0, 0, 0)
      eos.addpoint(out, p.pos.x, p.pos.y, p.col.r, p.col.g, p.col.b)
      eos.addpoint(out, p.pos.x, p.pos.y, 0, 0, 0)
    end
    return out
end

function psys:in_2(sel, atoms)
    if sel == "maxparticles" then
        self.particlesys.config.maxparticles = atoms[1]
    elseif sel == "emitprobability" then
        self.particlesys.config.emitprobability = math.max(atoms[1], 0.0)
    elseif sel == "lifespan" then
        self.particlesys.config.lifespan = math.max(atoms[1], 0.0)
    elseif sel == "gravity" then
        self.particlesys.config.gravity.y = atoms[1]
    elseif sel == "velocity" then
        self.particlesys.config.meanvelocity = atoms[1]
    end
end
