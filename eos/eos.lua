local eos = {}

eos.screenunit = 1.0 / 2047.0
eos.colorunit = 1.0 / 255.0

function eos.addpoint(arr, x, y, r, g, b, numpoints)
    if numpoints == nil then numpoints = 1 end
    for i=1,numpoints do
        table.insert(arr, x)
        table.insert(arr, y)
        table.insert(arr, r)
        table.insert(arr, g)
        table.insert(arr, b)
    end
end

function eos.wrapidx(idx, len)
    return ((idx-1) % len) + 1
end


function eos.isblank(p)
    return (p.r == 0 and p.g == 0 and p.b == 0)
end

function eos.colorequal(p1, p2)
    return (p1.r == p2.r and p1.g == p2.g and p1.b == p2.b)
end

function eos.positionequal(p1, p2)
    return (p1.x == p2.x and p1.y == p2.y)
end

function eos.pointsequal(p1, p2)
    return (p1.x == p2.x and p1.y == p2.y and p1.r == p2.r and p1.g == p2.g and p1.b == p2.b)
end

function eos.getdwellnum(pidx, arr)
    local dwellnum = -1
    local p1 = {
        x = arr[pidx  ],
        y = arr[pidx+1],
        r = arr[pidx+2],
        g = arr[pidx+3],
        b = arr[pidx+4]
    }
    local p2idx = eos.wrapidx(pidx+5, #arr)
    repeat
        local p2 = {
            x = arr[p2idx  ],
            y = arr[p2idx+1],
            r = arr[p2idx+2],
            g = arr[p2idx+3],
            b = arr[p2idx+4]
        }
        p2idx = eos.wrapidx(p2idx+5, #arr)
        dwellnum = dwellnum + 1
    until not eos.pointsequal(p1, p2)
    return dwellnum
end


function eos.pointatindex(arr, index)
  local i = 1 + (index-1) * 5
  if i < 1 then return nil end
  if i > #arr-4 then return nil end

  return {
    x = arr[i  ],
    y = arr[i+1],
    r = arr[i+2],
    g = arr[i+3],
    b = arr[i+4]
  }
end


function eos.pointatclampedindex(arr, index)
  return eos.pointatindex(arr, math.max(1, math.min(index, #arr/5)))
end

function eos.getdirections(arr)
  local v2 = require("vec2")
  local dirs = {}
  local p0, p1, p2, p3, i0, i1,i2, i3
  local npoints = #arr / 5
  local prevdir = v2.normalize(v2.sub(eos.pointatindex(arr, 2), eos.pointatindex(arr, 1)))
  for i=1,npoints do
    i0 = math.max(1, i-1)
    i1 = i
    i2 = math.min(i+1, npoints)
    i3 = math.min(i+2, npoints)
    p0 = eos.pointatindex(arr, i0)
    p1 = eos.pointatindex(arr, i1)
    p2 = eos.pointatindex(arr, i2)
    if eos.positionequal(p1, p0) then
      table.insert(dirs, prevdir)
    else
      local dir
      if eos.isblank(p1) and not eos.isblank(p2) then
        p3 = eos.pointatindex(arr, i3)
        dir = v2.normalize(v2.sub(p3, p2))
      else
        dir = v2.normalize(v2.sub(p1, p0))
      end
      table.insert(dirs, dir)
      prevdir = dir
    end
  end
  return dirs
end

function eos.subdivide(arr, p1, p2, mindist, mode)
    local v2 = require("vec2")
    local tvec = v2.sub(p2, p1)
    local len = v2.len(tvec)
    local subdivide_su = mindist * eos.screenunit
    local nsteps = math.ceil(len / subdivide_su)
    local stepvec = v2.scale(tvec, 1.0 / nsteps)
    local r, g, b
    if mode == "points" then
        r = 0
        g = 0
        b = 0
    else
        r = p1.r
        g = p1.g
        b = p1.b
    end

    for s=1,nsteps-1 do
        local pnew = v2.add(p1, v2.scale(stepvec, s))
        eos.addpoint(arr, pnew.x, pnew.y, r, g, b)
    end
end

  -- public float bezierPoint(float a, float b, float c, float d, float t) {
  --   float t1 = 1.0f - t;
  --   return a*t1*t1*t1 + 3*b*t*t1*t1 + 3*c*t*t*t1 + d*t*t*t;
  -- }


function eos.bezierlerp(a, b, c, d, t)
  local t1 = 1.0 - t
  return a * t1*t1*t1 + 3.0 * b * t * t1*t1 + 3.0 * c * t*t * t1 + d * t*t*t
end

function eos.subdivide_bezier(arr, p1, c1, c2, p2, mindist, mode)
  local v2 = require("vec2")
  local tvec = v2.sub(p2, p1)
  local len = v2.len(tvec)
  local subdivide_su = mindist * eos.screenunit
  local nsteps = math.ceil(len / subdivide_su)
  local r, g, b
  if mode == "points" then
    r = 0
    g = 0
    b = 0
  else
    r = p1.r
    g = p1.g
    b = p1.b
  end

  for s=0,nsteps-1 do
    local t = s / nsteps
    local xs = eos.bezierlerp(p1.x, c1.x, c2.x, p2.x, t)
    local ys = eos.bezierlerp(p1.y, c1.y, c2.y, p2.y, t)
    eos.addpoint(arr, xs, ys, r, g, b)
  end
end

function eos.smoothstep(x1, x2, t)
  if t < x1 then return 0.0
  elseif t > x2 then return 1.0
  end
  t = (t-x1) / (x2-x1)
  return t*t*(3.0-2.0*t)
end

function eos.smoothlerp(x1, x2, t)
  t = math.min(math.max(t, 0.0), 1.0);
  t = t*t * (3.0 - 2.0 * t)
  return x1 + (x2-x1) * t
end

function eos.subdivide_smooth(arr, p1, p2, mindist, mode)
    local v2 = require("vec2")
    local tvec = v2.sub(p2, p1)
    local len = v2.len(tvec)
    local subdivide_su = mindist * eos.screenunit
    local nsteps = math.ceil(len / subdivide_su)
    local r, g, b
    if mode == "points" then
        r = 0
        g = 0
        b = 0
    else
        r = p1.r
        g = p1.g
        b = p1.b
    end

    for s=0,nsteps-1 do
        local t = s / nsteps
        local xs = eos.smoothlerp(p1.x, p2.x, t)
        local ys = eos.smoothlerp(p1.y, p2.y, t)
        eos.addpoint(arr, xs, ys, r, g, b)
    end
end


function eos.subdivide_cos(arr, p1, p2, mindist, mode)
    local v2 = require("vec2")
    local tvec = v2.sub(p2, p1)
    local len = v2.len(tvec)
    local subdivide_su = mindist * eos.screenunit
    local nsteps = math.ceil(len / subdivide_su)
    local r, g, b
    if mode == "points" then
        r = 0
        g = 0
        b = 0
    else
        r = p1.r
        g = p1.g
        b = p1.b
    end

    for s=0,nsteps-1 do
        local t = s / nsteps
        local u = 0.5 + 0.5 * math.sin((math.pi*t - math.pi/2.0))
        local pnew = v2.add(p1, v2.scale(tvec, u))
        eos.addpoint(arr, pnew.x, pnew.y, r, g, b)
    end
end

function eos.subdivide_exp(arr, p1, p2, mindist, acc, mode)
    local v2 = require("vec2")
    local tvec = v2.sub(p2, p1)
    local len = v2.len(tvec)
    local subdivide_su = mindist * eos.screenunit
    local nsteps = math.ceil(len / subdivide_su)
    if acc == nil then acc = 1.0 end
    acc = math.max(0.1, math.min(acc, 50))
    local r, g, b
    if mode == "points" then
        r = 0
        g = 0
        b = 0
    else
        r = p1.r
        g = p1.g
        b = p1.b
    end
    for s=0,nsteps-1 do
        local t = s / nsteps
        local u = t ^ (1.0 - t ^ acc)
        local pnew = v2.add(p1, v2.scale(tvec, u))
        eos.addpoint(arr, pnew.x, pnew.y, r, g, b)
    end
end


-- vec3 hsv2rgb(vec3 c)
-- {
--     vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
--     vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
--     return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
-- }

function eos.hsv2rgb(h, s, v)
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



function eos.colorramp(col, minr, maxr, ming, maxg, minb, maxb)
    local function maprange(x, min, max)
        return min + x * (max - min)
    end
    return {
        r = maprange(col.r, minr, maxr),
        g = maprange(col.g, ming, maxg),
        b = maprange(col.b, minb, maxb)
    }
end


function eos.composite(paths, subdivide, preblank, startpos)
    local v2 = require("vec2")
    local npaths = #paths
    local out = {}
    local idx = 1
    if preblank == nil then preblank = 10 end
    if subdivide == nil then subdivide = 32 end

    -- subdivide from prev frame exit to current frame entry points
    if #paths > 0 and #paths[1] >= 5 then
      local p1 = { x=paths[1][1], y=paths[1][2], r=0, g=0, b=0, }
      eos.subdivide_smooth(out, startpos, p1, subdivide)
    end

    for i=1,npaths do
        local path = paths[i]
        local plen = #path
        if plen < 1 then
            break
        end

        local nextpathidx = eos.wrapidx(i+1, npaths)
        local nextpath = paths[nextpathidx]

        -- Preblank
        eos.addpoint(out, path[1], path[2], 0, 0, 0, preblank)

        for j=1,plen do
            table.insert(out, path[j])
        end

        if i < npaths then
          -- p1 = last point in current path
          local p1idx = plen - 4
          local p1 = {
              x=path[p1idx],
              y=path[p1idx+1],
              r=path[p1idx+2],
              g=path[p1idx+3],
              b=path[p1idx+4],
          }
          -- p2 = first point in the next path
          local p2 = {
              x=nextpath[1],
              y=nextpath[2]
          }

          -- post dwell color - so we dont blank too early
          -- eos.addpoint(out, p1.x, p1.y, p1.r, p1.g, p1.b, 12)

          eos.subdivide_smooth(out, p1, p2, subdivide, "lines")
      end
    end
    return out
end

function eos.randompos()
    return {
        x = 2.0 * math.random() - 1.0,
        y = 2.0 * math.random() - 1.0
    }
end

function eos.randomhue()
    return eos.hsv2rgb(math.random(), 1, 1)
end

return eos
