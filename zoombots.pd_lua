local zoombots = pd.Class:new():register("zoombots")
local socket = require("socket")
--local zb = require("zbots")


function zoombots:initialize(sel, atoms)
    self.zb = require("zbots")
    self.inlets = 1
    self.outlets = 2
    self.framerate = 30
    --self.xout = {}
    --self.yout = {}
    self.zb.init(16)
    return true
end

function zoombots:in_1_bang()
    local t_prev = t or 0.0
    local t = socket.gettime()
    local dt = t - t_prev
    if dt > 1.0 then dt = 1.0 / self.framerate end
    self.zb.update(dt)
    local bots = self.zb.bots
    --bots[#bots+1] = bots[1] -- connect last to first
    local xyrgb = zoombots:to_xyrgb(bots)
    --local botsrendered = zoombots:render(bots, 32, 32)
    self:outlet(2, "list", { #xyrgb / 5 })
    self:outlet(1, "list", xyrgb)
end

function zoombots:in_1_numbots(n)
    if n[1] > 0 then
        self.zb.init(n[1])
    end
end

function zoombots:to_xyrgb(bots)
    local out = {}
    local idx = 1
    local v2 = require("vec2")
    local r, g, b
    for i=1,#bots do
--        if i == 1 then
--            g = 1
--            b = 0
--        else
--            g = 0
--            b = 1
--        end
        r = 0
        g = 0 -- i % 2
        b = 1 -- (i + 1) % 2
        out[idx] = bots[i].pos.x -- * 2047
        idx = idx + 1
        out[idx] = bots[i].pos.y -- * 2047
        idx = idx + 1
        out[idx] = r 
        idx = idx + 1
        out[idx] = g 
        idx = idx + 1
        out[idx] = b
        idx = idx + 1
    end
    return out
end
