local xygizmo = pd.Class:new():register("xygizmo")

function xygizmo:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 2
   self.npoints = 600
   self.time = 0.0
   self.tau = 2 * math.pi

   self.x1freq = 1.0
   self.x1amp = 0.5
   self.x1phase = 0.0

   self.y1freq = 1.0
   self.y1amp = 0.5
   self.y1phase = 0.25

   self.x2freq = 1.0
   self.x2amp = 0.5
   self.x2phase = 0.0
   
   self.y2freq = 1.0
   self.y2amp = 0.5
   self.y2phase = 0.25

   return true
end

function xygizmo:in_1_bang()
    local xpoints = {}
    local ypoints = {}
    local out = {}
    local idx = 1
    local t = self.time
    local dt = (1.0 / self.npoints)
    for i=1,self.npoints do
        local xwave = self.x1amp * math.sin(t*self.x1freq*self.tau + self.x1phase) 
                    + self.x2amp * math.sin(t*self.x2freq*self.tau + self.x2phase)
        local ywave = self.y1amp * math.sin(t*self.y1freq*self.tau + self.y1phase) 
                    + self.y2amp * math.sin(t*self.y2freq*self.tau + self.y2phase)

        out[idx] = xwave -- * 2047
        idx = idx + 1
        out[idx] = ywave -- * 2047
        idx = idx + 1
        out[idx] =  1 --255 
        idx = idx + 1
        out[idx] =  1 -- 255 
        idx = idx + 1
        out[idx] = 1 -- 
        idx = idx + 1
        t = t + dt
    end

-- loop back to first point
--    for lp=1,8 do
--        out[idx] = out[1]
--        idx = idx + 1
--        out[idx] = out[2]
--        idx = idx + 1
--        out[idx] = out[3]
--        idx = idx + 1
--        out[idx] = out[4]
--        idx = idx + 1
--        out[idx] = out[5]
--        idx = idx + 1
--    end
 
    self.time = t
    self:outlet(2, "list", { #out / 5})
    self:outlet(1, "list", out)
end

function xygizmo:in_2_npoints(x)
    if x[1] >= 10 then
        self.npoints = x[1]
        self:outlet(2, "float", {self.npoints})
    end
end

function xygizmo:in_2(sel, atoms)
    if     sel == "x1freq"  then self.x1freq  = atoms[1]
    elseif sel == "x1amp"   then self.x1amp   = atoms[1]
    elseif sel == "x1phase" then self.x1phase = atoms[1] * math.pi * 2
    
    elseif sel == "x2freq"  then self.x2freq  = atoms[1] 
    elseif sel == "x2amp"   then self.x2amp   = atoms[1]
    elseif sel == "x2phase" then self.x2phase = atoms[1] * math.pi * 2
    
    elseif sel == "y1freq"  then self.y1freq  = atoms[1]
    elseif sel == "y1amp"   then self.y1amp   = atoms[1]
    elseif sel == "y1phase" then self.y1phase = atoms[1] * math.pi * 2
    
    elseif sel == "y2freq"  then self.y2freq  = atoms[1]
    elseif sel == "y2amp"   then self.y2amp   = atoms[1]
    elseif sel == "y2phase" then self.y2phase = atoms[1] * math.pi * 2
    elseif sel == "time"    then self.time = atoms[1]
    end
end

