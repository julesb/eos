IldaPoint = {}
IldaPoint.__index = IldaPoint

function IldaPoint:new(x, y, z, colorIdx, _rgb, blank, last)
    local self = setmetatable({}, IldaPoint)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    self.rgb = {0, 0, 0}
    self.colorIdx = colorIdx or 1
    self.blank = blank or false
    self.last = last or false

    if self.blank then
      return self
    end

    if _rgb ~= nil and #_rgb == 3 then
        self.rgb = { _rgb[1], _rgb[2], _rgb[3] }
    else
        if colorIdx ~= nil and colorIdx > 0 and colorIdx <= 64 then
            local pcol = IldaUtil.DEFAULT_PALETTE[colorIdx]
            self.rgb[1] = pcol[1] / 255.0
            self.rgb[2] = pcol[2] / 255.0
            self.rgb[3] = pcol[3] / 255.0
        else
          self.rgb = { 1, 0, 0 }
          print("colorIdx out of range:", colorIdx)
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
