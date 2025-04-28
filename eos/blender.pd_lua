local B = pd.Class:new():register("blender")

function B:initialize(sel, atoms)
  -- Set up inlets and outlets
  self.inlets = 2    -- bang, bufsize, rule, cycle
  self.outlets = 2  -- cell state output

  self.screenunit = 1.0 / 2047.0
  self.time = 0.0

  self.numsegments = 2
  self.segs = 1
  self.points = {}

  self.min_seg_width = 0.001
  self.max_seg_width = 0.3

  -- self.numpoints = 200
  self.noise_amp = 0.18
  self.noise_divergence = 0.03
  self.timestep = 0.01

  self.widthstep = 0.003
  self.posstep = 0.002
  self.width_t = 0
  self.pos_t = 0

  self.dwellnum = 2
  -- self.cellwidth = 0.0

  self.gradcolor1 = {r=1, g=0, b=0}
  self.gradcolor2 = {r=0, g=0, b=1}

  self.colormode = 1 -- 0 = HSV, 1 = gradient

  if type(atoms[1]) == "number" then
    self.numsegments = math.floor(atoms[1])
  end

  self:init_segs()

  return true
end

function B:phi_palette(num_colors, hue_offset)
  local eos = require("eos") -- provides hsv_to_rgb()
  local colors = {}
  local phi = 0.618033988749895
  hue_offset = hue_offset or 0

  for i = 1, num_colors do
    local hue = (hue_offset + i * phi) % 1.0
    local saturation = 1.0
    local value = 1.0
    colors[i] = eos.hsv2rgb(hue, saturation, value)
  end
  return colors
end

function B:poly_palette(num_hues, hue_offset)
  local cs = require("colorspace")
  local colors = {}
  local huestep = 1.0 / num_hues
  for i=0,num_hues-1 do
    local hue = (hue_offset + i * huestep) % 1.0
    table.insert(colors, cs.hsv_to_rgb({h=hue, s=1, v=1}))
  end
  return colors
end

