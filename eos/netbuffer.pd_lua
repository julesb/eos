local netbuffer = pd.Class:new():register("netbuffer")

function netbuffer:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2

  -- Default buffer size
  self.max_size = 64

  -- Parse optional buffer size argument
  if type(atoms[1]) == "number" and atoms[1] > 0 then
    self.max_size = math.floor(atoms[1])
  end

  -- Initialize circular buffer
  self.buffer = {}
  self.head = 1  -- Points to next write position
  self.tail = 1  -- Points to next read position
  self.count = 0 -- Number of frames in buffer

  return true
end

function netbuffer:in_1_bang()
  -- Output next frame if available
  if self.count > 0 then
    local frame = self.buffer[self.tail]
    if frame then
      -- Output the frame
      self:outlet(1, "list", frame)

      -- Advance tail and update count
      self.tail = (self.tail % self.max_size) + 1
      self.count = self.count - 1
    end
  end

  -- Always output current buffer count
  self:outlet(2, "float", {self.count})
end

function netbuffer:in_2_list(inp)
  -- Validate input (should have x,y,r,g,b tuples)
  if #inp % 5 ~= 0 then
    self:error("netbuffer: Invalid frame format. Expected [x y r g b ...] tuples")
    return
  end

  -- If buffer is full, overwrite oldest frame
  if self.count >= self.max_size then
    -- Move tail forward (drop oldest frame)
    self.tail = (self.tail % self.max_size) + 1
    self.count = self.count - 1
  end

  -- Store the new frame
  self.buffer[self.head] = inp

  -- Advance head and update count
  self.head = (self.head % self.max_size) + 1
  self.count = self.count + 1

  -- Output updated count
  self:outlet(2, "float", {self.count})
end

-- Optional: Add a method to clear the buffer
function netbuffer:in_1_clear()
  self.buffer = {}
  self.head = 1
  self.tail = 1
  self.count = 0
  self:outlet(2, "float", {0})
end

-- Optional: Add a method to query buffer status
function netbuffer:in_1_status()
  self:outlet(2, "float", {self.count})
end
