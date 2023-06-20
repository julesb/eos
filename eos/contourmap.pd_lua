
local contourmap = pd.Class:new():register("contourmap")


function contourmap:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
	self.datadim = 100
  self.contourheight = 0.5
  self.noisescale = 0.01
  self.timestep = 0.01
  self.time = 0.0
  self.framecount = 0
  self.basehue = 0
  return true
end


function contourmap:create_landscape(dim, fn)
  local image = {}
  for y=1,dim do
    local row = {}
    for x = 1,dim do
      table.insert(row, fn(x, y))
    end
    table.insert(image, row)
  end
  return image
end


function contourmap:in_1_bang()
  local ms = require("marchingsqr")
  local simplex = require("simplex")
  local eos = require("eos")
  local v2 = require("vec2")

  -- ith color of nth division of hue space / n
  local getcolor = function(i, n)
    local hue = self.basehue + (1 / n) * i
    return eos.hsv2rgb(hue, 1, 1)
  end

  -- cone / circle
  local landscape_circle = function(x, y)
    return v2.dist(v2.new(x, y), v2.new(self.datadim/2, self.datadim/2))
           / (self.datadim )
  end

  -- noise 2d
  local landscape_noise2d = function(x, y)
    local noise_offs = self.framecount
    return simplex.noise2d((x+noise_offs)*0.01, y*0.01)
  end

  -- noise 3d
  local landscape_noise3d = function(x, y)
    local c = self.datadim / 2
    local xoff,yoff = 123.123, 201.813
    return simplex.noise3d(
      xoff + (x-c)*self.noisescale,
      yoff + (y-c)*self.noisescale,
      self.time
    )
  end

  local landscape_fn = landscape_noise3d
  local image = contourmap:create_landscape(self.datadim, landscape_fn)
  local layers = ms.getContour(image, { -1*self.contourheight, self.contourheight })
  --local contours = layers[1]
  local out = {}
  local x, y, r, g, b

  for lidx = 1,#layers do
    local contours = layers[lidx]
    local col = getcolor(lidx-1, #layers)
    for c=1,#contours do
      local path = contours[c]
      -- local col = getcolor(c, #contours)
      -- local col = { r=0, g=0.1, b=1 }
      local isclosed = (v2.dist(v2.new(path[1], path[2]),
                                v2.new(path[#path-1], path[#path])) < 5)
      -- pre blank
      x,y = 2*path[1]/self.datadim - 1, 2*path[2]/self.datadim - 1
      eos.addpoint(out, x, y, 0, 0, 0, 8)

      if not isclosed then
        -- bright endpoint
        eos.addpoint(out, x, y, 1, 1, 1, 8)
      end

      for i=1,#path, 2 do
        x,y = 2*path[i]/self.datadim - 1, 2*path[i+1]/self.datadim - 1
        -- local l = math.max(0, 1 - v2.len(v2.new(x,y))) -- fade
        -- local l = v2.len(v2.new(x,y))
        -- if l < 1 then l = 1 else l = 0 end
        -- l = math.max(l, 0)
        local l = 1
        r, g, b = col.r*l, col.g*l, col.b*l
        eos.addpoint(out, x, y, r, g, b)
      end

      if isclosed then
        -- close the loop
        eos.addpoint(out,
                     2*path[1]/self.datadim-1,
                     2*path[2]/self.datadim-1,
                     r, g, b, 4)
      else
        -- bright endpoint
        eos.addpoint(out, x, y, 1, 1, 1, 8)
      end

      --post blank
      eos.addpoint(out, x, y, 0, 0, 0, 4)
    end
  end

  if #out == 0 then
    eos.addpoint(out, 0, 0, 0, 0, 0)
  end

  self.framecount = self.framecount + 1
  self.time = self.time + self.timestep
  self:outlet(2, "float", { #out / 5})
  self:outlet(1, "list", out)
end


function contourmap:in_2(sel, atoms)
    if     sel == "timestep"  then self.timestep  = atoms[1] * 0.01
    elseif sel == "noisescale" then self.noisescale = atoms[1] * 0.01
    elseif sel == "contourheight" then self.contourheight = atoms[1]
    elseif sel == "hue" then self.basehue = atoms[1]
    end
end

