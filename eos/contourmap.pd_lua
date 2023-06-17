
local contourmap = pd.Class:new():register("contourmap")

function contourmap:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
	self.datadim = 100
  self.contourheight = 0.5
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
  local ms = require("luams")
  local eos = require("eos")
  local v2 = require("vec2")
  local simplex = require("simplex")

  local landscape_fn = function(x, y)
    local noise_offs = self.framecount
    return simplex.noise2d((x+noise_offs)*0.01, y*0.01)
  end

  -- local landscape_fn = function(x, y)
  --   return v2.dist(v2.new(x, y), v2.new(self.datadim/2, self.datadim/2))
  --          / (self.datadim )
  -- end

  local image = contourmap:create_landscape(100, landscape_fn)
  local layers = ms.getContour(image, { self.contourheight })
  local contours = layers[1]
  local out = {}
  local x,y

  for c=1,#contours do
    local path = contours[c]
    -- pre blank
    x,y = 2*path[1]/self.datadim - 1, 2*path[2]/self.datadim - 1
    eos.addpoint(out, x, y, 0, 0, 0)
    for i=1,#path, 2 do
      local r,g,b = 0, 1, 0
      x,y = 2*path[i]/self.datadim - 1, 2*path[i+1]/self.datadim - 1
      eos.addpoint(out, x, y, r, g, b)
    end
    --post blank
    eos.addpoint(out, x, y, 0, 0, 0)
  end

  self.framecount = self.framecount + 1
  self:outlet(2, "float", { #out / 5})
  self:outlet(1, "list", out)
end


function contourmap:in_2_contourheight(x)
  self.contourheight = x[1]
  self:outlet(2, "float", {self.contourheight})
end







-- function contourmap:in_2(sel, atoms)
--     if     sel == "x1freq"  then self.x1freq  = atoms[1]
--     elseif sel == "x1amp"   then self.x1amp   = atoms[1]
--     end
-- end

