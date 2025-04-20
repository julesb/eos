-- cellular_automaton.lua
-- A Lua implementation of a 1D cellular automaton based on Wolfram's elementary rules

local CA = {}
local cells = {{}, {}}  -- Two buffers for the current and next state
local rule_number = 30
local bufsize = 64
local iterations = 0
local cycle_rules = true
local cycle_interval_frames = 64
local current = 1       -- Index for the current buffer (1 or 2)
local next_buf = 2      -- Index for the next buffer (2 or 1)



-- Seed random cells with life
local function seed_cells(numSeeds)
  math.randomseed(os.time())  -- Initialize random seed
  for i = 1, numSeeds do
    cells[current][math.random(bufsize)] = 1
  end
end

function CA.init_cells()
  cells[1] = {}
  cells[2] = {}

  for i = 1, bufsize do
    cells[1][i] = 0
    cells[2][i] = 0
  end

end

-- Clear and seed
function CA.init_seed(numseeds)
  CA.init_cells()
  seed_cells(numseeds)
end


-- Initialize the CA with size, rule, and number of seed cells
function CA.init(size, rule, numseeds)
  cycle_rules = true
  bufsize = (size > 0) and size or 1
  rule_number = rule

  -- Initialize cell buffers
  CA.init_cells()
  -- cells[1] = {}
  -- cells[2] = {}
  --
  -- for i = 1, bufsize do
  --   cells[1][i] = 0
  --   cells[2][i] = 0
  -- end

  iterations = 0
  current = 1
  next_buf = 2

  -- Seed initial cells
  seed_cells(numseeds or 1)

  return CA  -- Return the CA object for chaining
end



-- Resize the CA grid, preserving existing state where possible
function CA.resize(new_size)
  if new_size == bufsize then return CA end  -- No change needed

  local old_size = bufsize
  bufsize = new_size

  local new_cells = {{}, {}}

  -- Copy existing cells (as many as fit)
  for i = 1, math.min(old_size, new_size) do
    new_cells[1][i] = cells[1][i]
    new_cells[2][i] = cells[2][i]
  end

  -- Initialize any additional cells to 0
  for i = old_size + 1, new_size do
    new_cells[1][i] = 0
    new_cells[2][i] = 0
  end

  cells = new_cells
  return CA  -- Return the CA object for chaining
end

-- Get the neighborhood code for a cell at the given index
local function get_nb_code(idx)
  local val = 0

  if idx > 1 and idx < bufsize then
    -- Normal case
    val = val + (cells[current][idx - 1] * 4)
    val = val + (cells[current][idx] * 2)
    val = val + (cells[current][idx + 1] * 1)
  elseif idx == 1 then
    -- Wrap left
    val = val + (cells[current][bufsize] * 4)
    val = val + (cells[current][idx] * 2)
    val = val + (cells[current][idx + 1] * 1)
  elseif idx == bufsize then
    -- Wrap right
    val = val + (cells[current][idx - 1] * 4)
    val = val + (cells[current][idx] * 2)
    val = val + (cells[current][1] * 1)
  end

  return val
end

-- Swap the current and next buffers
local function swap()
  current, next_buf = next_buf, current
end

-- Count the number of active cells
function CA.count_cells()
  local count = 0
  for i = 1, bufsize do
    if cells[current][i] ~= 0 then
      count = count + 1
    end
  end
  return count
end

-- Get the current state of the cells
-- dir - 1 = normal, -1 = reversed
function CA.get_cells(dir)
  dir = dir or 1
  local result = {}
  if dir == 1 then
    for i = 1, bufsize do
      result[i] = cells[current][i]
    end
  else
    for i = bufsize, 1, -1 do
      result[i] = cells[current][i]
    end
  end
  return result
end

function CA.get_nbcounts()
  local result = {}
  for i = 1, bufsize do
    local left = (i - 2) % bufsize + 1
    local right = i % bufsize + 1
    result[i] = cells[current][left] + cells[current][i] + cells[current][right]
  end
  return result
end

-- Set whether rules should cycle
function CA.set_cycle_rules(should_cycle)
  cycle_rules = should_cycle
  return CA  -- Return the CA object for chaining
end

function CA.set_cycle_interval(nframes)
  cycle_interval_frames = math.max(1, nframes)
  return CA  -- Return the CA object for chaining
end

-- Set the rule number
function CA.set_rule(rule)
  rule_number = rule
  return CA  -- Return the CA object for chaining
end

-- Get the current rule number
function CA.get_rule()
  return rule_number
end

-- Get the buffer size
function CA.get_size()
  return bufsize
end

-- Get the number of iterations
function CA.get_iterations()
  return iterations
end

-- Update the CA for one step
function CA.update()
  -- Apply the rule to each cell
  for i = 1, bufsize do
    local nb_code = get_nb_code(i)
    cells[next_buf][i] = ((rule_number & (1 << nb_code)) == 0) and 0 or 1
  end

  -- Swap buffers
  swap()
  iterations = iterations + 1

  -- Optionally change the rule
  if cycle_rules and iterations % cycle_interval_frames == 0 then
    rule_number = math.random(0, 255)
  end

  -- Check if all cells are the same, and reseed if necessary
  local cell_count = CA.count_cells()
  if cell_count == 0 then
  -- if cell_count == 0 or cell_count == bufsize then
    seed_cells(1)
    rule_number = math.random(0, 255)
  end

  return CA  -- Return the CA object for chaining
end

-- Render the CA state as a string (for display)
function CA.render()
  local result = ""
  for i = 1, bufsize do
    result = result .. (cells[current][i] == 0 and " " or "#")
  end
  return result
end

function CA.render_nbcounts()
  local nbcounts = CA.get_nbcounts()
  local result = ""
  local nc
  for i = 1, bufsize do
    nc = nbcounts[i]
    result = result .. (nc == 0 and " " or tostring(nc))
    -- result = result .. (cells[current][i] == 0 and " " or tostring(nbcounts[i]))
  end
  return result
end

-- Return the CA module
return CA
