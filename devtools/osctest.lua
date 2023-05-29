
local socket = require("socket")
local losc = require("losc")
local plugin = require("losc.plugins.udp-socket")
local udp = plugin.new({sendAddr="aorus", sendPort=12000})
local osc = losc.new({plugin=udp})


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
    --print(string.format("eosc:pack(): % .4f\t % .4f\t % .2f\t% .2f\t% .2f",
    --                    x, y, r, g, b))
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


local function dotest()
  --local filename = "Ildatest.ild"
  --local filename = "ilda99.ild"
  local filename = "warp von swami.ild"
  --local filename = "1-rest.ild"
  local IldaFile = require("ildafile")
  local file = IldaFile:new("../ILDA/" .. filename, "ILDA")
  local loop =false

  dumppoints(file.frames[1])

  for fidx, frame in ipairs(file.frames) do
      print(string.format("[%s] frame[%d/%d]: points: %d",
            filename,  fidx, #file.frames, #frame / 5))
  end

  local sq_points = {
    -1, -1, 1, 1, 1,
     1, -1, 1, 1, 1,
     1,  1, 1, 1, 1,
    -1,  1, 1, 1, 1,
    -1, -1, 1, 1, 1
  }

  while true do
    for fidx, frame in ipairs(file.frames) do
      local points = frame
      local packed = pack(points)

      local msg = {
        address = "/frame",
        types = "b",
        packed
      }

      osc:send(msg)
      sleep(1/100)
    end
    if not loop then break end
  end
  -- dumppoints(points)
end

function sleep(sec)
  socket.select(nil, nil, sec)
end

dotest()


print("DONE")

