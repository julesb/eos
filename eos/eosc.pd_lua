local eosc = pd.Class:new():register("eosc")
local losc = require("losc")
local plugin = require("losc.plugins.udp-socket")
local zlib = require("zlib")

function eosc:initialize(sel, atoms)
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
    print("ERROR: eosc:initialize(): need address and port")
    return false
  end

  local udp = plugin.new({sendAddr=self.remoteaddr, sendPort=self.remoteport})
  self.osc = losc.new({plugin=udp})
  print(string.format("eosc: addr=%s, port=%s", self.remoteaddr, self.remoteport))
  return true
end


function eosc:in_1_list(inp)
  if self.bypass then return end
  local packed = eosc:pack(inp)
  local payload

  if self.usecompression then
    local stream = zlib.deflate(zlib.BEST_SPEED)
    local compressed, eof, bytes_in, bytes_out = stream(packed, 'full')
    payload = { compressed }
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


function eosc:in_2_bypass(b)
  self.bypass = (b ~= 0)
end


function eosc:pack(points)
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
    --print(string.format("eosc:pack(): % .4f\t % .4f\t % .2f\t% .2f\t% .2f",
    --                    x, y, r, g, b))
    local packed_point = string_pack("<HHBBB", x, y, r, g, b)
    table_insert(packed_values, packed_point)
  end

  return table.concat(packed_values)
end

