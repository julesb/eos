local triggerpool = {}

triggerpool.triggers = {}

function triggerpool.add(_name, _updatefunc, _lifespan)
    local _id = #triggerpool.triggers + 1
    local newtrigger = {
        id = _id,
        name = _name,
        update = _updatefunc,
        life = _lifespan,
        done = false
    }

    table.insert(triggerpool.triggers, newtrigger)
end

function triggerpool.tostring(idx)
    local t = triggerpool.triggers[idx]
    if t ~= nil then
        return string.format("triggers[%d]: name=%s, id=%d, life=%.4f", idx, t.name, t.id, t.life)
    else
        return string.format("trigger[%d]: nil", idx)
    end
end

function triggerpool.dumptriggers()
    local ntriggers = 0
    if triggerpool.triggers ~= nil then ntriggers = #triggerpool.triggers end
    print(string.format("TRIGGER POOL: %d", ntriggers))
    if triggerpool.triggers ~= nil then
        for i = 1, #triggerpool.triggers do
            print(triggerpool.tostring(i))
        end
    end
end


return triggerpool
