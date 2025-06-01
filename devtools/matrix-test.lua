local m4 = require("mat4")
local v3 = require("vec3")


print("IDENTITY TRANSFORM")
local id = m4.identity()
print(m4.tostring(id))

local v = v3.new(1, 2, 3)
print("V:",v3.tostring(v))

local result = m4.transform(v, id)
print("result:", v3.tostring(result))


print("TRANSLATE TRANSFORM")
local tm = m4.translate(1, 2, 3)
print(m4.tostring(tm))

local tv = v3.new(0, 0, 0)
print("V:", v3.tostring(tv))

result = m4.transform(tv, tm)
print("result:", v3.tostring(result))

-- local scalemat = m4.scale()

