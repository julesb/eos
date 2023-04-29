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


return palettes
