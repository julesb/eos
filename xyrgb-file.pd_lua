local XF = pd.Class:new():register("xyrgb-file")

function XF:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.currentframeidx = 1
    self.frames = {}
    self.filename = nil
    if type(atoms[1]) == "string" then
        local tmpname = XF:resolvefilename(atoms[1])
        if XF:fileexists(tmpname) then
            self.filename = tmpname
            pd.post(string.format("OK: %s", self.filename))
        else
            pd.post(string.format("Not found: %s", tmpname))
        end
    end
    return true
end


function XF:in_1_bang()
    local currentframe = self.frames[self.currentframeidx]
    --pd.post(string.format("frame idx: %d, numpoints: %d",
    --                        self.currentframeidx, #currentframe))
    --local npoints = #currentframe / 5
    out  = {}
    for i=1,#currentframe do
        out[i] = currentframe[i]
    end
    self:outlet(2, "float", { #out / 5 })
    self:outlet(1, "list", out)
    self.currentframeidx = self.currentframeidx + 1
    if self.currentframeidx > #self.frames then
        self.currentframeidx = 1
    end
end

function XF:postinitialize()
    if self.filename == nil then return end
    local lines = XF:loadxyrgb(self.filename)
    for k,v in pairs(lines) do
        print(string.format("line[%d] %s, %d", k, type(v[1]), #v))
    end
    self.frames = lines
    pd.post(string.format("NUM LINES: %d", #lines))
end


function XF:resolvefilename(filename)
    local ret = nil
    if  filename:sub(-string.len(".xyrgb")) ~= ".xyrgb" then
        ret = string.format("XYRGB/%s.xyrgb", filename)
    else
        ret = string.format("XYRGB/%s", filename)
    end
    pd.post(string.format("resolved filename: %s", ret))
    return ret
end

function XF:loadxyrgb(filename)
    if not XF:fileexists(filename) then
        self:error(string.format("File not found: %s", filename))
        return {}
    end
    local file = io.open(filename, "rb")
    local lines = {}
    for line in io.lines(filename) do
        local words = {}
        local lidx = 0
        -- pd.post(string.format("LINE: %s", line))
        for word in line:gmatch("-*%w+") do
            local coord
            -- pd.post(string.format("WORD: %s", word))

            if lidx % 5 < 2 then
                coord = tonumber(word) / 2047.0
            else
                coord = tonumber(word) / 255.0
            end
            -- pd.post(string.format("COORD: %f", coord))
            table.insert(words, coord)
            lidx = lidx + 1
        end
        table.insert(lines, words)
    end
    file:close()
    return lines
end

function XF:fileexists(filename)
    local f = io.open(filename, "rb")
    if f then f:close() end
    return f ~= nil
end
