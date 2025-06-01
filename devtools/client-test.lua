local eosclient = require("eosclient")
local eos = require("eos")

local client = eosclient.init("localhost", 12012)



-- Create some laser points (x, y, r, g, b format)
local points = {
  0, -1, 1, 0, 0,       -- red point at center
  1, 0, 0, 1, 0,       -- green point at right
  0, 1, 0, 0, 1,       -- blue point at top
  -1, 0, 1, 1, 0,      -- yellow point at left
  0, -1, 1, 0, 1       -- magenta point at bottom
}



-- Send the points
client.send(points)
