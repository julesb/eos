
-- local function get_contours(landscape_function, contour_height)
-- 	local paths = {}
-- 	local width, height = 100, 100 -- size of the landscape
-- 	local dx, dy = 1, 1 -- step size in each direction
-- 	local noisescale = 1.0
--
-- 	local lerp = function(a, b, t)
-- 		return a + (b - a) * t
-- 	end
--
-- 	-- Generate landscape.
-- 	local landscape = {}
--
-- 	for y = 0, height, dy do
-- 		for x = 0, width, dx do
-- 			landscape[y * width + x] = landscape_function(x * noisescale, y * noisescale)
-- 		end
-- 	end
--
-- 	-- Detect contours.
-- 	for y = 0, height - dy, dy do
-- 		for x = 0, width - dx, dx do
-- 			local indices = {
-- 				(y * width + x),
-- 				((y + dy) * width + x),
-- 				((y + dy) * width + x + dx),
-- 				(y * width + x + dx),
-- 			}
-- 			local corners = {
-- 				landscape[indices[1]],
-- 				landscape[indices[2]],
-- 				landscape[indices[3]],
-- 				landscape[indices[4]],
-- 			}
-- 			local path = {}
--
-- 			for i = 1, 4 do
-- 				local next_i = i % 4 + 1
-- 				if (corners[i] - contour_height) * (corners[next_i] - contour_height) < 0 then
-- 					local t = (contour_height - corners[i]) / (corners[next_i] - corners[i])
-- 					local xi = (indices[i] % width) * dx
-- 					local yi = math.floor(indices[i] / width) * dy
-- 					local x_next = (indices[next_i] % width) * dx
-- 					local y_next = math.floor(indices[next_i] / width) * dy
-- 					local x_contour = lerp(xi, x_next, t)
-- 					local y_contour = lerp(yi, y_next, t)
-- 					table.insert(path, x_contour)
-- 					table.insert(path, y_contour)
-- 				end
-- 			end
--
-- 			if #path > 0 then
-- 				table.insert(paths, path)
-- 			end
-- 		end
-- 	end
--
-- 	return paths
-- end

local simplex = require("simplex")
local v2 = require("vec2")
local ms = require("luams")

-- landscape = simplex.noise2d


local landscape = function(x, y)
  return simplex.noise2d(x*0.05, y*0.05)
end

-- local landscape = function(x, y)
--   return v2.dist(v2.new(x, y), v2.new(50, 50)) * 0.02
-- end

local image = {}
local imagedim=100
for y=1,imagedim do
  local row = {}
  for x = 1,imagedim do
    table.insert(row, landscape(x, y))
  end
  table.insert(image, row)
end

-- local contours = get_contours(landscape, 0.9)
local layers = ms.getContour(image, { 0.5 })
local contours = layers[1]
print("contours: ", #contours)
for k,v in ipairs(contours) do
  print(k, #v)
  -- for k2,v2 in ipairs(v) do
  --   print(k2, #v2)
  -- end
end

for c = 1, #contours do
  local path = contours[c]
	print(string.format("%03d: %s", c, table.concat(path, ", ")))
  for i=1, #path, 2 do
    local x,y = path[i], path[i+1]
    --print(landscape(x, y))
  end
end





