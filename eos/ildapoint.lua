IldaPoint = {}
IldaPoint.__index = IldaPoint

function IldaPoint:new(x, y, z, colorIdx, rgb, blank, last)
    local self = setmetatable({}, IldaPoint)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    self.rgb = {0, 0, 0}
    self.colorIdx = colorIdx or 1
    self.blank = blank or false
    self.last = last or false

    if rgb ~= nil and #rgb == 3 then
        self.rgb = rgb
    else
        if colorIdx ~= nil and colorIdx > 0 and colorIdx <= 64 then
            local rgb = IldaUtil.DEFAULT_PALETTE[colorIdx]
            if rgb[1] ~= nil and rgb[2] ~= nil and rgb[3] ~= nil then
                self.rgb[1] = rgb[1] / 255.0
                self.rgb[2] = rgb[2] / 255.0
                self.rgb[3] = rgb[3] / 255.0
            else
                self.rgb = {1, 1, 1}
            end
        end
    end

    return self
end

function IldaPoint:toString()
    return string.format("[%.2f %.2f %.2f] [b: %s, l: %s] [ci: %d, rgb: %s]",
                         self.x, self.y, self.z,
                         tostring(self.blank), tostring(self.last),
                         self.colorIdx, IldaUtil.RGBToHexString(self.rgb))
end

return IldaPoint
