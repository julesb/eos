
local contourmap = pd.Class:new():register("contourmap")


function contourmap:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  self.noisedimx = 32
  self.noisedimy = 32
  self.isovalue = 0.2
  self.nlayers = 3
  self.noisescale = 0.03
  self.timestep = 0.003
  self.time = 0.0
  self.framecount = 0
  self.basehue = 0
  self.optimizepath = false
  return true
end

function contourmap:make_isovalues(n, v)
  if n == 2 then
    return { -1 * v, v }
  elseif n == 3 then
    return { -1 * v, 0, v }
  else
    return { v }
  end
end


function contourmap:create_landscape(dimx, dimy, fn)
  local image = {}
  for y=1,dimy do
    local row = {}
    for x = 1,dimx do
      table.insert(row, fn(x, y))
    end
    table.insert(image, row)
  end
  return image
end


function contourmap:sort_paths(paths)
  local v2 = require("vec2")
  local eos = require("eos")

  local get_endpoints = function(path)
    return {
      v2.new(path[1], path[2]),
      v2.new(path[#path-4], path[#path-3])
    }
  end

  local find_closest_endpoint_info = function(pathidx, seen)
    local targetpath = paths[pathidx]
    local endpoints = get_endpoints(targetpath)
    local searchpos = endpoints[2]
    local mininfo = {
      dist = 999999,
      pathidx = 0,
      endidx = 1-- 1=first point, 2=last point in path
    }
    for searchidx=1, #paths do
      if searchidx ~= pathidx and not seen[searchidx] then
        endpoints = get_endpoints(paths[searchidx])
        local startdist = v2.dist_sqr(searchpos, endpoints[1])
        local enddist = v2.dist_sqr(searchpos, endpoints[2])
          if startdist < mininfo.dist then
            mininfo.dist = startdist
            mininfo.pathidx = searchidx
            mininfo.endidx = 1
          end
          if enddist < mininfo.dist then
            mininfo.dist = enddist
            mininfo.pathidx = searchidx
            mininfo.endidx = 2
          end
      end
    end
    return mininfo
  end

  local path_deepcopy = function(path)
    local copy = {}
    for _,v in ipairs(path) do
      table.insert(copy, v)
    end
    return copy
  end

  local seen_idxs = { [1] = true }
  local nextpathinfo = find_closest_endpoint_info(1, seen_idxs)
  local sorted = { paths[1] }
  -- local sorted = { path_deepcopy(paths[1]) }

  while #sorted < #paths do
    local nextpath = paths[nextpathinfo.pathidx]
    local newpath = {}
    if nextpathinfo.endidx == 1 then
      newpath = nextpath
      -- newpath = path_deepcopy(nextpath)
    else
      -- reverse points in path
      for pidx = #nextpath - 4, 1, -5 do
        local x = nextpath[pidx  ]
        local y = nextpath[pidx+1]
        local r = nextpath[pidx+2]
        local g = nextpath[pidx+3]
        local b = nextpath[pidx+4]
        eos.addpoint(newpath, x, y, r, g, b)
      end
    end
    table.insert(sorted, newpath)
    seen_idxs[nextpathinfo.pathidx] = true
    nextpathinfo = find_closest_endpoint_info(nextpathinfo.pathidx, seen_idxs)
  end
  return sorted
end


function contourmap:in_1_bang()
  local ms = require("marchingsqr")
  local simplex = require("simplex")
  local eos = require("eos")
  local v2 = require("vec2")

  -- divide hue space into n equidistant hues, return the ith hue
  local getcolor = function(i, n)
    return eos.hsv2rgb(self.basehue + 1 / n * i, 1, 1)
  end

  -- noise 3d
  local landscape_noise3d = function(x, y)
    local cx = self.noisedimx / 2
    local cy = self.noisedimy / 2
    local xoff,yoff = 123.123, 201.813
    return simplex.noise3d(
      xoff + (x-cx)*self.noisescale,
      yoff + (y-cy)*self.noisescale,
      self.time
    )
  end

  local landscape_fn = landscape_noise3d
  local image = contourmap:create_landscape(self.noisedimx,
                                            self.noisedimy,
                                            landscape_fn)
  local layers = ms.getContour(image, contourmap:make_isovalues(self.nlayers, self.isovalue))
  local out = {}
  local x, y, r, g, b
  local maxdim = math.max(self.noisedimx, self.noisedimy)
  local flatpaths = {}

  for lidx = 1,#layers do
    local contours = layers[lidx]
    local col = getcolor(lidx-1, #layers)

    for c=1,#contours do
      local path = contours[c]
      local newpath = {}
      local isclosed = (v2.dist(v2.new(path[1], path[2]),
                                v2.new(path[#path-1], path[#path])) < 2)
      -- pre blank
      x,y = 2*path[1]/maxdim - 1, 2*path[2]/maxdim - 1
      eos.addpoint(newpath, x, y, 0, 0, 0, 8)

      if not isclosed then
        -- bright endpoint
        eos.addpoint(newpath, x, y, 1, 1, 1, 8)
      end

      for i=1,#path, 2 do
        x,y = 2*path[i]/maxdim - 1, 2*path[i+1]/maxdim - 1
        r, g, b = col.r, col.g, col.b
        eos.addpoint(newpath, x, y, r, g, b)
      end

      if isclosed then
        -- close the loop
        eos.addpoint(newpath,
                     2*path[1]/maxdim-1,
                     2*path[2]/maxdim-1,
                     r, g, b, 4)
      else
        -- dwell on the last path point before going white
        -- to prevent white pre-tails
        eos.addpoint(newpath, x, y, r, g, b, 4)
        -- bright endpoint
        eos.addpoint(newpath, x, y, 1, 1, 1, 8)
      end

      --post blank
      eos.addpoint(newpath, x, y, 0, 0, 0, 4)
      table.insert(flatpaths, newpath)
    end
  end

  local pathstodraw = flatpaths
  if self.optimizepath and #pathstodraw > 2 then
    pathstodraw = contourmap:sort_paths(flatpaths)
  -- else
  --   pathstodraw = flatpaths
  end

  for pathidx=1,#pathstodraw do
    local path = pathstodraw[pathidx]
    for i=1, #path, 5 do
      eos.addpoint(out, path[i], path[i+1], path[i+2], path[i+3], path[i+4])
    end
  end

  -- if no data then output a single blank point at 0,0
  if #out == 0 then
    eos.addpoint(out, 0, 0, 0, 0, 0)
  end

  self.framecount = self.framecount + 1
  self.time = self.time + self.timestep
  self:outlet(2, "float", { #out / 5})
  self:outlet(1, "list", out)
end


function contourmap:in_2(sel, atoms)
    if     sel == "timestep"  then self.timestep  = atoms[1] * 0.01
    elseif sel == "noisedimx" then self.noisedimx = math.max(1, atoms[1])
    elseif sel == "noisedimy" then self.noisedimy = math.max(1, atoms[1])
    elseif sel == "nlayers" then self.nlayers = math.min(3, math.max(1, atoms[1]))
    elseif sel == "noisescale" then self.noisescale = atoms[1] * 0.01
    elseif sel == "isovalue" then self.isovalue = atoms[1]
    elseif sel == "hue" then self.basehue = atoms[1]
    elseif sel == "optimizepath" then self.optimizepath = (atoms[1] ~= 0)
    end
end

