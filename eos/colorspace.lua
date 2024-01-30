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




return colorspace
