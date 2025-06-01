
-- This is small test client for the quicksilver server, for 

local function pack(points)
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
    print(string.format("eosc:pack(): % .4f\t % .4f\t % .2f\t% .2f\t% .2f",
                       x, y, r, g, b))
    local packed_point = string_pack("<HHBBB", x, y, r, g, b)
    table_insert(packed_values, packed_point)
  end

  return table.concat(packed_values)
end


local function dumppoints(points)
  for i = 1, #points, 5 do
    local x, y, r, g, b =
      points[i    ],
      points[i + 1],
      points[i + 2],
      points[i + 3],
      points[i + 4]
    print(string.format("[%d/%d]: [% .4f\t% .4f]\t[%.2f\t%.2f\t%.2f]",
                        math.floor(i/5)+1, #points/5, x, y, r, g, b))
  end
end


local function circle(rad, npoints)
  npoints = npoints or 100
  local points = {}
  local step = math.pi * 2 / npoints
  for i = 1,npoints do
    local ang = (i-1) * step
    local x = rad * math.cos(ang)
    local y = rad * math.sin(ang)
    table.insert(points, x)
    table.insert(points, y)
    table.insert(points, 1)
    table.insert(points, 1)
    table.insert(points, 1)
  end
  return points
end

local function square()
  return {
    -1, -1, 1, 1, 1,
     1, -1, 1, 1, 1,
     1,  1, 1, 1, 1,
    -1,  1, 1, 1, 1,
    -1, -1, 1, 1, 1
  }
end


local function dotest()
  local losc = require("losc")
  local plugin = require("losc.plugins.udp-socket")
  local udp = plugin.new({sendAddr="127.0.0.1", sendPort=12000})
  local osc = losc.new({plugin=udp})
  local zlib = require("zlib")

  local loop = false
  local use_compression = true

  local points = circle(0.1, 500)

  print("Sending points:")
  dumppoints(points)

  local packed = pack(points)
  local packed_size = string.len(packed)
  local payload

  if use_compression then
    --local stream = zlib.deflate(zlib.BEST_SPEED)
    local stream = zlib.deflate()
    local compressed, eof, bytes_in, bytes_out = stream(packed, 'full')
    payload = { compressed }

    local ratio = bytes_out / packed_size
    print(string.format("deflate: in=%d, out=%d, eof=%s, actual=%d, ratio=%.2f",
                       bytes_in, bytes_out, eof, string.len(compressed), ratio))
  else
    payload = { packed }
  end

  local msg = {
    address = "/dac/0/frame",
    types = "b",
    payload[1]
  }

  osc:send(msg)
end
  -- dumppoints(points)


function sleep(sec)
  local socket = require("socket")
  socket.select(nil, nil, sec)
end

while true do
  dotest()
  sleep(0.02)
end

print("DONE")

