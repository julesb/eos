local adaptive_metro = pd.Class:new():register("adaptive_metro")

function adaptive_metro:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2

  -- Base frame rate (ms between bangs)
  self.base_rate = atoms[1] or (1000 / 60)  -- 30fps default
  self.target_fill = atoms[2] or 0.5  -- Target 50% full
  self.gain = atoms[3] or 0.2  -- Adjustment gain

  -- Current state
  self.current_rate = self.base_rate
  self.clock = pd.Clock:new():register(self, "tick")
  self.running = false

  return true
end

function adaptive_metro:in_1_bang()
  -- Start/restart the adaptive metro
  self.running = true
  self.clock:delay(self.current_rate)
end

function adaptive_metro:in_1_stop()
  -- Stop the metro
  self.running = false
  self.clock:unset()
end

function adaptive_metro:in_2_float(buffer_count)
  -- Adjust rate based on buffer fill level
  local buffer_size = 64  -- Should match your netbuffer size
  local fill_ratio = buffer_count / buffer_size

  -- Calculate error from target fill level
  local error = fill_ratio - self.target_fill

  -- Apply proportional control
  local adjustment = error * self.gain * self.base_rate

  -- Update rate with limits
  self.current_rate = math.max(10, math.min(100, self.base_rate - adjustment))
end

function adaptive_metro:tick()
  if self.running then
    -- Output bang
    self:outlet(2, "float", {self.current_rate})
    self:outlet(1, "bang", {})

    -- Schedule next tick
    self.clock:delay(self.current_rate)
  end
end


function adaptive_metro:finalize()
    -- CRITICAL: Always unset any clocks in finalize!
    if self.clock then
        self.clock:unset()
    end
end