function B:init_segs()
  local eos = require("eos")
  local segs = {}
  -- local cmy = {
  --   {r=0,g=1,b=1},
  --   {r=1,g=0,b=1},
  --   {r=1,g=1,b=0}
  -- }
  -- local pal = self:phi_palette(self.numsegments, math.random())
  for i=1, self.numsegments do
    -- local c = pal[i]
    -- local c = eos.hsv2rgb(math.random(), 1, 1)
    -- local c = cmy[(i-1) % #cmy + 1]
    local newseg = {
      id = i,
      color = {r=0, g=0, b=0},
      x1 = 0,
      x2 = 0
    }
    segs[i] = newseg
  end
  self.segs = segs
end

function B:seamless_noise(ang, rad, t)
  local simplex = require("simplex")
  local x = rad * math.cos(ang * math.pi*2)
  local y = rad * math.sin(ang * math.pi*2)
  return simplex.noise3d(x, y, t)
end


function B:update_segs_wrap()
  local S = require("simplex")
  local eos = require("eos")
  local pal = self:poly_palette(self.numsegments, (self.time*0.01) % 1.0)
  -- local pal = self:phi_palette(self.numsegments, (self.time*0.01) % 1.0)
  local wrange = (self.max_seg_width - self.min_seg_width)
  local basewidth = wrange * 0.5

  for i = 1, self.numsegments do
    local n = wrange * (1 + S.noise3d(i, self.width_t, 123.456)) * 0.5
    local w = basewidth + n

    local t = (i-1) / (self.numsegments-1) -- t goes from 0 to 1
    local x = t * 2 - 1 -- x goes from -1 to 1
    local px = x + self.noise_amp * self:seamless_noise(t, self.noise_divergence, self.time)
    -- px = eos.wrap_neg1_to_1(px)

    -- local prange = 1 - self.max_seg_width / 2
    -- local px = prange * S.noise3d(i*34.567, self.pos_t, 234.567)

    self.segs[i].x1 = math.max(-1, math.min(1, (px - w/2)))
    self.segs[i].x2 = math.max(-1, math.min(1, (px + w/2)))
    -- self.segs[i].x1 = eos.wrap_neg1_to_1(px - w/2)
    -- self.segs[i].x2 = eos.wrap_neg1_to_1(px + w/2)
    self.segs[i].color = pal[i]
  end
end

function B:update_segs()
  local S = require("simplex")
  local pal = self:poly_palette(self.numsegments, (self.time*0.01) % 1.0)
  -- local pal = self:phi_palette(self.numsegments, (self.time*0.01) % 1.0)
  local wrange = (self.max_seg_width - self.min_seg_width)
  local basewidth = wrange * 0.5

  for i = 1, self.numsegments do
    local n = wrange * (1 + S.noise3d(i, self.width_t, 123.456)) * 0.5
    local w = basewidth + n

    local prange = 1 - self.max_seg_width / 2
    local px = prange * S.noise3d(i*34.567, self.pos_t, 234.567)
    self.segs[i].x1 = px - w/2
    self.segs[i].x2 = px + w/2
    self.segs[i].color = pal[i]
  end
end

function B:blend_colors(colors)
  local cs = require("colorspace")
  if #colors == 0 then
    return {r=0, g=0, b=0}
  elseif #colors == 1 then
    return colors[1]
  else
    local color = colors[1]
    -- local color = cs.hcl_gradient(colors[1], colors[2], 0.5)
    for i=2, #colors do
      color = cs.hcl_gradient(color, colors[i], 1/i)
    end
    return color
  end
end


function B:blend_colors1(colors)
  local cs = require("colorspace")
  if #colors == 0 then
    return {r=0, g=0, b=0}
  elseif #colors == 1 then
    return colors[1]
  elseif #colors == 2 then
      return cs.hcl_gradient(colors[1], colors[2], 0.5)
  else
    local color = cs.hcl_gradient(colors[1], colors[2], 0.5)
    for i=3, #colors do
      color = cs.hcl_gradient(color, colors[i], 1/i)
    end
    return color
  end
end


function B:blend_colors_lab(colors)
  local cs = require("colorspace")
  if #colors == 0 then
    return {r=0, g=0, b=0}
  elseif #colors == 1 then
    return colors[1]
  else
    -- Convert all to Lab
    local labs = {}
    for i=1, #colors do
      labs[i] = cs.rgb_to_lab(colors[i])
    end

    -- Average Lab values
    local l = 0
    local a = 0
    local b = 0
    for i=1, #labs do
      l = l + labs[i].l
      a = a + labs[i].a
      b = b + labs[i].b
    end

    local avg_lab = {
      l = l / #labs,
      a = a / #labs,
      b = b / #labs
    }

    return cs.lab_to_rgb(avg_lab)
  end
end


function B:get_colors_at_point(px, segments)
  local colors = {}
  for i=1, #segments do
    if segments[i].x1 <= px and segments[i].x2 >= px then
      table.insert(colors, segments[i].color)
    end
  end
  return colors
end


function B:get_points_bruteforce()
  local eos = require("eos")
  local black = {r=0,g=0,b=0}
  local points = {}
  local out = {}
  local cur_color = black

  -- TODO optimize - sort points by x then run this loop from
  -- minx to maxx instead of from 0 to 1
  for x=-1,1, self.screenunit do
    local colors = self:get_colors_at_point(x, self.segs)
    if #colors == 0 then
      if not eos.colorequal(cur_color, black) then
        table.insert(points, eos.newpoint2(x, 0, cur_color))
        table.insert(points, eos.newpoint2(x, 0, black))
        cur_color = black
      end
    else
      local color = self:blend_colors(colors)
      -- local color = self:blend_colors_lab(colors)
      if not eos.colorequal(cur_color, color) then
        table.insert(points, eos.newpoint2(x, 0, cur_color))
        table.insert(points, eos.newpoint2(x, 0, color))
        cur_color = color
      end
    end
  end

  for i=1,#points do
    eos.addpoint2(out, points[i])
  end

  return out
end


function B:get_points()
  local eos = require("eos")
  local points = {}
  local out = {}

  for i=1, self.numsegments do
    local seg = self.segs[i]
    table.insert(points, eos.newpoint2(seg.x1, 0, seg.color))
    table.insert(points, eos.newpoint2(seg.x2, 0, seg.color))
  end

  table.sort(points, function(a, b)
    return a.x < b.x
  end)

  -- Render
  eos.addblank(out, points[1], self.dwellnum)
  for i=1, #points do
      eos.addpoint2(out, points[i], 1)
  end
  eos.addpoint2(out, points[#points], self.dwellnum)
  eos.addblank(out, points[#points])

  return out
end


function B:in_1_bang()
  self:update_segs()
  local out = self:get_points_bruteforce()
  -- local out = self:get_points()

  self.time = self.time + self.timestep
  self.width_t = self.width_t + self.widthstep
  self.pos_t = self.pos_t + self.posstep

  self:outlet(2, "float", {#out / 5})
  self:outlet(1, "list", out)
end




function B:in_2(sel, atoms)
  if sel == "numsegments" then
    self.numsegments = math.max(1, atoms[1])
    self:init_segs()
  elseif sel == "timestep" then
    self.timestep = atoms[1] * 0.001
    self.posstep = self.timestep
    self.widthstep = self.timestep
  elseif sel == "dwell" then
    self.dwellnum = math.max(0, atoms[1])
  elseif sel == "noiseamp" then
    self.noise_amp = atoms[1] * 0.01
  elseif sel == "noisediverge" then
    self.noise_divergence = atoms[1]
  elseif sel == "cellwidth" then
    self.cellwidth = atoms[1]
  elseif sel == "colormode" then
    self.colormode = math.max(0, math.min(1, atoms[1]))
  elseif sel == "gradcolor1" then
    self.gradcolor1 = {r= atoms[1], g=atoms[2], b=atoms[3]}
  elseif sel == "gradcolor2" then
    self.gradcolor2 = {r= atoms[1], g=atoms[2], b=atoms[3]}
  end
end

