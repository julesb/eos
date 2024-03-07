--[[

  - Parameters:

        - color1: user defined RGB 
        - color2: user defined RGB
   
        - blendmode:
done      - rgb: linear RGB interpolation
done      - hsv: linear HSV interpolation
done      - hcl: linear HCL interpolation

TODO    - auto: boolean, whewn true will modulate the generated gradient.
TODO    - autospeed: float, determines the modulation rate when auto=tre
   
done    - reflect: boolean, seamless gradient by mirroring about t=0.5
done    - repeat: integer, repeats the gradient N times over the points,
                  eg. for when the input points have symmetry.
done    - offset: float, determines the offset from the complement from
                  color1 of the two complement colors in split_complement
                  mode, and offset from color1 of the analogous colors in
                  analogous mode.
    
done    - huepoints: integer, determines the number of hue points used when
                      mode=polyadic.
 
TODO    - saturation: float, applies saturation to the final output colors
TODO    - brightness: float, applies brightness to the final output colors

        - mode:
done      - constant: boolean, when true, color1 is applied to all points.
done      - user: blend from user-defined color1 to color2 using `blendmode`.
TODO      - monochromatic: blend from color1 to black.
done      - analogous: two colors offset from color1 by amount `split_offset`
done      - polyadic: creates a gradient by interpolating between `huepoints`
                      number of primary colors at equal angles around the hue
                      wheel.
done      - split_complement: blend from color1 to two colors offset from
                              the complement of color1. The offset amount is
                              is determined by the offset parameter.
TODO      - rectangle: rectangle tetradic hue points defined by color1, color2
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
  self.reflect = true
  self["repeat"] = 1
  self.offset = 0.1
  self.huepoints = 3
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
  self.validblendmodes = {
    RGB = true,
    HSV = true,
    HCL = true,
    STEP = true
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
  return math.max(1, pcount)
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
  local colorstep = 1.0 / uniqpositions
  local color_t = 0.0
  local lrepeat = self["repeat"]

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) then
      local grad_t = (color_t * lrepeat) % 1.0
      if self.reflect then grad_t = cs.mirror_t(grad_t) end
      gcolor = cs.blendfn[self.blendmode](self.usercolor1, self.usercolor2, grad_t)
      e.setcolor(p, gcolor)
      if (not e.positionequal(p, p_prev)) then
        color_t = color_t + colorstep
      end
    end

    e.addpoint2(out, p)
    p_prev = p
  end
  return out
end


function gradient:apply_analogous(xyrgb)
  local e = require("eos")
  local cs = require("colorspace")
  local npoints = #xyrgb / 5
  local out = {}
  local p, p_prev, gcolor
  local uniqpositions = self:countpositions(xyrgb)
  local colorstep = 1.0 / uniqpositions
  local color_t = 0.0
  local lrepeat = self["repeat"]

  local hsv = cs.rgb_to_hsv(self.usercolor1)

  local ahue1 = (hsv.h - self.offset) % 1.0
  local ahue2 = (hsv.h + self.offset) % 1.0
  local acolor1 = cs.hsv_to_rgb({h=ahue1, s=hsv.s, v=hsv.v})
  local acolor2 = cs.hsv_to_rgb({h=ahue2, s=hsv.s, v=hsv.v})

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) then
      local grad_t = (color_t * lrepeat) % 1.0
      if self.reflect then grad_t = cs.mirror_t(grad_t) end
      gcolor = cs.blendfn[self.blendmode](acolor1, acolor2, grad_t)
      e.setcolor(p, gcolor)
      if (not e.positionequal(p, p_prev)) then
        color_t = color_t + colorstep
      end
    end

    e.addpoint2(out, p)
    p_prev = p
  end
  return out
end


function gradient:apply_polyadic(xyrgb)
  local e = require("eos")
  local cs = require("colorspace")
  local npoints = #xyrgb / 5
  local out = {}
  local p, p_prev, gcolor
  local uniqpositions = self:countpositions(xyrgb)
  local colorstep = 1.0 / uniqpositions
  local color_t = 0.0
  local lrepeat = self["repeat"]

  local basehsv = cs.rgb_to_hsv(self.usercolor1)
  local keycolors = {}
  local huestep = 1.0 / self.huepoints
  for i=0,self.huepoints-1 do
    local keyhue = (basehsv.h + i * huestep) % 1.0
    table.insert(keycolors, cs.hsv_to_rgb({h=keyhue, s=basehsv.s, v=basehsv.v}))
  end
  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) then
      local grad_t = (color_t * lrepeat) % 1.0
      if self.reflect then grad_t = cs.mirror_t(grad_t) end
      gcolor = cs.polyadic_gradient(keycolors, self.blendmode, grad_t)
      e.setcolor(p, gcolor)
      if (not e.positionequal(p, p_prev)) then
        color_t = color_t + colorstep
      end
    end

    e.addpoint2(out, p)
    p_prev = p
  end
  return out
end


function gradient:apply_splitcomplement(xyrgb)
  local e = require("eos")
  local cs = require("colorspace")
  local npoints = #xyrgb / 5
  local out = {}
  local p, p_prev, gcolor
  local uniqpositions = self:countpositions(xyrgb)
  local colorstep = 1.0 / uniqpositions
  local color_t = 0.0
  local lrepeat = self["repeat"]

  local hsv = cs.rgb_to_hsv(self.usercolor1)

  local ahue1 = (hsv.h + 0.5 - self.offset) % 1.0
  local ahue2 = (hsv.h + 0.5 + self.offset) % 1.0
  local acolor1 = cs.hsv_to_rgb({h=ahue1, s=hsv.s, v=hsv.v})
  local acolor2 = cs.hsv_to_rgb({h=ahue2, s=hsv.s, v=hsv.v})
  local gcolors = {self.usercolor1, acolor1, acolor2}

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) then
      local grad_t = (color_t * lrepeat) % 1.0
      if self.reflect then grad_t = cs.mirror_t(grad_t) end
      gcolor = cs.polyadic_gradient(gcolors, self.blendmode, grad_t)
      e.setcolor(p, gcolor)
      if (not e.positionequal(p, p_prev)) then
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
  elseif self.mode == "analogous" then
    out = self:apply_analogous(inp)
  elseif self.mode == "polyadic" then
    out = self:apply_polyadic(inp)
  elseif self.mode == "splitcomplement" then
    out = self:apply_splitcomplement(inp)
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
  elseif sel == "reflect" then
    self.reflect = (atoms[1] ~= 0)
  elseif sel == "repeat" then
    self["repeat"] = math.max(1, atoms[1])
  elseif sel == "offset" then
    self.offset = atoms[1]
  elseif sel == "huepoints" then
    self.huepoints = math.max(1, atoms[1])
  elseif sel == "blendmode" then
    if self.validblendmodes[atoms[1]] then
      self.blendmode = atoms[1]
    end
  end
end


