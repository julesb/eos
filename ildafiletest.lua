IldaFile = require("ildafile")

file = IldaFile:new("ILDA/BEAM8.ild", "BEAM8")

print("LOADED FILE: ", file:toString())


print("\t\tDUMP FILE")
print(file:toString())
for fidx, frame in ipairs(file.frames) do
    print("\t", frame:toString())
    for pidx, point in ipairs(frame.points) do
        print("\t\t", point:toString())
    end
end
