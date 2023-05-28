IldaFrame = {}
IldaFrame.__index = IldaFrame

IldaHeader = require("ildaheader")
IldaPoint = require("ildapoint")

function IldaFrame:new(frameOffset, bytes)
    local self = setmetatable({}, IldaFrame)
    self.points = {}
    self:parse(frameOffset, bytes)
    return self
end

function IldaFrame:parse(frameOffset, bytes)
    local headerBytes = string.sub(bytes, frameOffset + 1, frameOffset + 32)
    local header = IldaHeader:new(headerBytes)
    if header ~= nil then
        self.header = header
    else
        print("ERROR couldnt read header")
        return
    end
    local recsize = self.header:getFormatRecordSize()
    local reccount = self.header.numRecords
    local datalen = recsize * reccount
    self.byteCount = reccount == 0 and 32 or 32 + datalen
    local dataStartIdx = frameOffset + 32

    local i = dataStartIdx
    while (i < dataStartIdx + datalen) do
        local endOff = i + recsize
        if endOff >= #bytes then
            print("out of range")
            break
        end

        local recBytes = string.sub(bytes, i + 1, i + recsize)
        local x, y, z, status, st_blank, st_last, colIdx, rgb, p
        local formatCode = self.header.formatCode
        if formatCode == IldaHeader.ILDA_3D_INDEXED or formatCode == IldaHeader.ILDA_2D_INDEXED then
            x = IldaUtil.bytesToShort({string.byte(recBytes, 1, 2)})
            y = IldaUtil.bytesToShort({string.byte(recBytes, 3, 4)})
            z = (formatCode == IldaHeader.ILDA_3D_INDEXED) and IldaUtil.bytesToShort({string.byte(recBytes, 5, 6)}) or 0
            x = x / 32767.0
            y = y / 32767.0
            z = z / 32767.0
            status = string.byte(recBytes, formatCode == IldaHeader.ILDA_3D_INDEXED and 7 or 5)
            colIdx = 1 + string.byte(recBytes, formatCode == IldaHeader.ILDA_3D_INDEXED and 8 or 6)
            st_last = (status & (1 << 7)) >> 7
            st_blank = (status & (1 << 6)) >> 6
            rgb = nil
            p = IldaPoint:new(x, y, z, colIdx, rgb, st_blank == 1, st_last == 1)
            table.insert(self.points, p)
        elseif formatCode == IldaHeader.ILDA_COLOR_PALETTE then
            print("NOT IMPLEMENTED: ILDA_COLOR_PALETTE")
        elseif formatCode == IldaHeader.ILDA_3D_RGB or formatCode == IldaHeader.ILDA_2D_RGB then
            x = IldaUtil.bytesToShort({string.byte(recBytes, 0, 2)})
            y = IldaUtil.bytesToShort({string.byte(recBytes, 3, 4)})
            z = formatCode == IldaHeader.ILDA_3D_RGB and IldaUtil.bytesToShort({string.byte(recBytes, 5, 6)}) or 0
            x = x / 32767.0
            y = y / 32767.0
            z = z / 32767.0

            status = string.byte(recBytes, formatCode == IldaHeader.ILDA_3D_RGB and 7 or 5)
            st_last = (status & (1 << 7)) >> 7
            st_blank = (status & (1 << 6)) >> 6
            local b = (string.byte(recBytes, formatCode == IldaHeader.ILDA_3D_RGB and 8 or 6) & 0xff) / 255.0
            local g = (string.byte(recBytes, formatCode == IldaHeader.ILDA_3D_RGB and 9 or 7) & 0xff) / 255.0
            local r = (string.byte(recBytes, formatCode == IldaHeader.ILDA_3D_RGB and 10 or 8) & 0xff) / 255.0
            rgb = {r, g, b}
            colIdx = -1
            p = IldaPoint:new(x, y, z, colIdx, rgb, st_blank == 1, st_last == 1)
            table.insert(self.points, p)
        end
        i = i + recsize
    end
    self.pointCount = #self.points
end

function IldaFrame:getXYRGB()
    local xyrgb = {}
    for _, point in ipairs(self.points) do
        table.insert(xyrgb, point.x)
        table.insert(xyrgb, point.y)
        table.insert(xyrgb, point.rgb[1])
        table.insert(xyrgb, point.rgb[2])
        table.insert(xyrgb, point.rgb[3])
    end
    return xyrgb
end

function IldaFrame:toString()
    return "frame " .. (self.header.frameNumber + 1) .. "/" .. self.header.totalFrames ..
    ": " .. self.header:getFormatString() .. " " ..
    self.header.numRecords .. " points " ..
    "[" .. self.header.name .. "|" .. self.header.companyName .. "]"
end

return IldaFrame
