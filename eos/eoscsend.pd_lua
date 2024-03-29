local eoscsend = pd.Class:new():register("eoscsend")
local losc = require("losc")
local plugin = require("losc.plugins.udp-socket")
local zlib = require("zlib")

function eoscsend:initialize(sel, atoms)
  self.inlets = 2
  self.outlets = 0
  self.remoteaddr = nil
  self.remoteport = nil
  self.usecompression = true
  self.bypass = false

  if atoms[1] ~= nil then
    self.remoteaddr = atoms[1]
  end
  if atoms[2] ~= nil then
    self.remoteport = math.floor(tonumber(atoms[2]))
  end

  if not self.remoteaddr and self.remoteport then
    print("ERROR: eoscsend:initialize(): need address and port")
    return false
  end

  local udp = plugin.new({sendAddr=self.remoteaddr, sendPort=self.remoteport})
  self.osc = losc.new({plugin=udp})
  print(string.format("eoscsend: addr=%s, port=%s", self.remoteaddr, self.remoteport))
  return true
end


function eoscsend:in_1_list(inp)
  if self.bypass then return end
  local packed = eoscsend:pack(inp)
  local payload, compressed

  local function hexencode(str)
     return (str:gsub(".", function(char) return string.format("%02x ",char:byte()) end))
  end

  if self.usecompression then
    local stream = zlib.deflate(zlib.BEST_SPEED)
    local eof, bytes_in, bytes_out
    compressed, eof, bytes_in, bytes_out = stream(packed, 'full')
    payload = { compressed }

    -- print("########### ENCODE")
    -- print(hexencode(compressed))
    -- print(string.format("compressed len: %d", #compressed))
  else
    payload = { packed }
  end


  local msg = {
    address = "/f",
    types = "b",
    payload[1]
  }
  self.osc:send(msg)
end


function eoscsend:in_2_float(b)
  self.bypass = (b ~= 0)
end


function eoscsend:pack(points)
  assert(#points % 5 == 0, "invalid number of points")
  local string_pack = string.pack
  local table_insert = table.insert
  local packed_values = {}
  packed_values[#points / 5] = nil -- pre-allocate table size

  local function clamp(n, mn, mx)
    return math.max(math.min(n, mx), mn)
  end

  for i = 1, #points, 5 do
    local x, y, r, g, b =
      math.floor((0.5 + 0.5*clamp(points[i    ], -1, 1)) * 65535),
      math.floor((0.5 + 0.5*clamp(points[i + 1], -1, 1)) * 65535),
      math.floor(clamp(points[i + 2], 0, 1) * 255),
      math.floor(clamp(points[i + 3], 0, 1) * 255),
      math.floor(clamp(points[i + 4], 0, 1) * 255)
    -- print(string.format("eoscsend:pack(): % .4f\t % .4f\t % .2f\t% .2f\t% .2f",
    --                     x, y, r, g, b))
    local packed_point = string_pack("<HHBBB", x, y, r, g, b)
    table_insert(packed_values, packed_point)
  end

  return table.concat(packed_values)
end


local function hexdecode(hex)
   return (hex:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end))
end

