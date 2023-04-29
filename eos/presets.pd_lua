local presets = pd.Class:new():register("presets")

function presets:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 2
    self.currentpresetname = nil
    self.currentpresetidx = -1
    self.currentparams = {}
    self.presetfiles = {}
    self.cwd = io.popen("pwd"):read()
    print("current dir:", self.cwd)
    
    self.presetbasepath = string.format("%s/presets", self.cwd)
    print("preset base path:", self.presetbasepath)

    if type(atoms[1]) == "string" then
        if self:isdir(self.presetbasepath) then
            print("OK: preset base path exists")
        else
            print(string.format("base path %s doesnt exist, creating:", self.presetbasepath))
            io.popen("mkdir " .. self.presetbasepath)
        end

        self.patchname = atoms[1]
        print("patchname:", self.patchname)

        self.presetpath = string.format("%s/%s", self.presetbasepath, self.patchname)
        print("preset path:", self.presetpath)

    end
    return true
end

function presets:postinitialize()
    local presetfiles = self:scanpresets(self.presetpath)
    if #(presetfiles) > 0 then
        self.presetfiles = presetfiles
        for i,f in pairs(self.presetfiles) do
            print("\tpreset: ", f)
        end
        
        self.currentparams = self:loadpresetidx(1)
        self:printparams()
        self:outlet(2, "symbol", {self.currentpresetname})
        self:sendcurrentparams()
    else
        print("NO PRESET FILES LOADED")
    end
end

function presets:in_1(sel, atoms)
    if sel == "load" then
        local filepath = atoms[1]
        print(string.format("load %s", atoms[1]))
        self:loadpreset(filepath)
        self:outlet(2, "symbol", {self.currentpresetname})
        self:sendcurrentparams()
    elseif sel == "save" then
        print(string.format("save %s", atoms[1]))
        if atoms[1] ~= nil then
            local filepath = atoms[1]
            self:savepreset(filepath)
        end
        self:outlet(2, "symbol", {self.currentpresetname})
    elseif sel == "next" then
        print(string.format("next: currentidx=%s", self.currentpresetidx))
        self.currentpresetidx = self.currentpresetidx + 1
        if self.currentpresetidx > #self.presetfiles then
            self.currentpresetidx = 1
        end
        self.currentparams = self:loadpresetidx(self.currentpresetidx)
        print(string.format("loaded new idx=%s, name=%s", self.currentpresetidx, currentpresetname))
        self:outlet(2, "symbol", {self.currentpresetname})
        self:sendcurrentparams()
    elseif sel == "prev" then
        self.currentpresetidx = self.currentpresetidx - 1
        if self.currentpresetidx < 1 then
            self.currentpresetidx = #self.presetfiles
        end
        self.currentpresetname = self.presetfiles[self.currentpresetidx]
        self.currentparams = self:loadpresetidx(self.currentpresetidx)
        self:outlet(2, "symbol", {self.currentpresetname})
        self:sendcurrentparams()
    end
end

function presets:in_2(sel, atoms)
    self.currentparams[sel] = atoms[1]
    print(string.format("UPDATE PARAM [%s]: %s = %s", self.patchname, sel, atoms[1]))
end

function presets:scanpresets(path)
    local presetfiles = self:scandir(path)
    return presetfiles
end

function presets:sendcurrentparams()
    for name, value in pairs(self.currentparams) do
        self:outlet(1, name, {value})
    end
end

function presets:loadpresetidx(idx)
    if idx < 1 or idx > #self.presetfiles then
        print("presets:loadpresetidx(): ERROR: idx out of range:",  idx)
        return false
    end
    self.currentpresetname = self.presetfiles[idx]
    self.currentpresetidx = idx
 
    local presetfilepath = string.format("%s/%s", self.presetpath, self.currentpresetname)
    print("loading preset: ", presetfilepath)
    local presetparams = self:loadparsefile(presetfilepath)
    return presetparams
end

function presets:loadpreset(filepath)
    print("loadpreset: ", filepath)
    local params = self:loadparsefile(filepath)
    self.currentparams = params
    local presetname = self:filenamefrompath(filepath)
    self.currentpresetname = presetname
    self.presetfiles = self:scanpresets(self.presetpath)
    self.currentpresetidx = self:getpresetidx(presetname)
    return presetparams
end

function presets:savepreset(filepath)
    local result = self:savefile(self.currentparams, filepath)

    if result then
        self.currentpresetname = self:filenamefrompath(filepath)
        self.presetfiles = self:scanpresets(self.presetpath)
        self.currentpresetidx = self:getpresetidx(self.currentpresetname)
        print(string.format("SAVED PRESET: %s", self.currentpresetname))
    else
        print("FAILED TO SAVE PRESET")
    end
end


function presets:filenamefrompath(filepath)
    return filepath:match("[^\\/]*$")
end

function presets:getpresetidx(presetname)
    for i,name in pairs(self.presetfiles) do
        if name == presetname then
            return i
        end
    end
    print(string.format("getpresetidx() ERROR: preset %s not found", presetname))
    return -1
end


function presets:loadparsefile(filename)
    local file, err = io.open(filename, "r")
    if not file then
        print("Error opening file: " .. err)
        return nil
    end
    local params = {}
    for line in file:lines() do
        local key, value = line:match("^(%w+):%s*(.+)$")
        if key and value then
            local numberValue = tonumber(value)
            if numberValue then
                params[key] = numberValue
            elseif value == "true" then
                params[key] = true
            elseif value == "false" then
                params[key] = false
            else
                params[key] = value
            end
        end
    end
    file:close()
    return params
end

function presets:savefile(config, filename)
    local file, err = io.open(filename, "w")
    
    if not file then
        print("Error opening file: " .. err)
        return false
    end
    
    for key, value in pairs(config) do
        local line = key .. ": " .. tostring(value)
        file:write(line .. "\n")
    end
    
    file:close()
    return true
end



function presets:exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

function presets:isdir(path)
   return self:exists(path.."/")
end

function presets:scandir(dir)
    local i, t, popen = 0, {}, io.popen
    local file = popen('ls "'..dir..'"')
    for fname in file:lines() do
        i = i + 1
        t[i] = fname
    end
    file.close()
    return t
end

function presets:printparams()
    print("========== PARAMS ==========")
    for p, v in pairs(self.currentparams) do
        print(string.format("%s: %s", p, v))
    end
    print("============================")
end

