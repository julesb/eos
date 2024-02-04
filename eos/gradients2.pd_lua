local gradients2 = pd.Class:new():register("gradients2")

function gradients2:initialize(sel, atoms)
  self.screenunit = 1.0 / 2047.0
  self.inlets = 3
  self.outlets = 2
  self.npoints = 256
  self.color1 = { r=1, g=0.0, b=0.0 }
  self.color2 = { r=0, g=1.0, b=0.0 }

  self.vspace = 512
  -- if type(atoms[1] == "number") then
  --     self.npoints = atoms[1]
  -- end
  return true
end

-- function gradients2:in_2_float(n)
--   if type(n) == "number" and n > 0 then
--     self.npoints = n
--   end
-- end


-- function gradients2:makegradient(rgb1, rgb2)
--
-- end

function gradients2:in_2_list(rgb)
  if rgb == nil or #rgb ~= 3 then return end
  self.color1.r = rgb[1]
  self.color1.g = rgb[2]
  self.color1.b = rgb[3]
end

function gradients2:in_3_list(rgb)
  if rgb == nil or #rgb ~= 3 then return end
  self.color2.r = rgb[1]
  self.color2.g = rgb[2]
  self.color2.b = rgb[3]
end


function gradients2:in_1_bang()
  local eos = require("eos")
  local cs = require("colorspace")
  local out = {}
  local x, y --, gc
  local xstep = 2.0 / self.npoints

  -- HSV linear gradient
  y = (0 - self.vspace * 1.5) * self.screenunit
  eos.addpoint(out, -1, y, 0, 0, 0, 8)
  local gc1
  for i=0, self.npoints-1 do
    local t = i /self.npoints
    gc1 = cs.hsv_gradient(self.color1, self.color2, t)
    x = 1.0 - i * xstep
    -- x = -1.0 + i * xstep
    eos.addpoint(out, x, y, gc1.r, gc1.g, gc1.b)
  end
  eos.addpoint(out, x, y, gc1.r, gc1.g, gc1.b, 8)
  eos.addpoint(out, x, y, 0, 0, 0)

  -- RGB linear gradient
  y = (0 - self.vspace * 1.0) * self.screenunit
  eos.addpoint(out, -1, y, 0, 0, 0, 8)
  local gc2

  for i=0, self.npoints-1 do
    local t = i /self.npoints
    gc2 = cs.rgb_gradient(self.color1, self.color2, t)
    x = 1.0 - i * xstep
    -- x = -1.0 + i * xstep
    eos.addpoint(out, x, y, gc2.r, gc2.g, gc2.b)
  end
  eos.addpoint(out, x, y, gc2.r, gc2.g, gc2.b, 8)
  eos.addpoint(out, x, y, 0, 0, 0)


  -- HCL linear gradient
  y = (0 - self.vspace * 0.5) * self.screenunit
  eos.addpoint(out, -1, y, 0, 0, 0, 8)
  local gc3
  for i=0, self.npoints-1 do
    local t = i /self.npoints
    gc3 = cs.hcl_gradient(self.color1, self.color2, t)
    x = 1.0 - i * xstep
    -- x = -1.0 + i * xstep
    eos.addpoint(out, x, y, gc3.r, gc3.g, gc3.b)
  end
  eos.addpoint(out, x, y, gc3.r, gc3.g, gc3.b, 8)
  eos.addpoint(out, x, y, 0, 0, 0)


  -- -- White gradient
  -- y = (0 + self.vspace * 2.5) * self.screenunit
  -- eos.addpoint(out, -1, y, 0, 0, 0, 8)
  -- for i=0, self.npoints-1 do
  --     local intensity = i / (self.npoints-1)
  --     c = {r=intensity, g=intensity, b=intensity}
  --     x = -1.0 + i * xstep
  --     eos.addpoint(out, x, y, c.r, c.g, c.b)
  -- end
  -- eos.addpoint(out, x, y, c.r, c.g, c.b, 8)
  -- eos.addpoint(out, x, y, 0, 0, 0)

  self:outlet(2, "float", { #out/5 })
  self:outlet(1, "list", out)
end

