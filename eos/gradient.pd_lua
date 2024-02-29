--[[

  - Parameters:

        - color1: user defined RGB 
        - color2: user defined RGB
   
TODO    - blendmode:
TODO      - rgb: linear RGB interpolation
TODO      - hsv: linear HSV interpolation
TODO      - hcl: linear HCL interpolation

TODO    - auto: boolean, whewn true will modulate the generated gradient.
TODO    - autospeed: float, determines the modulation rate when auto=true
   
TODO    - wrap: boolean, seamless gradient by mirroring about t=0.5
TODO    - repeat: integer, repeats the gradient N times over the points,
                  eg. for when the input points have symmetry.
TODO    - offset: float, determines the offset from the complement from
                  color1 of the two complement colors in split_complement
                  mode, and offset from color1 of the analogous colors in
                  analogous mode.
    
TODO    - huepoints: integer, determines the number of hue points used when
                      mode=polyadic.
 
TODO    - saturation: float, applies saturation to the final output colors
TODO    - brightness: float, applies brightness to the final output colors

        - mode:
          - constant: boolean, when true, color1 is applied to all points.
TODO      - user: blend from user-defined color1 to color2 using `blendmode`.
TODO      - monochromatic: blend from color1 to black.
TODO      - analogous: two colors offset from color1 by amount `split_offset`
TODO      - polyadic: creates a gradient by interpolating between `huepoints`
                      number of primary colors at equal angles around the hue
                      wheel.
TODO      - split_complement: blend from color1 to two colors offset from
                              the complement of color1. The offset amount is
                              is determined by the offset parameter.
          - rectangle: rectangle tetradic hue points defined by color1, color2
                       and their complements.
 
--]]

local gradient = pd.Class:new():register("gradient")


function gradient:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2

  -- Parameters
  self.usercolor1 = { r=1, g=0, b=0 }
  self.usercolor2 = { r=0, g=0, b=1 }
  self.blendmode = "HCL" -- RGB | HSV | HCL
  self.auto = false
  self.autospeed = 1.0
  self.wrap = true
  self["repeat"] = 1
  self.offset = 0.1
  self.huepoints = 2
  self.saturation = 1.0
  self.brightness = 1.0
  self.bypass = false

  self.mode = "constant" -- constant | user | monochromatic | analogous
                         -- | polyadic | splitcomplement | rectangle
  self.validmodes = {
    constant = true,
    user = true,
    mono = true,
    analogous = true,
    polyadic = true,
    splitcomplement = true,
    rect = true
  }

  -- State
  self.hue_points = {}
  self.drift_offset = 0;


  if type(atoms[1]) == "string" then
    if self.validmodes[atoms[1]] then
      self.mode = atoms[1]
    else
      print("gradient: invalid mode", atoms[1])
    end
  end
  return true
end

function gradient:in_2_float(c)
    self.hsv1.h = c
end
function gradient:in_3_float(c)
    self.hsv2.h = c
end


function gradient:countpositions(inp)
  local eos = require("eos")
  local npoints = #inp / 5
  local p, p_prev
  local pcount = 0

  for i=1,npoints do
    p = eos.pointatindex(inp, i)
    if not eos.isblank(p) then
      if not eos.positionequal(p, p_prev) then pcount = pcount + 1 end
    end
    p_prev = p
  end
  return pcount
end


function gradient:apply_constant(xyrgb)
  local e = require("eos")
  local npoints = #xyrgb / 5
  local out = {}
  local p

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)
    if not e.isblank(p) then
      e.setcolor(p, self.usercolor1)
    end
    e.addpoint2(out, p)
  end
  return out
end

function gradient:apply_userdefined(xyrgb)
  local e = require("eos")
  local cs = require("colorspace")
  local npoints = #xyrgb / 5
  local out = {}
  local p, p_prev, gcolor
  local uniqpositions = self:countpositions(xyrgb)
  local colorstep = 1.0 / (1.0 + uniqpositions)
  local color_t = 0.0
  local lrepeat = self["repeat"]

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) then
      if (not e.positionequal(p, p_prev)) or e.isblank(p_prev) then
        local grad_t = (color_t * lrepeat) % 1.0
        if self.wrap then grad_t = cs.mirror_t(grad_t) end
        gcolor = cs.hcl_gradient(self.usercolor1, self.usercolor2, grad_t)
        e.setcolor(p, gcolor)
        color_t = color_t + colorstep
      end
    end

    e.addpoint2(out, p)
    p_prev = p
  end
  return out
end



function gradient:in_1_list(inp)
  local out = {}

  if self.bypass then
    self:outlet(2, "float", { #inp / 5 })
    self:outlet(1, "list", inp)
    return
  end

  if self.mode == "constant" then
    out = self:apply_constant(inp)
  elseif self.mode == "user" then
    out = self:apply_userdefined(inp)
  end

  self:outlet(2, "float", { #out / 5 })
  self:outlet(1, "list", out)
end



function gradient:in_2(sel, atoms)

  if sel == "color1" then
    self.usercolor1 = {
      r = atoms[1],
      g = atoms[2],
      b = atoms[3]
    }
  elseif sel == "color2" then
    self.usercolor2 = {
      r = atoms[1],
      g = atoms[2],
      b = atoms[3]
    }
  elseif sel == "bypass" then
    self.bypass = (atoms[1] ~= 0)
  elseif sel == "mode" then
    if self.validmodes[atoms[1]] then
      self.mode = atoms[1]
    else
      print("Invalid mode:", atoms[1])
    end
  elseif sel == "wrap" then
    self.wrap = (atoms[1] ~= 0)
  elseif sel == "repeat" then
    self["repeat"] = math.max(1, atoms[1])
  end
end


