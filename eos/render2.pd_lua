local render2 = pd.Class:new():register("render2")

 -- Render 2
 -- Params:
 -- maxdistanceblank
 -- maxdistancecolor
 -- corner dwell
 -- blanklerpmode: linear | cos | exponential

function render2:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047
    self.inlets = 2
    self.outlets = 2
    self.mode = "lines" 
    self.dwell = 8 
    self.subdivide = 32 
    self.preblank = 0
    self.postblank = 0
    self.accel = 1.0
    self.smoothblank = true

    if type(atoms[1] == "string") then
        if atoms[1] == "points" then
            self.mode = "points"
        elseif atoms[1] == "lines" then
            self.mode = "lines"
        end
    else
        self.mode = "lines"
    end
    pd.post(string.format("render:initialize(): render mode: %s", self.mode))
    if type(atoms[2]) == "number" then
        self.dwell = math.max(0, atoms[2])
        pd.post(string.format("render:initialize(): dwell: %s", self.dwell))
    end
    if type(atoms[3]) == "number" then
        self.subdivide = math.max(0, atoms[3])
        pd.post(string.format("render:initialize(): subdivide: %s", self.subdivide))
    end
    if type(atoms[4]) == "number" then
        self.preblank = math.max(0, atoms[4])
        pd.post(string.format("render:initialize(): preblank: %s", self.preblank))
    end

    return true
end

function render2:in_2_mode(m)
    if type(m[1]) ==  "string" and (m[1] == "lines" or m[1] == "points") then
        self.mode = m[1]
    end
    pd.post(string.format("render: mode: %s", self.mode))
end

function render2:in_2_dwell(d)
    if type(d[1]) ==  "number" then
        self.dwell = math.max(0, d[1])
    end
    pd.post(string.format("render: dwell: %s", self.dwell))
end

function render2:in_2_subdivide(s)
    if type(s[1]) ==  "number" then
        self.subdivide = math.max(0, s[1])
    end
    pd.post(string.format("render: subdivide: %s", self.subdivide))
end

function render2:in_2_preblank(p)
    if type(p[1]) ==  "number" then
        self.preblank = math.max(0, p[1])
    end
    pd.post(string.format("render: preblank: %s", self.preblank))
end

function render2:in_2_postblank(p)
    if type(p[1]) ==  "number" then
        self.postblank = math.max(0, p[1])
    end
    pd.post(string.format("render: postblank: %s", self.postblank))
end

function render2:in_2_accel(a)
    if type(a[1]) ==  "number" then
        self.accel = math.min(math.max(0.1, a[1]), 50.0)
    end
    pd.post(string.format("render: accel: %s", self.accel))
end

function render2:in_2_smoothblank(p)
    if type(p[1]) ==  "number" then
        self.smoothblank = (p[1] ~= 0)
    end
    pd.post(string.format("render: smoothblank: %s", self.smoothblank))
end

-- for each point p1
-- if is_blank(p1)
--   output(p1)
-- else
--   


function render2:in_1_list(inp)
  if type(inp) ~= "table" then
    self:error("render:in_1_list(): not a list")
    self:error(type(inp))
    return false
  end
  local eos = require("eos")
  local v2 = require("vec2")
  local out = {}
  local npoints = #inp / 5
  local ldwell = self.dwell
  local lsubdivide = self.subdivide
  -- local r1, g1, b1
  -- local prevcol = {
  --     r = 0,
  --     g = 0,
  --     b = 0
  -- }
  for i=0, npoints - 1 do
    local iidx = i * 5 + 1
    local p1 = {
        x=inp[iidx],
        y=inp[iidx+1],
        r = inp[iidx+2],
        g = inp[iidx+3],
        b = inp[iidx+4]
    }

    -- Preblank 
    eos.addpoint(out, p1.x, p1.y, 0, 0, 0, self.preblank)

    -- The point
    eos.addpoint(out, p1.x, p1.y, p1.r, p1.g, p1.b)

    -- Dwell points
    eos.addpoint(out, p1.x, p1.y, p1.r, p1.g, p1.b, ldwell)

    -- Subdivision
    if lsubdivide > 0 and npoints > 1 then
      local p2 = {
          x=inp[((i+1) % npoints) * 5 + 1],
          y=inp[((i+1) % npoints) * 5 + 2]
      }
      if eos.isblank(p1) and self.smoothblank then
          eos.subdivide_smooth(out, p1, p2, self.subdivide*2, self.mode)
          --eos.subdivide_exp(out, p1, p2, self.subdivide, self.accel, self.mode)
      else
          eos.subdivide(out, p1, p2, self.subdivide, self.mode)
      end
    end
  end
  self:outlet(2, "float", { #out / 5 })
  self:outlet(1, "list", out)
end

