local colorspace = {}

function colorspace.hsv_to_rgb(hsv)
  local h, s, v = hsv.h, hsv.s, hsv.v
  local ro, go, bo
  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);
  i = i % 6
  if i == 0 then ro, go, bo = v, t, p
  elseif i == 1 then ro, go, bo = q, v, p
  elseif i == 2 then ro, go, bo = p, v, t
  elseif i == 3 then ro, go, bo = p, q, v
  elseif i == 4 then ro, go, bo = t, p, v
  elseif i == 5 then ro, go, bo = v, p, q
  end
  return {
    r = ro,
    g = go,
    b = bo
  }
end

function colorspace.rgb_to_hsv(rgb)
  local r, g, b = rgb.r, rgb.g, rgb.b
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, v
  v = max

  local d = max - min
  if max == 0 then
      s = 0
  else
      s = d / max
  end

  if max == min then
    h = 0 -- achromatic
  else
    if max == r then
      h = (g - b) / d
      if g < b then
          h = h + 6
      end
    elseif max == g then
        h = (b - r) / d + 2
    elseif max == b then
        h = (r - g) / d + 4
    end
    h = h / 6
  end

  return {h = h, s = s, v = v}
end


function colorspace.rgb_to_xyz(rgb)
  local function adjust(c)
    if c > 0.04045 then
      return ((c + 0.055) / 1.055) ^ 2.4
    else
      return c / 12.92
    end
  end

  local r = adjust(rgb.r)
  local g = adjust(rgb.g)
  local b = adjust(rgb.b)

  -- Convert to XYZ using the sRGB color space
  local x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
  local y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
  local z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

  return {x = x, y = y, z = z}
end


function colorspace.xyz_to_lab(xyz)
  local function f(t)
    if t > 0.008856 then
      return t ^ (1/3)
    else
      return (7.787 * t) + (16 / 116)
    end
  end

  local x = f(xyz.x / 0.95047)
  local y = f(xyz.y / 1.00000)
  local z = f(xyz.z / 1.08883)

  local l = (116 * y) - 16
  local a = 500 * (x - y)
  local b = 200 * (y - z)

  return {l = l, a = a, b = b}
end


function colorspace.lab_to_xyz(lab)
  local y = (lab.l + 16) / 116
  local x = lab.a / 500 + y
  local z = y - lab.b / 200

  local function f(t)
    if t^3 > 0.008856 then
        return t^3
    else
        return (t - 16 / 116) / 7.787
    end
  end

  return {
    x = f(x) * 0.95047,
    y = f(y),
    z = f(z) * 1.08883
  }
end


function colorspace.xyz_to_rgb(xyz)
  local x = xyz.x
  local y = xyz.y
  local z = xyz.z

  -- Convert to RGB using the sRGB color space
  local r = x * 3.2404542 - y * 1.5371385 - z * 0.4985314
  local g = -x * 0.9692660 + y * 1.8760108 + z * 0.0415560
  local b = x * 0.0556434 - y * 0.2040259 + z * 1.0572252

  local function adjust(c)
    if c > 0.0031308 then
      return 1.055 * (c ^ (1 / 2.4)) - 0.055
    else
      return 12.92 * c
    end
  end

  return {
      r = adjust(r),
      g = adjust(g),
      b = adjust(b)
  }
end


function colorspace.lab_to_hcl(lab)
  local h = math.atan(lab.b, lab.a) * (180 / math.pi)
  if h < 0 then h = h + 360 end
  local c = math.sqrt(lab.a^2 + lab.b^2)
  local l = lab.l

  return {h = h, c = c, l = l}
end


function colorspace.hcl_to_lab(hcl)
  local h_rad = hcl.h * (math.pi / 180)
  local a = math.cos(h_rad) * hcl.c
  local b = math.sin(h_rad) * hcl.c
  local l = hcl.l

  return {l = l, a = a, b = b}
end


function colorspace.lab_to_rgb(lab)
  local xyz = colorspace.lab_to_xyz(lab)
  return colorspace.xyz_to_rgb(xyz)
end


function colorspace.rgb_to_lab(rgb)
  local xyz = colorspace.rgb_to_xyz(rgb)
  return colorspace.xyz_to_lab(xyz)
end

function colorspace.hcl_to_rgb(hcl)
  local lab = colorspace.hcl_to_lab({h=hcl.h, c=hcl.c, l=hcl.l})
  return colorspace.lab_to_rgb(lab)
end

function colorspace.rgb_to_hcl(rgb)
  return colorspace.lab_to_hcl(colorspace.rgb_to_lab(rgb))
end

function colorspace.rgb_to_cmy(r, g, b)
    return 1 - r, 1 - g, 1 - b
end

function colorspace.cmy_to_rgb(c, m, y)
    return 1 - c, 1 - m, 1 - y
end




function colorspace.mirror_t(t)
  t = t % 1.0
  return 1.0 - math.abs(2.0 * t - 1.0)
end


