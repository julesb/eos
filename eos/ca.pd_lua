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

    self.dwellcolor = {r=1, g=1, b=1}
    self.pathcolor = {r=0, g=0, b=1}

    self.dwellnum = 4
    self.scandir = -1

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
    local out = {}
    -- eos.addblank(out, {x=-1, y=0})
    local posx, point
    for i = 1, #cells do
      posx = self.scandir * (((i-1) / (#cells-1)) * 2.0 - 1)
      point = {x=posx, y=0, r=0, g=0, b=0}
      if cells[i] == 0 then
        if i > 1 and cells[i-1] == 1 then
          -- start blank
          eos.addblank(out, {x=posx, y=0})
        end

        if i < #cells and cells[i+1] == 1 then
          -- end blank
          eos.addblank(out, {x=posx, y=0})
        end
      else
        if (i == 1 or cells[i-1] == 0) then
          -- start segment
          -- dwell
          eos.addblank(out, point, self.dwellnum)

          eos.setcolor(point, self.dwellcolor)
          eos.addpoint2(out, point, self.dwellnum)

          eos.setcolor(point, self.pathcolor)
          eos.addpoint2(out, point)
        end
        if i == #cells or cells[i+1] == 0 then
          -- end segment
          eos.setcolor(point, self.pathcolor)
          eos.addpoint2(out, point, self.dwellnum)

          eos.setcolor(point, self.dwellcolor)
          eos.addpoint2(out, point, self.dwellnum)

          eos.addblank(out, point)

          -- eos.addpoint(out, posx, 0, 1, 1, 1)
          -- eos.addblank(out, {x=posx, y=0})
        end
      end
    end

    -- self.scandir = self.scandir * -1

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
