local ColorConstants = {}
local mt = {}

-- Define color prototypes (not exposed directly)
local color_prototypes = {
  -- Primary colors
  RED = {r=1, g=0, b=0, a=1},
  GREEN = {r=0, g=1, b=0, a=1},
  BLUE = {r=0, g=0, b=1, a=1},

  -- Secondary colors
  YELLOW = {r=1, g=1, b=0, a=1},
  CYAN = {r=0, g=1, b=1, a=1},
  MAGENTA = {r=1, g=0, b=1, a=1},

  -- Grayscale
  BLACK = {r=0, g=0, b=0, a=1},
  WHITE = {r=1, g=1, b=1, a=1},
  GRAY = {r=0.5, g=0.5, b=0.5, a=1},
  DARK_GRAY = {r=0.25, g=0.25, b=0.25, a=1},
  LIGHT_GRAY = {r=0.75, g=0.75, b=0.75, a=1},

  -- Common UI colors
  TRANSPARENT = {r=0, g=0, b=0, a=0},

  -- Extended palette
  ORANGE = {r=1, g=0.5, b=0, a=1},
  PURPLE = {r=0.5, g=0, b=0.5, a=1},
  PINK = {r=1, g=0.75, b=0.8, a=1},
  BROWN = {r=0.6, g=0.3, b=0, a=1},
  TURQUOISE = {r=0, g=0.8, b=0.8, a=1},
  LIME = {r=0.5, g=1, b=0, a=1},
  VIOLET = {r=0.5, g=0, b=1, a=1},
  GOLD = {r=1, g=0.84, b=0, a=1},
  SILVER = {r=0.75, g=0.75, b=0.75, a=1},
  CRIMSON = {r=0.86, g=0.08, b=0.24, a=1},
  INDIGO = {r=0.29, g=0, b=0.51, a=1},

  NEON_GREEN = {r=0.57, g=1, b=0.06, a=1},
  NEON_PINK = {r=1, g=0.11, b=0.68, a=1},
  NEON_BLUE = {r=0.36, g=0.84, b=1, a=1},
  HOT_PINK = {r=1, g=0.41, b=0.71, a=1},
  ELECTRIC_BLUE = {r=0.49, g=0.98, b=1, a=1}
}

function ColorConstants.new(r, g, b, a)
  return {r=r or 0, g=g or 0, b=b or 0, a=a or 1}
end

function ColorConstants.exists(name)
  return color_prototypes[name] ~= nil
end

function ColorConstants.getNames()
  local names = {}
  for name, _ in pairs(color_prototypes) do
    table.insert(names, name)
  end
  return names
end

function mt.__index(_, key)
  local proto = color_prototypes[key]
  if proto then
    return {r=proto.r, g=proto.g, b=proto.b, a=proto.a}
  end
  return nil
end

setmetatable(ColorConstants, mt)
return ColorConstants
