local traildot2 = pd.Class:new():register("traildot2")

local eos = require("eos")
local v2 = require("vec2")
local osimplex = require("opensimplex2s")

function traildot2:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.npoints = 100
  self.ntrails = 2
  self.trail_offset = 0.3
  self.trail_diverge = 1.0
  self.offset_freq = 0.2
  self.aspectratio = 1.0
  self.time = 0.0
  self.timestep = 1.0 / 90.0
  self.x1freq = 1.0
  self.x1amp = 1.0
  self.x1phase = 0.0
  self.y1freq = 1.0
  self.y1amp = 1.0
  self.y1phase = 0.0
  self.trailstep = 0.01
  self.expand = 5
  self.hscroll = 0
  self.headcol = { r=1, g=0.25, b=0 }
  self.trailcol = { r=0, g=0, b=1 }
  self.headrepeat = 10
  self.tailrepeat = 10

  self.octaves = 1
  self.lacunarity = 2
  self.persistence = 0.5

  self.Simplex = osimplex.new()
  self.headprev = v2.new(0, 0)
  return true
end


function traildot2:in_1_bang()
  local out = {}
  local arscalex, arscaley

  if self.aspectratio >= 1.0 then
    arscalex = self.aspectratio
    arscaley = 1
  else
    arscalex = 1
    arscaley = (1 / self.aspectratio)
  end

  for tr = 1, self.ntrails do
    local t = self.time

    local tr_off_x = self.trail_offset
           * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*12.3, 93.5)
    local tr_off_y = self.trail_offset
           * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 33.5)
    local head = {
      x = tr_off_x + arscalex * self.x1amp
        * self.Simplex:stacked_noise2(t*self.x1freq*arscaley + self.x1phase,
                                      211.323, self.octaves, self.lacunarity,
                                      self.persistence),
      y = tr_off_y + arscaley * self.y1amp
        * self.Simplex:stacked_noise2(t*self.y1freq*arscalex + self.y1phase,
                                      134.567, self.octaves, self.lacunarity,
                                      self.persistence)
    }

    eos.addpoint(out, head.x, head.y, 0, 0, 0, 12)
    eos.addpoint(out, head.x, head.y, 1, 1, 1, self.headrepeat)
    self.headprev.x = head.x
    self.headprev.y = head.y

    local trailx, traily
    local fader, fadeg, fadeb

    for i=1,self.npoints do
      fader = self.trailcol.r * (1.0 - (i / self.npoints))
      fadeg = self.trailcol.g * (1.0 - (i / self.npoints))
      fadeb = self.trailcol.b * (1.0 - (i / self.npoints))
      t = t - self.trailstep
      tr_off_x = self.trail_offset
               * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*12.3, 93.5)
      tr_off_y = self.trail_offset
               * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 33.5)
      trailx = tr_off_x + arscalex * self.x1amp
             * self.Simplex:stacked_noise2(t*self.x1freq*arscaley + self.x1phase,
                                           211.323, self.octaves, self.lacunarity,
                                           self.persistence)
      traily = tr_off_y + arscaley * self.y1amp
             * self.Simplex:stacked_noise2(t*self.y1freq*arscalex + self.y1phase,
                                           134.567, self.octaves,
                                           self.lacunarity, self.persistence)
      -- horizontal scroll
      trailx = trailx + eos.screenunit * i * self.hscroll

      -- polar "scroll"
      trailx = trailx + eos.screenunit * i * trailx * self.expand
      traily = traily + eos.screenunit * i * traily * self.expand

      eos.addpoint(out, trailx, traily, fader, fadeg, fadeb)
    end

    -- eos.addpoint(out, trailx, traily, fader, fadeg, fadeb, 12)
    -- eos.addpoint(out, trailx, traily, 1, 1, 1, self.tailrepeat)
    eos.addpoint(out, trailx, traily, 0, 0, 0, 1)

  end


  self.time = self.time + self.timestep
  self:outlet(2, "float", { #out / 5})
  self:outlet(1, "list", out)
end


function traildot2:in_2_npoints(x)
    if x[1] >= 10 then
        self.npoints = x[1]
        self:outlet(2, "float", {self.npoints})
    end
end


function traildot2:in_2(sel, atoms)
    if     sel == "x1freq"  then self.x1freq  = atoms[1]
    elseif sel == "x1amp"   then self.x1amp   = atoms[1]
    elseif sel == "x1phase" then self.x1phase = atoms[1] * math.pi * 2
    elseif sel == "y1freq"  then self.y1freq  = atoms[1]
    elseif sel == "y1amp"   then self.y1amp   = atoms[1]
    elseif sel == "y1phase" then self.y1phase = atoms[1] * math.pi * 2
    elseif sel == "ntrails" then self.ntrails = math.max(1, atoms[1])
    elseif sel == "trailoffset" then self.trail_offset = atoms[1]
    elseif sel == "traildiverge" then self.trail_diverge = atoms[1] * 0.01
    elseif sel == "offsetfreq" then self.offset_freq = atoms[1]
    elseif sel == "time"    then self.time    = atoms[1]
    elseif sel == "timestep" then self.timestep = atoms[1] / 100.0
    elseif sel == "trailstep" then self.trailstep = atoms[1]
    elseif sel == "expand"  then self.expand = atoms[1]
    elseif sel == "hscroll"  then self.hscroll = atoms[1]
    elseif sel == "headcolor" then self.headcol = eos.hsv2rgb(atoms[1], 1, 1)
    elseif sel == "trailcolor" then self.trailcol = eos.hsv2rgb(atoms[1], 1, 1)
    elseif sel == "headrepeat" then self.headrepeat = math.max(atoms[1], 0)
    elseif sel == "aspectratio" then self.aspectratio = math.max(atoms[1], 0.2)
    elseif sel == "octaves" then self.octaves = math.max(1, math.floor(atoms[1]))
    elseif sel == "lacunarity" then self.lacunarity = atoms[1]
    elseif sel == "persistence" then self.persistence = atoms[1]
    end
end

