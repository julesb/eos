local eos = {}

eos.screenunit = 1.0 / 2047.0

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

function eos.isblank(p)
    return (p.x == 0 and p.y == 0 and p.z == 0)
end

function eos.colorequal(p1, p2)
    return (p1.r == p2.r and p1.g == p2.g and p1.b == p2.b)
end

function eos.positionequal(p1, p2)
    return (p1.x == p2.x and p1.y == p2.y)
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

    for s=0,nsteps-1 do
        local pnew = v2.add(p1, v2.scale(stepvec, s))
        eos.addpoint(arr, pnew.x, pnew.y, r, g, b)
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
        -- u = 0.5 + 0.5 * math.sin((math.pi*t - math.pi/2.0))
        local u = math.pow(t, 1.0 - math.pow(t, acc))
        local pnew = v2.add(p1, v2.scale(tvec, u))
        eos.addpoint(arr, pnew.x, pnew.y, r, g, b)
    end
end

return eos
