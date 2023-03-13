local flock = require("flock")

local coh = 0.5
local sep = 0.5
local ali = 0.5
local wallavoid = 0.5
local size = 10
local range = 0.5
local maxspeed = 0.1
local maxforce = 0.3

flock.init(size, coh, sep, ali, wallavoid, range, maxforce, maxspeed)

print("Agents:")
for i = 1,size do
    print(flock.agenttostring(flock.agents[i]))
end

while true do
    flock.update(0.1)
    print("")
    for i = 1,size do
        print(flock.agenttostring(flock.agents[i]))
    end
end
