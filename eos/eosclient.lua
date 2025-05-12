-- eosclient.lua
local losc = require("losc")
local plugin = require("losc.plugins.udp-socket")
local zlib = require("zlib")

local eosclient = {}

function eosclient.init(remoteaddr, remoteport, options)
  local self = {}
  options = options or {}

  self.remoteaddr = remoteaddr
  self.remoteport = math.floor(tonumber(remoteport))
  self.usecompression = options.usecompression ~= false  -- default to true
  self.bypass = options.bypass or false

  if not self.remoteaddr or not self.remoteport then
    error("ERROR: eosclient.init(): need address and port")
  end

  local udp = plugin.new({sendAddr=self.remoteaddr, sendPort=self.remoteport})
  self.osc = losc.new({plugin=udp})

  print(string.format("eosclient: addr=%s, port=%s", self.remoteaddr, self.remoteport))

  -- Pack points for laser frames
  function self.pack(points)
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

      local packed_point = string_pack("<HHBBB", x, y, r, g, b)
      table_insert(packed_values, packed_point)
    end

    return table.concat(packed_values)
  end

  -- Send laser frame data
  function self.send(points)
    if self.bypass then return end

    local packed = self.pack(points)
    local payload

    if self.usecompression then
      local stream = zlib.deflate(zlib.BEST_SPEED)
      local compressed, eof, bytes_in, bytes_out = stream(packed, 'full')
      payload = compressed
    else
      payload = packed
    end

    local msg = {
      address = "/f",
      types = "b",
      payload
    }

    self.osc:send(msg)
  end

  -- Set bypass state
  function self.setBypass(state)
    self.bypass = (state ~= false)
  end

  -- Set compression state
  function self.setCompression(state)
    self.usecompression = (state ~= false)
  end

  -- Helper for debugging
  function self.hexencode(str)
    return (str:gsub(".", function(char) return string.format("%02x ", char:byte()) end))
  end

  function self.hexdecode(hex)
    return (hex:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end))
  end

  return self
end

return eosclient
