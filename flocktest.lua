local flock = require("flock")

config = {
    size = 3,
    cohesion = 2.3,
    separation = 3.2,
    alignment = 1.5,
    wander = 24.0,
    wanderfreq = 1.5,
    wandermag = 6.0,
    walldetect = 0.2,
    wallavoid = 0.5,
    visualrange = 0.3,
    agentfov = 90.0,
    mindistance = 0.03,
    maxforce = 1.6,
    maxspeed = 0.4
}

flock = require("flock")
flock.init(config)

print("Agents:")
for i = 1, config.size do
    print(flock.agenttostring(flock.agents[i]))
end

while true do
    flock.update(0.1)
    print("")
    for i = 1,config.size do
        print(flock.agenttostring(flock.agents[i]))
    end
end
