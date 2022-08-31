local triggers = pd.Class:new():register("triggers")

function triggers:initialize(sel, atoms)
    self.inlets = 1
    self.outlets = 2
    self.maxtriggers = 10
    self.time = 0.0
    self.ptime = 0.0
    if type(atoms[1]) == "number" then
        self.fps = atoms[1]
    end
    return true
end

function triggers:in_1_float(time)
    tp = require("triggerpool")
    local dt = time - self.ptime
    self.ptime = time
    if dt > 0.5 then dt = 1.0 / 50.0 end
    out = {}
    for i = 1, #tp.triggers do
        local trigger = tp.triggers[i]
        if trigger ~= nil then
            if trigger.done then
                table.remove(tp.triggers, i)
            else
                local points = trigger.update(dt)
                for p=1, #points do
                    table.insert(out, points[p])
                end
                trigger.life = trigger.life - dt
                if trigger.life <= 0 then
                    trigger.done = true
                end
            end
        end
    end
    tp.dumptriggers()
    self:outlet(2, "float", { #out / 5 })
    self:outlet(1, "list", out)
end
