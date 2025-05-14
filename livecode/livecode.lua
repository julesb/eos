-- livecode.lua
local eosclient = require("eosclient")
local socket = require("socket") -- For more precise sleep functions
local colorConstants = require("colorconstants")

-- Configuration
local scriptPath = arg[1] -- Use arg[] for command line arguments
if not scriptPath then
  print("Usage: lua livecode.lua <script_file.lua>")
  os.exit(1)
end

-- Initialize the laser client
local laserClient = eosclient.init("127.0.0.1", 12000)

-- Global environment for the loaded scripts
local scriptEnv = {
  -- Include standard libraries
  math = math,
  table = table,
  string = string,
  os = os,
  io = io,

  -- Expose the laser client
  laser = laserClient,

  -- Utility functions
  sleep = function(sec)
    socket.sleep(sec)
  end,
  
  C = colorConstants,

}
setmetatable(scriptEnv, {__index = _G}) -- Fall back to global environment

-- Animation control variables
local running = false
local lastContent = ""
local frameDelay = 1/64-- Target 60 FPS
local lastModTime = 0

-- Get file content
local function getFileContent()
  local file = io.open(scriptPath, "r")
  if not file then return "" end

  local content = file:read("*all")
  file:close()

  return content
end

-- Linux-specific file modification check
local function getFileModTime()
  local handle = io.popen('stat -c %Y "' .. scriptPath .. '"')
  if not handle then return 0 end

  local result = handle:read("*a")
  handle:close()

  return tonumber(result) or 0
end

-- Load script
local function loadScript()
  print("Loading script: " .. scriptPath)

  -- Update last known state
  lastContent = getFileContent()
  lastModTime = getFileModTime()

  local scriptCode, err = loadfile(scriptPath, "t", scriptEnv)
  if not scriptCode then
    print("Error loading script: " .. tostring(err))
    return false
  end

  -- Execute the script to define functions
  local success, err = pcall(scriptCode)
  if not success then
    print("Error executing script: " .. tostring(err))
    return false
  end

  -- Check for init function
  if type(scriptEnv.init) == "function" then
    local success, err = pcall(scriptEnv.init)
    if not success then
      print("Error in init function: " .. tostring(err))
    end
  end

  print("OK: " .. scriptPath)
  return true
end

-- THE KEY CHANGE: File watching and animation in the same thread
print("Livecoding environment started. Watching: " .. scriptPath)
print("Press Ctrl+C to exit")

-- Initial script load
local loaded = loadScript()
if not loaded then
  print("Failed to load initial script")
  os.exit(1)
end

-- Animation variables
local startTime = socket.gettime()
local lastFrameTime = startTime

-- Main loop combining animation and file watching
while true do
  -- 1. Check for file changes
  -- local checkStart = socket.gettime()
  local currentModTime = getFileModTime()
  local currentContent = getFileContent()

  -- Detect changes
  if currentModTime > lastModTime or currentContent ~= lastContent then
    -- print("Script modified, reloading...")

    -- Call cleanup if defined
    if type(scriptEnv.cleanup) == "function" then
      pcall(scriptEnv.cleanup)
    end

    -- Reload script
    loaded = loadScript()
    if loaded then
      -- Reset animation timing
      startTime = socket.gettime()
      lastFrameTime = startTime
    end
  end

  -- 2. Run animation frame if script is loaded and has animate function
  if loaded and type(scriptEnv.animate) == "function" then
    local currentTime = socket.gettime()
    local frameTime = currentTime - lastFrameTime

    -- Only render a new frame if enough time has passed
    if frameTime >= frameDelay then
      local animTime = currentTime - startTime
      lastFrameTime = currentTime

      -- Run the animation frame
      local success, err = pcall(scriptEnv.animate, animTime)
      if not success then
        print("Error in animate function: " .. tostring(err))
      end
    end
  end

  -- Sleep a small amount to avoid hogging CPU
  socket.sleep(0.001)
end
