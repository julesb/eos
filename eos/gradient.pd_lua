--[[

  - Parameters:

        - color1: user defined RGB 
        - color2: user defined RGB
        - alpha: transparency - alpha blend gradient with input
done    - preservewhite: if the input color is white, then pass through unchanged.
        - blendmode:
done      - rgb: linear RGB interpolation
done      - hsv: linear HSV interpolation
done      - hcl: linear HCL interpolation

TODO    - auto: boolean, when true will modulate the generated gradient.
TODO    - autospeed: float, determines the modulation rate when auto=tre
   
done    - reflect: boolean, seamless gradient by mirroring about t=0.5
done    - repeat: integer, repeats the gradient N times over the points,
                  eg. for when the input points have symmetry.
done    - splitoffset: float, determines the offset from the complement from
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
  self.reverse = false
  self["repeat"] = 1
  self.splitoffset = 0.1
  self.huepoints = 3
  -- self.saturation = 1.0
  -- self.brightness = 1.0
  self.alpha = 0.0
  self.preservewhite = false
  self.bypass = false
  self.phase = 0.0
  self.phasestep = 0.0 -- will be redundant when autogradient is implemented

  self.curvescale = 1.0

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
    STEP = true,
    SUB = true
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
  local cs = require("colorspace")
  local npoints = #xyrgb / 5
  local out = {}
  local p, col

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) and (not self.preservewhite or not e.iswhite(p)) then
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
      if (not self.preservewhite or not e.iswhite(p)) then
        local grad_t = (self.phase + color_t * lrepeat) % 1.0
        if self.reflect then grad_t = cs.mirror_t(grad_t) end
        if self.reverse then grad_t = 1 - grad_t end
        gcolor = cs.blendfn[self.blendmode](
                  self.usercolor1, self.usercolor2, grad_t)
        e.setcolor(p, gcolor)
      end

      if (not e.positionequal(p, p_prev)) then
        color_t = color_t + colorstep
      end
    end

    e.addpoint2(out, p)
    p_prev = p
  end
  return out
end


function gradient:apply_curvature(xyrgb)
  local e = require("eos")
  local cs = require("colorspace")
  local v2 = require("vec2")
  local npoints = #xyrgb / 5
  local out = {}
  local p0, p1, p2

  local function has_curvature(p0, p1, p2)
    return (p0 and p1 and p2)
      and not e.isblank2(p0)
      and not e.isblank2(p1)
      and not e.isblank2(p2)
      and not e.positionequal(p0, p1)
      and not e.positionequal(p1, p2)
  end

  local function is_path_start(p, p_prev)
    return ((not p_prev) or e.isblank(p_prev))
      and p and not e.isblank(p)
  end

  local function is_path_end(p, p_next)
    return ((not p_next) or e.isblank(p_next))
      and p and not e.isblank(p)
  end

  local curvature = {}
  for i=1,npoints do
    p0 = e.pointatindex(xyrgb, i-1)
    p1 = e.pointatindex(xyrgb, i)
    p2 = e.pointatindex(xyrgb, i+1)
    if has_curvature(p0, p1, p2) then
      table.insert(curvature, math.abs(v2.curvature(p0, p1, p2)))
    else
      table.insert(curvature, false)
    end
  end
  for i=1,npoints do
    p0 = e.pointatindex(xyrgb, i-1)
    p1 = e.pointatindex(xyrgb, i)
    p2 = e.pointatindex(xyrgb, i+1)
    if is_path_start(p1, p0) then
      curvature[i] = curvature[i+1]
    elseif is_path_end(p1, p2) then
      curvature[i] = curvature[i-1]
    end
  end
  local c, grad_t, gcolor
  for i=1,npoints do
    p0 = e.pointatindex(xyrgb, i-1)
    p1 = e.pointatindex(xyrgb, i)
    p2 = e.pointatindex(xyrgb, i+1)
    c = curvature[i]
    if c then
      grad_t = math.min(1, c*self.curvescale)
      if self.reverse then grad_t = 1 - grad_t end
      gcolor = cs.blendfn[self.blendmode](self.usercolor1, self.usercolor2, grad_t)
      e.setcolor(p1, gcolor)
    end
    e.addpoint2(out, p1)
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

  local ahue1 = (hsv.h - self.splitoffset) % 1.0
  local ahue2 = (hsv.h + self.splitoffset) % 1.0
  local acolor1 = cs.hsv_to_rgb({h=ahue1, s=hsv.s, v=hsv.v})
  local acolor2 = cs.hsv_to_rgb({h=ahue2, s=hsv.s, v=hsv.v})

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) then

      if (not self.preservewhite or not e.iswhite(p)) then
        local grad_t = (self.phase + color_t * lrepeat) % 1.0
        if self.reflect then grad_t = cs.mirror_t(grad_t) end
        if self.reverse then grad_t = 1 - grad_t end
        gcolor = cs.blendfn[self.blendmode](acolor1, acolor2, grad_t)
        e.setcolor(p, gcolor)
      end

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
      if (not self.preservewhite or not e.iswhite(p)) then
        local grad_t = (self.phase + color_t * lrepeat) % 1.0
        if self.reflect then grad_t = cs.mirror_t(grad_t) end
        if self.reverse then grad_t = 1 - grad_t end
        gcolor = cs.polyadic_gradient(keycolors, self.blendmode, grad_t)
        e.setcolor(p, gcolor)
      end

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

  local ahue1 = (hsv.h + 0.5 - self.splitoffset) % 1.0
  local ahue2 = (hsv.h + 0.5 + self.splitoffset) % 1.0
  local acolor1 = cs.hsv_to_rgb({h=ahue1, s=hsv.s, v=hsv.v})
  local acolor2 = cs.hsv_to_rgb({h=ahue2, s=hsv.s, v=hsv.v})
  local gcolors = {self.usercolor1, acolor1, acolor2}

  for i=1,npoints do
    p = e.pointatindex(xyrgb, i)

    if not e.isblank(p) then
      if (not self.preservewhite or not e.iswhite(p)) then
        local grad_t = (self.phase + color_t * lrepeat) % 1.0
        if self.reflect then grad_t = cs.mirror_t(grad_t) end
        if self.reverse then grad_t = 1 - grad_t end
        gcolor = cs.polyadic_gradient(gcolors, self.blendmode, grad_t)
        e.setcolor(p, gcolor)
      end

      if (not e.positionequal(p, p_prev)) then
        color_t = color_t + colorstep
      end
    end

    e.addpoint2(out, p)
    p_prev = p
  end
  return out
