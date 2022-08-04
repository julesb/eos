local gt = pd.Class:new():register("graphicstest")

function gt:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.inlets = 1
    self.outlets = 2
    return true
end

function gt:in_1_bang()
    local g = require("graphics")
    local scene = g.create()
    local dim = 4
    local d = dim / 2.0
    local p1, p2
    local col = {r=0, g=1, b=0}
    for x=0-d, d do
        p1 = { x = x/d, y = 0 }   
        p2 = { x = x/d, y = 1 }   
        g.line(scene, p1, p2, col)
    end
    col = {r=0, g=0, b=1}
    for y = 0, d*2 do
        p1 = { x = 0, y = (y-d)/d }   
        p2 = { x = 1, y = (y-d)/d }   
        g.line(scene, p1, p2, col)
    end
    self:outlet(2, "float", { #scene.paths })
    self:outlet(1, "list", scene.paths)
end
