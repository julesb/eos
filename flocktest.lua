local flock = require("flock")


size = 21
cohesion = 0.1
separation = 0.2
alignment = 0.2
wander = 0.2
wanderfreq = 0.1
wandermag = 0.1
walldetect = 0.1
wallavoid = 0.2
centerattract = 1.0
visualrange = 0.2
mindistance = 0.1
maxforce = 1.0
maxspeed = 0.5
flock = require("flock")
flock.init(
    size,
    cohesion,
    separation,
    alignment,
    wander,
    wanderfreq,
    walldetect,
    wallavoid,
    visualrange,
    mindistance,
    maxforce,
    maxspeed
    )
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
