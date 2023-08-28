local palettes = {}



function palettes.gradient(hsv1, hsv2, t)
    local eos = require("eos")
    local hsv = {
        h = hsv1.h + t * (hsv2.h - hsv1.h),
        s = hsv1.s + t * (hsv2.s - hsv1.s),
        v = hsv1.v + t * (hsv2.v - hsv1.v)
    }
    return eos.hsv2rgb(hsv.h, hsv.s, hsv.v)
end


function palettes.sinebow(t)
  t = 0.5 - t
  return {
    r = math.sin(math.pi * (t + 0 / 3)) ^ 2,
    g = math.sin(math.pi * (t + 1 / 3)) ^ 2,
    b = math.sin(math.pi * (t + 2 / 3)) ^ 2
  }
end

function palettes.blackbody(t)
  local r, g, b
  t = math.max(0, math.min(t, 1))
  if t < 0.4 then
    r = t / 0.4
    g = 0
    b = (0.4 - t) / 0.4
  elseif t < 0.8 then
    r = 1
    g = (t - 0.4) / 0.4
    b = 0
  else
    r = (1 - (t - 0.8) / 0.2)
    g = 1
    b = 1
  end

  return { r = r, g = g, b = b }
end


return palettes
