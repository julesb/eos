IldaFile = {}
IldaFile.__index = IldaFile

IldaFrame = require("ildaframe")

function IldaFile:new(filename, name)
    local self = setmetatable({}, IldaFile)
    self.filename = filename
    self.name = name
    self.bytes = self:loadFile()
    self.frames = {}
    self.frameCount = 0
    self.totalPoints = 0
    self.droppedFrameCount = 0

    local frameOffset = 0
    local frame
    repeat
        frame = IldaFrame:new(frameOffset, self.bytes)
        --print("FRAME ", frame:toString())
        if frame.header.numRecords == 0 then
            break
        else
            table.insert(self.frames, frame)
            self.totalPoints = self.totalPoints + frame.pointCount
            frameOffset = frameOffset + frame.byteCount
        end
    until frame.header.numRecords <= 0 or frameOffset >= #self.bytes

    if frame.header.numRecords ~= 0 then
        print(self.name .. ": NO EOF HEADER")
        table.remove(self.frames, #self.frames)
    end

    self.frameCount = #self.frames
    return self
end

function IldaFile:loadFile()
    local file, err = io.open(self.filename, "rb")
    if not file then
        error("Error loading file: " .. err)
    end

    local bytes = file:read("*a")
    file:close()
    return bytes
end

function IldaFile:toString()
    return self.name .. ": frames:" .. self.frameCount .. ": " ..
        (self.frameCount > 0 and self.frames[1]:toString() or "")
end

return IldaFile
