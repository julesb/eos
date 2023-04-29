socket = require("socket")

function sleep(sec)
    socket.select(nil, nil, sec)
end


function getmemusage()
    return string.format("used: %dMB", collectgarbage("count") / 1024)
end

function dotest()

    local IldaFile = require("ildafile")
    
    print(getmemusage())

    local file = IldaFile:new("unloadable/Moondance.ILD", "SPOOKY")
    print("LOADED FILE: ", file:toString())
    print(getmemusage())


--     print("\t\tDUMP FILE")
--     print(file:toString())
--     for fidx, frame in ipairs(file.frames) do
--         print("\t", frame:toString())
--         --for pidx, point in ipairs(frame.points) do
--         --    print("\t\t", point:toString())
--         --  end
--     end

    print("sleeping...")
    sleep(10)

    print("releasing file")
--     for _, frame in ipairs(file.frames) do
--         for _, _ in ipairs(frame.points) do
--             frame.points[_] = nil
--         end
--         frame.points = nil
--         file.frames[_] = nil
--     end
--     file.frames = nil
    file = nil
    collectgarbage("collect")
    print("done")
    print(getmemusage())

end

dotest()

while true do
    print("sleeping...")
    sleep(5)
    print(getmemusage())
end