function colorspace.hsv_gradient(rgb1, rgb2, t)
  local hsv1 = colorspace.rgb_to_hsv(rgb1)
  local hsv2 = colorspace.rgb_to_hsv(rgb2)
  local h = hsv1.h + t * (hsv2.h - hsv1.h)
  local s = hsv1.s + t * (hsv2.s - hsv1.s)
  local v = hsv1.v + t * (hsv2.v - hsv1.v)

  -- Adjust hue for wrapping around 1
  if math.abs(hsv2.h - hsv1.h) > 0.5 then
    if hsv1.h > hsv2.h then
      h = hsv1.h + t * ((hsv2.h + 1) - hsv1.h)
    else
      h = hsv1.h + t * (hsv2.h - (hsv1.h + 1))
    end
  end

  h = h % 1
  return colorspace.hsv_to_rgb({h = h, s = s, v = v})
end


function colorspace.rgb_gradient(rgb1, rgb2, t)
  return {
    r = rgb1.r + t * (rgb2.r - rgb1.r),
    g = rgb1.g + t * (rgb2.g - rgb1.g),
    b = rgb1.b + t * (rgb2.b - rgb1.b)
  }
end

function colorspace.hcl_gradient(rgb1, rgb2, t)
  local lab1 = colorspace.rgb_to_lab(rgb1)
  local lab2 = colorspace.rgb_to_lab(rgb2)
  local hcl1 = colorspace.lab_to_hcl(lab1)
  local hcl2 = colorspace.lab_to_hcl(lab2)
  -- print(string.format("HCL(%.2f, %.2f, %.2f)", hcl1.h, hcl1.c, hcl1.l))
  local dh = hcl2.h - hcl1.h
  if dh < -180 then
    dh = dh + 360
  elseif dh > 180 then
    dh = dh - 360
  end

  local h = hcl1.h + t * dh
  if h < 0 then
    h = h + 360
  elseif h > 360 then
    h = h - 360
  end

  local c = hcl1.c + t * (hcl2.c - hcl1.c)
  local l = hcl1.l + t * (hcl2.l - hcl1.l)

  local labgrad = colorspace.hcl_to_lab({h=h, c=c, l=l})
  return colorspace.lab_to_rgb(labgrad)
end

function colorspace.step_gradient(rgb1, rgb2, t)
  if t < 0.5 then
    return rgb1
  else
    return rgb2
  end
end


function colorspace.subtractive_gradient(col1, col2, t)
    local function lerp(a, b, t1)
      return a + t1 * (b - a)
    end
    local function lerp2(a, b, t)
        if t <= 0.5 then
            -- Scale t to the [0, 1] range for the first half of the interpolation
            local scaledT = t * 2
            -- Interpolate from 'a' towards 'a + b', but ensure the sum does not exceed 1
            return a + scaledT * (math.min(1, a + b) - a)
        else
            -- Scale t to the [0, 1] range for the second half of the interpolation
            local scaledT = (t - 0.5) * 2
            -- Interpolate from 'a + b' towards 'b', starting the interpolation at the sum 'a + b'
            return math.min(1, a + b) + scaledT * (b - math.min(1, a + b))
        end
    end



    -- Convert RGB to CMY
    local c1, m1, y1 = colorspace.rgb_to_cmy(col1.r, col1.g, col1.b)
    local c2, m2, y2 = colorspace.rgb_to_cmy(col2.r, col2.g, col2.b)

    -- Linearly interpolate the CMY values based on t
    local mixedC = lerp2(c1, c2, t)
    local mixedM = lerp2(m1, m2, t)
    local mixedY = lerp2(y1, y2, t)

    -- Ensure CMY values do not exceed 1
    -- mixedC = math.min(mixedC, 1)
    -- mixedM = math.min(mixedM, 1)
    -- mixedY = math.min(mixedY, 1)

    -- Convert the mixed CMY back to RGB
    local r, g, b = colorspace.cmy_to_rgb(mixedC, mixedM, mixedY)

    return {r = r, g = g, b = b}
end


colorspace.blendfn = {
  RGB = colorspace.rgb_gradient,
  HSV = colorspace.hsv_gradient,
  HCL = colorspace.hcl_gradient,
  STEP = colorspace.step_gradient,
  SUB = colorspace.subtractive_gradient
}

function colorspace.polyadic_gradient(rgbcolors, blendmode, t)
  local ncolors = #rgbcolors
  if ncolors == 0 then
    print("polyadic_gradient(): ERROR: no colors")
    return {r=0, g=0, b=0}
  end
  if ncolors == 1 then return rgbcolors[1] end
  local segmentlen = 1 / (ncolors - 1)
  local segmentidx = math.min(ncolors - 1, math.floor(t / segmentlen))
  local coloridx1 = segmentidx + 1
  local coloridx2 = math.min(coloridx1 + 1, ncolors)
  local grad_t = (t - segmentidx * segmentlen) / segmentlen
  return colorspace.blendfn[blendmode](rgbcolors[coloridx1], rgbcolors[coloridx2], grad_t)
  -- return colorspace.hcl_gradient(rgbcolors[coloridx1], rgbcolors[coloridx2], grad_t)
end


function colorspace.alpha_blend(c1, c2, alpha)
  return {
      r = alpha * c1.r + (1 - alpha) * c2.r,
      g = alpha * c1.g + (1 - alpha) * c2.g,
      b = alpha * c1.b + (1 - alpha) * c2.b
  }
end

return colorspace
