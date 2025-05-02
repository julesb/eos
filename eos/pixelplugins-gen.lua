local gen = {}

gen.sine = function(color, freq, amp, phase)
  color = color or {r=1, g=1, b=1, a=1}
  freq = freq or 1
  amp = amp or 1
  phase = phase or 0
  local c = {color.r or 0, color.g or 0, color.b or 0, color.a or 1}
  local phase_offset = -math.pi / 2
  local fn = function(x, _, _)
    local theta = x * math.pi * 2 * freq + phase + phase_offset
    local sine = amp * (0.5 + 0.5 * math.sin(theta))
    sine = math.max(0, math.min(1, sine))
    return c[1]*sine, c[2]*sine, c[3]*sine, 1
  end

  return {
    type = "map",
    fn = fn
  }
end

gen.square = function(color, freq, duty, phase)
  color = color or {r=1, g=1, b=1, a=1}
  freq = freq or 1
  duty = duty or 0.5 -- default 50% duty cycle
  phase = phase or 0
  local c = {color.r or 0, color.g or 0, color.b or 0, color.a or 1}
  local phase_offset = -math.pi / 2
  local fn = function(x)
    local t = (x * freq + (phase+phase_offset) / (2 * math.pi)) % 1
    -- local t = (x * freq + phase / (2 * math.pi)) % 1
    local v = (t < duty) and 1 or 0
    return c[1]*v, c[2]*v, c[3]*v, c[4]
  end

  return {type = "map", fn = fn}
end

gen.saw = function(color, freq, phase)
  color = color or {r=1, g=1, b=1, a=1}
  freq = freq or 1
  phase = phase or 0
  local c = {color.r or 0, color.g or 0, color.b or 0, color.a or 1}

  local fn = function(x)
    local t = (x * freq + phase / (2 * math.pi)) % 1
    local v = freq >= 0 and t or 1 - t -- negative freq = reverse ramp
    return c[1]*v, c[2]*v, c[3]*v, c[4]
  end

  return {type = "map", fn = fn}
end

gen.triangle = function(color, freq, phase)
  color = color or {r=1, g=1, b=1, a=1}
  freq = freq or 1
  phase = phase or 0
  local c = {color.r or 0, color.g or 0, color.b or 0, color.a or 1}

  local fn = function(x)
    local t = (x * freq + phase / (2 * math.pi)) % 1
    local v = 1 - math.abs(2 * t - 1) -- symmetric triangle wave
    return c[1]*v, c[2]*v, c[3]*v, c[4]
  end

  return {type = "map", fn = fn}
end

return gen

