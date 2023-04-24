local IF = pd.Class:new():register("ilda-file")
local IldaFile = require("ildafile")

function IF:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.file = nil
    self.currentframeidx = 1
    self.frames = {}
    self.filename = nil 
    if type(atoms[1]) == "string" then
        local tmpname = string.format("ILDA/%s", atoms[1])
        if IF:fileexists(tmpname) then
            self.filename = tmpname
            pd.post(string.format("OK: %s", self.filename))
        else
            pd.post(string.format("Not found: %s", tmpname))
        end
    end
    return true
end

function IF:postinitialize()
    if self.filename == nil then return end
    self.file = IldaFile:new(self.filename, "THEFILE")
    self.frames = self.file.frames
end


function IF:in_1_bang()
    local currentframe = self.frames[self.currentframeidx]
    local out = currentframe:getXYRGB()
    self:outlet(2, "float", { #out / 5 })
    self:outlet(1, "list", out)
    self.currentframeidx = self.currentframeidx + 1
    if self.currentframeidx > #self.frames then
        self.currentframeidx = 1
    end
end

function IF:in_2(sel, atoms)
    if sel == "load" then
        if type(atoms[1]) == "string" then
            local tmpname = string.format("ILDA/%s", atoms[1])
            print("filename: ", tmpname)
            if IF:fileexists(tmpname) then
                self.filename = tmpname
                pd.post(string.format("OK found: %s", self.filename))
            else
                pd.post(string.format("Not found: %s", tmpname))
                return
            end
        end
       
        local file = IldaFile:new(self.filename, "THEFILE")
        if file ~= nil then
            self.file = file
            self.currentframeidx = 1
            self.frames = self.file.frames
            print("LOADED ", self.filename)
        else
            print("LOAD FAILED: ", self.filename)
        end
    elseif sel == "dump" then
        self:dumpfile()
    end
end

function IF:dumpfile()
    if self.file == nil then return end
    print(self.file:toString())
    for fidx, frame in ipairs(self.file.frames) do
        print("\t", frame:toString())
        for pidx, point in ipairs(frame.points) do
            print("\t\t", point:toString())
        end
    end
end

function IF:resolvefilename(filename)
    local ret = nil
    if  filename:sub(-string.len(".xyrgb")) ~= ".xyrgb" then
        ret = string.format("XYRGB/%s.xyrgb", filename)
    else
        ret = string.format("XYRGB/%s", filename)
    end
    pd.post(string.format("resolved filename: %s", ret))
    return ret
end

function IF:fileexists(filename)
    local f = io.open(filename, "rb")
    if f then f:close() end
    return f ~= nil
end
