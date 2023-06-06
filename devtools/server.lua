local losc = require'losc'
local plugin = require'losc.plugins.udp-socket'

local udp = plugin.new {
  recvAddr = 'localhost',
  recvPort = 12000,
  ignore_late = true, -- ignore late bundles
}
local osc = losc.new {plugin = udp}

osc:add_handler('/f', function(data)
  local bytes = data.message[1]
  local zlib = require("zlib")
  local stream = zlib.inflate()
  local inflated, eof, bytes_in, bytes_out = stream(bytes)
  print(string.format("in=%d, out=%d, points=%d",
                      bytes_in, bytes_out, bytes_out / 7))
end)


local function print_data(data)
  local msg = data.message
  print('address: ' .. msg.address, 'timestamp: ' .. data.timestamp)
  for index, argument in ipairs(msg) do
    print('index: ' .. index, 'arg: ' .. argument)
  end
end


-- osc:add_handler('/param/{x,y,z}', function(data)
--   print_data(data)
-- end)

osc:open()
