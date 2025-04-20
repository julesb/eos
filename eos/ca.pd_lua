-- ca.pd_lua
-- PureData external for 1D cellular automaton using pd-lua
-- Uses the cellular_automaton.lua library

local ca = pd.Class:new():register("ca")

function ca:initialize(sel, atoms)
  -- Set up inlets and outlets
  self.inlets = 2    -- bang, bufsize, rule, cycle
  self.outlets = 3  -- cell state output

  self.screenunit = 1.0 / 2047.0
  -- Load the CA module
  self.CA = require("cellular_automaton")

  self.dwellcolor = {r=1, g=0.5, b=0}
  self.pathcolor = {r=0, g=0, b=1}
  self.dwellnum = 4
  self.rendermode = 1 -- 0 = Basic, 1 = NB Colors, 2 = Bidirectional 
  self.printcells = true

  self.scandir = 1


  -- self.osimplex = require("opensimplex2s")
  -- self.S = self.osimplex.new()
  self.noise_amp = 100
  self.noise_freq = 1.9
  self.noiseoffset = false
  -- self.cellwidth = 2 / self.CA.get_size()

  self.cellcolors = {
    {r=0.1, g=0.06, b=0.1},
    {r=1, g=0, b=0},
    {r=0, g=1, b=0},
    {r=0, g=0, b=1}
  }

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

