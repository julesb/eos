local socket = require("socket")

local function sleep(sec)
    socket.select(nil, nil, sec)
end


local function getmemusage()
    return string.format("used: %sMB", collectgarbage("count") / 1024)
end

local function dotest()

    local IldaFile = require("ildafile")

    print(getmemusage())

    local file = IldaFile:new("../ILDA/YOWZA.ild", "ILDATESTA")
    --local file = IldaFile:new("../ILDA/Z3.ILD", "ILDATESTA")
    --local file = IldaFile:new("../ILDA/ildatsta.ild", "ILDATESTA")
    print("LOADED FILE: ", file:toString())

    for fidx, frame in ipairs(file.frames) do
        print(string.format("\tframe[%d/%d]: points: %d", fidx, #file.frames, #frame / 5))
    end


end

dotest()
print("DONE")


