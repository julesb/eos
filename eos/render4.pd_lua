local r4 = pd.Class:new():register("render4")

function r4:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047
    self.inlets = 2
    self.outlets = 2
    self.mode = "lines" 
    self.dwell = 8 
    self.subdivide = 32 
    self.preblank = 0
    self.postblank = 0
    self.bypass = false

    if type(atoms[1] == "string") then
        if atoms[1] == "points" then
            self.mode = "points"
        elseif atoms[1] == "lines" then
            self.mode = "lines"
        end
    else
        self.mode = "lines"
    end

    pd.post(string.format("render4:initialize(): render mode: %s",
                          self.mode))
    if type(atoms[2]) == "number" then
        self.dwell = math.max(0, atoms[2])
        pd.post(string.format("render:initialize(): dwell: %s",
                              self.dwell))
    end
    if type(atoms[3]) == "number" then
        self.subdivide = math.max(0, atoms[3])
        pd.post(string.format("render4:initialize(): subdivide: %s",
                              self.subdivide))
    end
    if type(atoms[4]) == "number" then
        self.preblank = math.max(0, atoms[4])
        pd.post(string.format("render4:initialize(): preblank: %s",
                              self.preblank))
    end

    return true
end

function r4:in_2_mode(m)
    if type(m[1]) == "string" and (m[1] == "lines" or m[1] == "points") then
        self.mode = m[1]
    end
    pd.post(string.format("render4: mode: %s", self.mode))
end

function r4:in_2_dwell(d)
    if type(d[1]) ==  "number" then
        self.dwell = math.max(0, d[1])
    end
    pd.post(string.format("render4: dwell: %s", self.dwell))
end

function r4:in_2_subdivide(s)
    if type(s[1]) ==  "number" then
        self.subdivide = math.max(0, s[1])
    end
    pd.post(string.format("render4: subdivide: %s", self.subdivide))
end

function r4:in_2_preblank(p)
    if type(p[1]) ==  "number" then
        self.preblank = math.max(0, p[1])
    end
    pd.post(string.format("render4: preblank: %s", self.preblank))
end

function r4:in_2_postblank(p)
    if type(p[1]) ==  "number" then
        self.postblank = math.max(0, p[1])
    end
    pd.post(string.format("render4: postblank: %s", self.postblank))
end

function r4:in_2_bypass(b)
    if type(b[1]) ==  "number" then
        self.bypass = (b[1] ~= 0)
    end
    pd.post(string.format("render4: bypass: %s", self.bypass))
end


function r4:render_lines(points)

end


function r4:render_points(points)

end

function r4:truncateToMultipleOfFive(arr)
    local len = #arr
    local remainder = len % 5
    local newLen = len - remainder

    local newArr = {}
    for i = 1, newLen do
        newArr[i] = arr[i]
    end

    return newArr
end

function r4:in_1_list(inp)
  if type(inp) ~= "table" then
    self:error("render4:in_1_list(): input is not a list")
    self:error(type(inp))
    return false
  end
  if self.bypass then
    self:outlet(2, "float", { #inp / 5 })
    self:outlet(1, "list", inp)
    return
  end

  if #inp % 5 ~= 0 then
    self:error("render4:in_1_list(): input length is not a multiple of 5")
    self:outlet(2, "float", { #inp / 5 })
    self:outlet(1, "list", inp)
    return
  end

  local eos = require("eos")
  -- local v2 = require("vec2")
  local out = {}
  local npoints = #inp / 5
  local ldwell = self.dwell
  local lsubdivide = self.subdivide
  local lmode = self.mode
  local lpreblank = self.preblank
  local p0, p1, p2, dwell

  for i=1, npoints do

    p0 = (i > 1) and eos.pointatindex(inp, i-1)
    p1 = eos.pointatindex(inp, i)
    p2 = (i < npoints) and eos.pointatindex(inp, i+1)

    -- dwell brightness normalization - needs work
    -- local dcol = {
    --   r= 0.5 + (p1.r / (1+dwell)) * 0.5,
    --   g= 0.5 + (p1.g / (1+dwell)) * 0.5,
    --   b= 0.5 + (p1.b / (1+dwell)) * 0.5,
    -- }

    if lpreblank > 0 and p2 then
      local b1 = eos.isblank(p1)
      local b2 = eos.isblank(p2)
      if b2 ~= b1 then
        eos.addpoint2(out, p1, lpreblank)
      end
    end

    -- angle dependent dwell 
    dwell = eos.getdwellbyangle(p0, p1, p2, ldwell)

    -- The point
    eos.addpoint2(out, p1, dwell)
    -- eos.addpoint(out, p1.x, p1.y, dcol.r, dcol.g, dcol.b, dwell)

    -- Subdivision
    if lsubdivide > 0 and npoints > 1 and i < npoints then
      eos.subdivide(out, p1, p2, lsubdivide, lmode)
    end
  end

  -- path end dwell points
  eos.addpoint2(out, p1, ldwell)

  -- path end blank point
  -- eos.addpoint(out, p1.x, p1.y, 0, 0, 0)

  self:outlet(2, "float", { #out / 5 })
  self:outlet(1, "list", out)
end

