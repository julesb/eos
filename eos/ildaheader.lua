IldaHeader = {}
IldaHeader.__index = IldaHeader

local IldaUtil = require("ildautil")

IldaHeader.ILDA_3D_INDEXED = 0
IldaHeader.ILDA_2D_INDEXED = 1
IldaHeader.ILDA_COLOR_PALETTE = 2
IldaHeader.ILDA_3D_RGB = 4
IldaHeader.ILDA_2D_RGB = 5

function IldaHeader:new(headerBytes)
    local self = setmetatable({}, IldaHeader)
    
    local id = string.sub(headerBytes, 1, 4)
    if id ~= "ILDA" then
        print("ERROR: Invalid file identifier: '" .. id .. "'")
        return
    end

    self.identifier = id
    self.formatCode = string.byte(headerBytes, 8)
    self.name = string.sub(headerBytes, 9, 16):gsub("%s*$", "")
    self.companyName = string.sub(headerBytes, 17, 24):gsub("%s*$", "")
    self.numRecords = IldaUtil.bytesToShort({string.byte(headerBytes, 25, 26)})
    self.frameNumber = IldaUtil.bytesToShort({string.byte(headerBytes, 27, 28)})
    self.totalFrames = IldaUtil.bytesToShort({string.byte(headerBytes, 29, 30)})
    return self
end

function IldaHeader:getFormatString()
    local formatCode = self.formatCode
    if formatCode == IldaHeader.ILDA_3D_INDEXED then
        return "ILDA_3D_INDEXED"
    elseif formatCode == IldaHeader.ILDA_2D_INDEXED then
        return "ILDA_2D_INDEXED"
    elseif formatCode == IldaHeader.ILDA_COLOR_PALETTE then
        return "ILDA_COLOR_PALETTE"
    elseif formatCode == IldaHeader.ILDA_3D_RGB then
        return "ILDA_3D_RGB"
    elseif formatCode == IldaHeader.ILDA_2D_RGB then
        return "ILDA_2D_RGB"
    else
        return "UNDEFINED FORMAT: " .. formatCode
    end
end

function IldaHeader:getFormatName()
    local formatCode = self.formatCode
    if formatCode == IldaHeader.ILDA_3D_INDEXED then
        return "3DIDX"
    elseif formatCode == IldaHeader.ILDA_2D_INDEXED then
        return "2DIDX"
    elseif formatCode == IldaHeader.ILDA_COLOR_PALETTE then
        return "PALETTE"
    elseif formatCode == IldaHeader.ILDA_3D_RGB then
        return "3DRGB"
    elseif formatCode == IldaHeader.ILDA_2D_RGB then
        return "2DRGB"
    else
        return "UNDEFINED FORMAT: " .. formatCode
    end
end

function IldaHeader:getFormatRecordSize()
    local formatCode = self.formatCode
    if formatCode == IldaHeader.ILDA_3D_INDEXED then
        return 8
    elseif formatCode == IldaHeader.ILDA_2D_INDEXED then
        return 6
    elseif formatCode == IldaHeader.ILDA_COLOR_PALETTE then
        return 3
    elseif formatCode == IldaHeader.ILDA_3D_RGB then
        return 10
    elseif formatCode == IldaHeader.ILDA_2D_RGB then
        return 8
    else
        return -1
    end
end

return IldaHeader
