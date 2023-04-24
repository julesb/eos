local IL = pd.Class:new():register("ilda-library")

function IL:initialize(sel, atoms)
    self.inlets = 2
    self.outlets = 3
    self.dir = "ILDA"
    self.currentfileidx = 1
    self.filelist = self:scandir(self.dir)
    
    --for i = 1, #self.filelist do
    --    print(self.filelist[i])
    --end
    print("Ilda files: ", #self.filelist)
    return true
end

function IL:in_2(sel, atoms)
    if sel == "next" then
        self.currentfileidx = IL:wrapidx(self.currentfileidx+1, #self.filelist)
        self:outlet(3, "float", {#self.filelist})
        self:outlet(2, "float", {self.currentfileidx})
        self:outlet(1, "symbol", {self.filelist[self.currentfileidx]})
    elseif sel == "prev" then
        self.currentfileidx = IL:wrapidx(self.currentfileidx-1, #self.filelist)
        self:outlet(3, "float", {#self.filelist})
        self:outlet(2, "float", {self.currentfileidx})
        self:outlet(1, "symbol", {self.filelist[self.currentfileidx]})
    elseif sel == "goto" then
    elseif sel == "scan" then

    end

end

function IL:isdir(path)
   return self:exists(path.."/")
end

function IL:scandir(dir)
    local i, t, popen = 0, {}, io.popen
    local file = popen('ls "'..dir..'"')
    for fname in file:lines() do
        i = i + 1
        t[i] = fname
    end
    file.close()
    return t
end

function IL:wrapidx(idx, div)
    return ((idx-1) % div) + 1
end