end

function gradient:apply_monochrome(xyrgb)
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
      if (not self.preservewhite or not e.iswhite(p)) then
        local grad_t = (self.phase + color_t * lrepeat) % 1.0
        if self.reflect then grad_t = cs.mirror_t(grad_t) end
        if self.reverse then grad_t = 1 - grad_t end
        gcolor = cs.blendfn[self.blendmode](
                  self.usercolor1, {r=0, g=0, b=0}, grad_t)
        e.setcolor(p, gcolor)
      end

      if (not e.positionequal(p, p_prev)) then
        color_t = color_t + colorstep
      end
    end

    e.addpoint2(out, p)
    p_prev = p
  end
  return out
end



function gradient:apply_alpha(inp, grad)
  local eos = require("eos")
  local cs = require("colorspace")
  local npoints = #inp / 5
  local out = {}
  local p, gp, incol, gradcol, acol
  for i=1,npoints do
    p = eos.pointatindex(inp, i)
    if not eos.isblank(p) then
      if (not self.preservewhite or not eos.iswhite(p)) then
        gp = eos.pointatindex(grad, i)
        incol = {r=p.r, g=p.g, b=p.b}
        gradcol = {r=gp.r, g=gp.g, b=gp.b}
        acol = cs.alpha_blend(incol, gradcol, self.alpha)
        p.r = acol.r
        p.g = acol.g
        p.b = acol.b
      end
    end
    eos.addpoint2(out, p)
  end
  return out
end


function gradient:in_1_list(inp)
  local out = {}
  local final = {}

  if self.bypass then
    self:outlet(2, "float", { #inp / 5 })
    self:outlet(1, "list", inp)
    return
  end

  if self.mode == "constant" then
    out = self:apply_constant(inp)
  elseif self.mode == "user" then
    out = self:apply_curvature(inp)
    -- out = self:apply_userdefined(inp)
  elseif self.mode == "analogous" then
    out = self:apply_analogous(inp)
  elseif self.mode == "polyadic" then
    out = self:apply_polyadic(inp)
  elseif self.mode == "splitcomplement" then
    out = self:apply_splitcomplement(inp)
  elseif self.mode == "mono" then
    out = self:apply_monochrome(inp)
  end

  if self.alpha ~= 0.0 then
    final = self:apply_alpha(inp, out)
  else
    final = out
  end

  self.phase = self.phase + self.phasestep

  self:outlet(2, "float", { #final / 5 })
  self:outlet(1, "list", final)
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
  elseif sel == "reverse" then
    self.reverse = (atoms[1] ~= 0)
  elseif sel == "repeat" then
    self["repeat"] = math.max(1, atoms[1])
  elseif sel == "splitoffset" then
    self.splitoffset = atoms[1]
  elseif sel == "huepoints" then
    self.huepoints = math.max(1, atoms[1])
  elseif sel == "blendmode" then
    if self.validblendmodes[atoms[1]] then
      self.blendmode = atoms[1]
    end
  elseif sel == "alpha" then
    self.alpha = math.max(0, math.min(1, atoms[1]))
  elseif sel == "phase" then
    self.phase = atoms[1] % 1.0
  elseif sel == "phasestep" then
    self.phasestep = atoms[1] % 1.0
  elseif sel == "preservewhite" then
    self.preservewhite = (atoms[1] ~= 0)
  elseif sel == "curvescale" then
    self.curvescale = atoms[1]
  end
end


