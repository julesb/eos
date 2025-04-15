-- ca.pd_lua
-- PureData external for 1D cellular automaton using pd-lua
-- Uses the cellular_automaton.lua library

local ca = pd.Class:new():register("ca")

function ca:initialize(sel, atoms)
    -- Set up inlets and outlets
    self.inlets = 4    -- bang, bufsize, rule, cycle
    self.outlets = 2  -- cell state output

    self.screenunit = 1.0 / 2047.0
    -- Load the CA module
    self.CA = require("cellular_automaton")

    -- Parse creation arguments
    local bufsize = 80   -- Default size
    local rule = 30      -- Default rule (rule 30)
    local seeds = 1      -- Default seed count
    local cycle = true   -- Default cycling behavior

    if type(atoms[1]) == "number" then
        bufsize = math.floor(atoms[1])
    end

    if type(atoms[2]) == "number" then
        rule = math.floor(atoms[2])
    end

    if type(atoms[3]) == "number" then
        cycle = (atoms[3] ~= 0)
    end

    -- Initialize the CA module
    self.CA.init(bufsize, rule, seeds)
    self.CA.set_cycle_rules(cycle)

    return true
end

-- Inlet 1: Bang to update and output
function ca:in_1_bang()
    local eos = require("eos")
    -- Update the CA
    self.CA.update()

    -- Get the current state
    local cells = self.CA.get_cells()

    -- Convert to floats for PD output
    local out = {}
    eos.addblank(out, {x=-1, y=0})
    for i = 1, #cells do
      local posx = ((i-1) / (#cells-1)) * 2.0 - 1
      if cells[i] == 1 and i == 1 or cells[i-1] == 0 then
        -- start segment
        eos.addblank(out, {x=posx-0.0001, y=0})
        eos.addpoint(out, posx, 0, 1, 1, 1)
      end
      if cells[i] == 1 and i == #cells or cells[i+1] == 0 then
        -- end segment
        eos.addpoint(out, posx+0.0001, 0, 1, 1, 1)
        eos.addblank(out, {x=posx, y=0})
      end
    end
    print(self.CA.render())
    -- Output the list
    self:outlet(2, "float", {#out / 5})
    self:outlet(1, "list", out)
end

-- Inlet 2: Set buffer size
function ca:in_2_float(size)
    if type(size) == "number" then
        local new_size = math.floor(size)
        if new_size > 0 then
            self.CA.resize(new_size)
        end
    end
end

-- Inlet 3: Set rule number
function ca:in_3_float(rule)
    if type(rule) == "number" then
        self.CA.set_rule(math.floor(rule) % 256)
    end
end

-- Inlet 4: Toggle rule cycling (0 = off, non-zero = on)
function ca:in_4_float(cycle)
    if type(cycle) == "number" then
        self.CA.set_cycle_rules(cycle ~= 0)
    end
end
