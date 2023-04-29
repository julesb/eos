local N = pd.Class:new():register("normalize")


function N:initialize(sel, atoms)
    self.screenunit = 1.0 / 2047.0
    self.colorunit = 1.0 / 255.0
    self.inlets = 1
    self.outlets = 1
    return true
end

function N:in_1_list(inp)
    local eos = require("eos")
    local out = {}
    for i=1,#inp, 5 do
        eos.addpoint(
            out,
            inp[i  ] * self.screenunit,
            inp[i+1] * self.screenunit,
            inp[i+2] * self.colorunit,
            inp[i+3] * self.colorunit,
            inp[i+4] * self.colorunit
        )
    end
    self:outlet(1, "list", out)
end
