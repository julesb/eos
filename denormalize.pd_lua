local D = pd.Class:new():register("denormalize")


function D:initialize(sel, atoms)
    self.screenscale = 2047.0
    self.colorscale = 255.0
    self.inlets = 1
    self.outlets = 1
    return true
end

function D:in_1_list(inp)
    local eos = require("eos")
    local out = {}
    for i=1,#inp, 5 do
        eos.addpoint(
            out,
            inp[i  ] * self.screenscale,
            inp[i+1] * self.screenscale,
            inp[i+2] * self.colorscale,
            inp[i+3] * self.colorscale,
            inp[i+4] * self.colorscale
        )
    end
    self:outlet(1, "list", out)
end
