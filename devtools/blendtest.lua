-- Function to generate transition points for RGB laser scanner
function generate_transition_points(segments)
  -- First, collect all unique transition points (start and end of each segment)
  local unique_points = {}
  for _, segment in ipairs(segments) do
    unique_points[segment.x1] = true
    unique_points[segment.x2] = true
  end

  -- Convert to sorted array
  local transition_points = {}
  for x, _ in pairs(unique_points) do
    table.insert(transition_points, x)
  end
  table.sort(transition_points)

  -- Generate output points for all transitions
  local output_points = {}
  local active_segments = {}  -- Track currently active segments

  for i, x in ipairs(transition_points) do
    -- Determine which segments are starting and ending at this x-coordinate
    local starting_segments = {}
    local ending_segments = {}

    for _, segment in ipairs(segments) do
      -- Using epsilon for floating point comparison
      if math.abs(segment.x1 - x) < 1e-9 then
        table.insert(starting_segments, segment)
      end
      if math.abs(segment.x2 - x) < 1e-9 then
        table.insert(ending_segments, segment)
      end
    end

    -- Process ending segments first
    for _, segment in ipairs(ending_segments) do
      -- Remove from active segments
      for j = #active_segments, 1, -1 do
        if active_segments[j].id == segment.id then
          table.remove(active_segments, j)
          break
        end
      end
    end

    -- If any segments are ending at this point, we need a color point followed by a black point
    if #ending_segments > 0 then
      -- Get colors of segments that are ending
      local ending_colors = {}
      for _, segment in ipairs(ending_segments) do
        table.insert(ending_colors, segment.color)
      end

      -- Add the color point (either the segment color or blended if multiple)
      local color_to_use
      if #ending_colors == 1 then
        color_to_use = ending_colors[1]
      else
        color_to_use = blend_colors(ending_colors)
      end

      table.insert(output_points, {x = x, color = color_to_use})

      -- Then add a black point
      table.insert(output_points, {x = x, color = {r=0, g=0, b=0}})
    end

    -- Process starting segments
    for _, segment in ipairs(starting_segments) do
      -- Add to active segments
      table.insert(active_segments, segment)
    end

    -- If any segments are starting at this point, we need a black point followed by a color point
    if #starting_segments > 0 then
      -- Add a black point
      table.insert(output_points, {x = x, color = {r=0, g=0, b=0}})

      -- Get colors of all active segments
      local active_colors = {}
      for _, segment in ipairs(active_segments) do
        table.insert(active_colors, segment.color)
      end

      -- Add the color point (either the segment color or blended if multiple)
      local color_to_use
      if #active_colors == 1 then
        color_to_use = active_colors[1]
      else
        color_to_use = blend_colors(active_colors)
      end

      table.insert(output_points, {x = x, color = color_to_use})
    end
  end

  return output_points
end

-- Fixed blend_colors function (fixed the variable assignment typos)
function blend_colors(colors)
  local c = {r=0, g=0, b=0}
  for i=1, #colors do
    c.r = c.r + colors[i].r
    c.g = c.g + colors[i].g  -- Fixed: Now correctly adds to c.g
    c.b = c.b + colors[i].b  -- Fixed: Now correctly adds to c.b
  end
  return {r=c.r/#colors, g=c.g/#colors, b=c.b/#colors}
end

-- Helper function to check if a color is black
function is_color_black(color)
  return math.abs(color.r) < 1e-9 and math.abs(color.g) < 1e-9 and math.abs(color.b) < 1e-9
end

-- Example usage with both non-overlapping and overlapping segments:
-- Non-overlapping segments example
--
local segments = {
    {id = 1, color = {r=1, g=0, b=0}, x1 = -0.9, x2 = -0.7},  -- Red segment
    {id = 2, color = {r=0, g=1, b=0}, x1 = -0.1, x2 = 0.1},   -- Green segment
    {id = 3, color = {r=0, g=0, b=1}, x1 = 0.5, x2 = 0.8}     -- Blue segment
}

-- Overlapping segments example
local segments_overlapping = {
    {id = 1, color = {r=1, g=0, b=0}, x1 = -0.5, x2 = 0.2},   -- Red segment
    {id = 2, color = {r=0, g=1, b=0}, x1 = 0.0, x2 = 0.8},    -- Green segment
    {id = 3, color = {r=0, g=0, b=1}, x1 = 0.4, x2 = 0.6}     -- Blue segment
}

local transition_points = generate_transition_points(segments_overlapping)

-- Print the result
for i, point in ipairs(transition_points) do
    print(string.format("Point %d: x=%.3f, color=(%.1f, %.1f, %.1f)",
          i, point.x, point.color.r, point.color.g, point.color.b))
end
