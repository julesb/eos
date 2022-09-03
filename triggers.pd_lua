local triggers = pd.Class:new():register("triggers")

function triggers:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.maxtriggers = 10
    self.time = 0.0
    self.ptime = 0.0
    if type(atoms[1]) == "number" then
        self.fps = atoms[1]
    end
    return true
end

function triggers:in_2_bang()
    tp = require("triggerpool")
    tp.triggers = {}
end

function triggers:in_1_float(time)
    tp = require("triggerpool")
    eos = require("eos")
    local paths = {}
    local out = {}
    local dt = time - self.ptime
    local points
    self.ptime = time
    if dt > 0.5 then dt = 1.0 / 50.0 end
    for i = 1, #tp.triggers do
        local trigger = tp.triggers[i]
        if trigger ~= nil then
            if trigger.done then
                table.remove(tp.triggers, i)
            else
                points = trigger.update(trigger)
                if points ~= nil and #points > 0 then
                    table.insert(paths, points)
                end
                trigger.life = trigger.life - dt
                if trigger.life <= 0 then
                    trigger.done = true
                end
            end
        end
    end
    -- tp.dumptriggers()
    out = eos.composite(paths, 64, 10)
    if out ~= nil and #out >= 5 then
        self:outlet(2, "float", { #out / 5 })
        self:outlet(1, "list", out)
    else
        self:outlet(2, "float", { 0 })
    end
end