function ca:get_cell_color(cellidx, cells)
  local eos = require("eos")
  local n = cells[eos.wrapidx(cellidx-1, #cells)]
  + cells[eos.wrapidx(cellidx, #cells)]
  + cells[eos.wrapidx(cellidx+1, #cells)]
  return self.cellcolors[n+1]
end

function ca:get_nbcounts_noise()
  local eos = require("eos")
  local simplex = require("simplex")
  local nbcounts = self.CA.get_nbcounts()
  local result = {}
  local noff = simplex.noise3d(
    self.CA.get_iterations()/1000.0 * self.noise_freq,
    123.456, 234.567) * self.noise_amp

  for i = 1,#nbcounts do
    result[i] = nbcounts[eos.wrapidx(math.floor(i+noff), #nbcounts)]
  end
  return result
end


function ca:render_cells1(cells)
  local eos = require("eos")
  local cellwidth = 2.0 / #cells
  local out = {}
  local cellx1, cellx2, point1, point2
  local col, colidx, colidxl, colidxr
  local nbcounts
  if self.noiseoffset then
    nbcounts = self:get_nbcounts_noise()
  else
    nbcounts = self.CA.get_nbcounts()
  end

  -- eos.addblank(out, {x=-1, y=0})
  for i = 1, #cells do
    cellx1 = -1 + ((i-1) / (#cells-1)) * 2.0
    cellx2 = cellx1 + cellwidth
    colidxl = nbcounts[eos.wrapidx(i-1, #cells)]+1
    colidx  = nbcounts[i]+1
    colidxr = nbcounts[eos.wrapidx(i+1, #cells)]+1
    col = self.cellcolors[colidx]
    point1 = eos.newpoint2(cellx1, 0, col)
    point2 = eos.newpoint2(cellx2, 0, col)

    if colidx ~= colidxl or i == 1 then
      -- color span start
      eos.addpoint2(out, point1)
    end

    if colidx ~= colidxr or i == #cells then
      -- color span end
      eos.addpoint2(out, point2, self.dwellnum)
    end

  end
  eos.addblank(out, point2)
  return out
end

-- render neighbour colors bidirectional
function ca:render_cells2(cells)
  local eos = require("eos")
  local cellwidth = 2.0 / #cells
  local out = {}
  local cellx1, cellx2, point1, point2
  local col, colidx, colidxl, colidxr, i
  local nbcounts = self.CA.get_nbcounts()

  -- eos.addblank(out, {x=self.scandir*-1, y=0})
  for i1 = 1, #cells do
    if self.scandir == 1 then
      i = i1
      cellx1 = ((i-1) / (#cells-1)) * 2.0 - 1.0
      cellx2 = cellx1 + cellwidth
    else
      i = #cells - i1 + 1
      cellx1 = ((i-1) / (#cells-1)) * 2.0 - 1.0 + cellwidth
      cellx2 = ((i-1) / (#cells-1)) * 2.0 - 1.0
      -- cellx2 = cellx1 - cellwidth
    end
    colidxl = nbcounts[eos.wrapidx(i-1, #cells)]+1
    colidx  = nbcounts[i]+1
    colidxr = nbcounts[eos.wrapidx(i+1, #cells)]+1
    col = self.cellcolors[colidx]
    point1 = eos.newpoint2(cellx1, 0, col)
    point2 = eos.newpoint2(cellx2, 0, col)

    if self.scandir == 1 then
      if colidx ~= colidxl or i == 1 then
        -- color span start
        eos.addpoint2(out, point1)
      end

      if colidx ~= colidxr or i == #cells then
        -- color span end
        eos.addpoint2(out, point2, self.dwellnum)
      end
    else
      if colidx ~= colidxr or i == #cells then
        -- color span start
        eos.addpoint2(out, point1)
      end

      if colidx ~= colidxl or i == 1 then
        -- color span end
        eos.addpoint2(out, point2, self.dwellnum)
      end

    end
  end
  -- eos.addblank(out, {x=self.scandir, y=0})
  -- eos.addblank(out, point2)
  return out
end

-- render two color basic
function ca:render_cells0(cells)
  local eos = require("eos")
  -- local cellwidth = 2.0 / #cells
  local out = {}
  local posx, point --, i
  -- local col
  -- eos.addblank(out, {x=-1, y=0})
  -- eos.addblank(out, {x=self.scandir * -1, y=0})
  for i = 1, #cells do

    -- if self.scandir == -1 then
    --   i = #cells+1 - i1
    -- else
    --   i = i1
    -- end
    posx = -1 * (((i-1) / (#cells-1)) * 2.0 - 1)
    -- posx = self.scandir * (((i-1) / (#cells-1)) * 2.0 - 1)
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
      -- col = self:get_cell_color(i, cells)

      if (i == 1 or cells[i-1] == 0) then
        -- start segment
        -- dwell
        eos.addblank(out, point, self.dwellnum)

        -- eos.setcolor(point, col)
        eos.setcolor(point, self.dwellcolor)
        eos.addpoint2(out, point, self.dwellnum)

        -- eos.setcolor(point, col)
        eos.setcolor(point, self.pathcolor)
        eos.addpoint2(out, point)
      end
      if i == #cells or cells[i+1] == 0 then
        -- end segment
        -- eos.setcolor(point, col)
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

  eos.addblank(out, {x=1, y=0})
  -- eos.addblank(out, {x=self.scandir, y=0})
  return out
end


function ca:in_1_bang()
  local out
  self.CA.update()
  local cells = self.CA.get_cells()

  if self.rendermode == 2 then
    out = self:render_cells2(cells)
  elseif self.rendermode == 1 then
    out = self:render_cells1(cells)
  else
    out = self:render_cells0(cells)
  end

  self.scandir = self.scandir * -1
  -- print(self.CA.render_nbcounts())
  if self.printcells then
    print(self.CA.render() .. "|")
  end
  self:outlet(3, "float", {#out / 5})
  self:outlet(2, "float", {self.CA.get_rule()})
  self:outlet(1, "list", out)
end



function ca:in_2(sel, atoms)
  if sel == "size" then
    self.CA.resize(math.max(1, math.floor(atoms[1])))
  elseif sel == "rule" then
    self.CA.set_rule(math.floor(atoms[1]) % 256)
  elseif sel == "randrule" then
    self.CA.set_cycle_rules(atoms[1] ~= 0)
  elseif sel == "dwell" then
    self.dwellnum = math.max(0, atoms[1])
  elseif sel == "printcells" then
    self.printcells = (atoms[1] ~= 0)
  elseif sel == "rendermode" then
    self.rendermode = math.min(math.max(0, atoms[1]))
  elseif sel == "initseed" then
    self.CA.init_seed(atoms[1])
  elseif sel == "noiseamp" then
    self.noise_amp = atoms[1]
  elseif sel == "noisefreq" then
    self.noise_freq = atoms[1]
  elseif sel == "noiseoffset" then
    self.noiseoffset = (atoms[1] ~= 0)
  end
end


