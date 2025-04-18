local traildot3d = pd.Class:new():register("traildot3d")

local eos = require("eos")
local v3 = require("vec3")
local osimplex = require("opensimplex2s")

function traildot3d:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 4
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
  self.z1freq = 1.0
  self.z1amp = 1.0
  self.z1phase = 0.0

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
  return true
end

-- Warning, the code uses separate variables `tail` and `trail`. Dont mix them up
function traildot3d:in_1_bang()
  local out = {}
  local avg_pos_head = {x=0, y=0, z=0}
  local avg_pos_head_out
  local avg_pos_tail = {x=0, y=0, z=0}
  local avg_pos_tail_out

  for tr = 0, self.ntrails-1 do
    local t = self.time

    local tr_off_x = self.trail_offset
           * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 93.5)
    local tr_off_y = self.trail_offset
           * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 33.5)
    local tr_off_z = self.trail_offset
           * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 133.5)

    local head = {
      x = tr_off_x + self.x1amp
        * self.Simplex:stacked_noise2(t*self.x1freq + self.x1phase,
                                      211.323,
                                      self.octaves,
                                      self.lacunarity,
                                      self.persistence),
      y = tr_off_y + self.y1amp
        * self.Simplex:stacked_noise2(t*self.y1freq + self.y1phase,
                                      134.567,
                                      self.octaves,
                                      self.lacunarity,
                                      self.persistence),
      z = tr_off_z + self.z1amp
        * self.Simplex:stacked_noise2(t*self.z1freq + self.z1phase,
                                      84.567,
                                      self.octaves,
                                      self.lacunarity,
                                      self.persistence),
      r = 1, g = 1, b = 1
    }

    avg_pos_head = v3.add(avg_pos_head, head)

    eos.addblank3d(out, head, 12)
    eos.addpoint3d(out, head, self.headrepeat)
    -- eos.addblank3d(out, head, 1)

    -- add a single point of trailcol to prevent gap
    -- head.r = self.trailcol.r
    -- head.g = self.trailcol.g
    -- head.b = self.trailcol.b
    -- eos.addpoint3d(out, head, 1)

    local p, trailx, traily, trailz
    local fader, fadeg, fadeb

    for i=0,self.npoints-1 do
      fader = self.trailcol.r * (1.0 - (i / self.npoints))
      fadeg = self.trailcol.g * (1.0 - (i / self.npoints))
      fadeb = self.trailcol.b * (1.0 - (i / self.npoints))
      t = t - self.trailstep
      tr_off_x = self.trail_offset
               * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 93.5)
      tr_off_y = self.trail_offset
               * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 33.5)
      tr_off_z = self.trail_offset
               * self.Simplex:noise2(t*self.offset_freq + tr*self.trail_diverge*19.1, 133.5)

      trailx = tr_off_x + self.x1amp
             * self.Simplex:stacked_noise2(t*self.x1freq + self.x1phase,
                                           211.323,
                                           self.octaves,
                                           self.lacunarity,
                                           self.persistence)
      traily = tr_off_y + self.y1amp
             * self.Simplex:stacked_noise2(t*self.y1freq + self.y1phase,
                                           134.567,
                                           self.octaves,
                                           self.lacunarity,
                                           self.persistence)
      trailz = tr_off_z + self.z1amp
             * self.Simplex:stacked_noise2(t*self.z1freq + self.z1phase,
                                           84.567,
                                           self.octaves,
                                           self.lacunarity,
                                           self.persistence)
      -- horizontal scroll
      -- trailx = trailx + eos.screenunit * i * self.hscroll

      -- polar "scroll"
      trailx = trailx + eos.screenunit * i * trailx * self.expand
      traily = traily + eos.screenunit * i * traily * self.expand
      trailz = trailz + eos.screenunit * i * trailz * self.expand

      p = {x=trailx, y=traily, z=trailz, r=fader, g=fadeg, b=fadeb}
      eos.addpoint3d(out, p)
    end
    avg_pos_tail = v3.add(avg_pos_tail, p)

    -- eos.addpoint(out, trailx, traily, fader, fadeg, fadeb, 12)
    -- eos.addpoint(out, trailx, traily, 1, 1, 1, self.tailrepeat)

    eos.addblank3d(out, p, 1)
  end

  avg_pos_head = v3.scale(avg_pos_head, 1/self.ntrails)
  avg_pos_head_out = {avg_pos_head.x, avg_pos_head.y, avg_pos_head.z}

  avg_pos_tail = v3.scale(avg_pos_tail, 1/self.ntrails)
  avg_pos_tail = v3.scale(avg_pos_tail, 2)
  avg_pos_tail_out = {avg_pos_tail.x, avg_pos_tail.y, avg_pos_tail.z}

  self.time = self.time + self.timestep
  self:outlet(4, "float", { #out / 6})
  self:outlet(3, "list", avg_pos_head_out)
  self:outlet(2, "list", avg_pos_tail_out)
  self:outlet(1, "list", out)
end


function traildot3d:in_2_npoints(x)
    if x[1] >= 10 then
        self.npoints = x[1]
        self:outlet(2, "float", {self.npoints})
    end
end


function traildot3d:in_2(sel, atoms)
    if     sel == "x1freq"  then self.x1freq  = atoms[1]
    elseif sel == "x1amp"   then self.x1amp   = atoms[1]
    elseif sel == "x1phase" then self.x1phase = atoms[1] * math.pi * 2
    elseif sel == "y1freq"  then self.y1freq  = atoms[1]
    elseif sel == "y1amp"   then self.y1amp   = atoms[1]
    elseif sel == "y1phase" then self.y1phase = atoms[1] * math.pi * 2
    elseif sel == "z1freq"  then self.z1freq  = atoms[1]
    elseif sel == "z1amp"   then self.z1amp   = atoms[1]
    elseif sel == "z1phase" then self.z1phase = atoms[1] * math.pi * 2
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

