
local contourmap = pd.Class:new():register("contourmap")


function contourmap:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
	self.datadim = 100
  self.contourheight = 0.5
  self.noisescale = 0.01
  self.timescale = 0.01
  self.framecount = 0
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

  local getcolor = function(i, n)
    local hue = (1 / n) * i
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
    local z = self.framecount
    return simplex.noise3d(x*self.noisescale, y*self.noisescale, z*self.timescale)
  end

  local landscape_fn = landscape_noise3d
  local image = contourmap:create_landscape(100, landscape_fn)
  local layers = ms.getContour(image, { self.contourheight })
  local contours = layers[1]
  local out = {}
  local x, y, r, g, b

  for c=1,#contours do
    local path = contours[c]
    -- local col = getcolor(c, #contours)
    local col = { r=0, g=0.1, b=1 }

    -- pre blank
    x,y = 2*path[1]/self.datadim - 1, 2*path[2]/self.datadim - 1
    eos.addpoint(out, x, y, 0, 0, 0, 8)

    for i=1,#path, 2 do
      r, g, b = col.r, col.g, col.b
      x,y = 2*path[i]/self.datadim - 1, 2*path[i+1]/self.datadim - 1
      eos.addpoint(out, x, y, r, g, b)
    end

    if v2.dist(v2.new(path[1], path[2]),
               v2.new(path[#path-1], path[#path])) < 5 then
      eos.addpoint(out, 2*path[1]/self.datadim-1, 2*path[2]/self.datadim-1, r, g, b, 4)
    end

    --post blank
    eos.addpoint(out, x, y, 0, 0, 0, 4)
  end

  if #out == 0 then
    eos.addpoint(out, 0, 0, 0, 0, 0)
  end

  self.framecount = self.framecount + 1
  self:outlet(2, "float", { #out / 5})
  self:outlet(1, "list", out)
end


function contourmap:in_2(sel, atoms)
    if     sel == "timescale"  then self.timescale  = atoms[1] * 0.01
    elseif sel == "noisescale" then self.noisescale = atoms[1] * 0.01
    elseif sel == "contourheight" then self.contourheight = atoms[1]
    end
end

