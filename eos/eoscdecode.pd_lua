
local eoscdecode = pd.Class:new():register("eoscdecode")

function eoscdecode:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 2
  return true
end

function eoscdecode:in_1_list(inp)
  local zlib = require("zlib")
  local function hexencode(str)
     return (str:gsub(".", function(char) return string.format("%02x ",char:byte()) end))
  end
  local compressed_len = inp[1]
  local compressed_bytes = string.pack("<" .. string.rep("B", compressed_len),
                                       table.unpack(inp, 2, #inp))
  print("########### DECODE")
  print(hexencode(compressed_bytes))
  print(string.format("compressed len: %d", #compressed_bytes))

  local stream = zlib.inflate()
  local inflated, eof, bytes_in, bytes_out = stream(compressed_bytes)
  local out = {}
  print(string.format("in=%d, out=%d, points=%d, actual=%d",
                      bytes_in, bytes_out, bytes_out / 7, #inflated))

  for i = 1, #inflated, 7 do
    local x, y, r, g, b = string.unpack("<HHBBB", inflated, i)
     x = x / 32767 - 1
     y = y / 32767 - 1
     r = r / 255
     g = g / 255
     b = b / 255
    print(x, y, r, g, b)
    table.insert(out, x)
    table.insert(out, y)
    table.insert(out, r)
    table.insert(out, g)
    table.insert(out, g)
  end
  self:outlet(1, "float", { #out / 5 })
  self:outlet(1, "list", out)
end
