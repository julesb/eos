-- ca_demo.lua
-- Example usage of the cellular automaton library

local CA = require("ca")

-- Initialize with similar parameters to your original code
CA.init(79, 30, 1)

-- Main loop
local function main()
  while true do
    -- Update the CA
    CA.update()

    -- Print the current state
    print(CA.render())

    -- Sleep for a short time (similar to usleep in C)
    os.execute("sleep 0.02")
  end
end

main()
