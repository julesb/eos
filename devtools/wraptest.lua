local eos = require("eos")


for i = 0, 11 do
  print(string.format("%d: %d", i, eos.wrapidx(i, 10)))
end

print("### WRAP -1 .. 1")
for i=-1.5, 1.5, 0.1 do
  print(i .. ": " .. eos.wrap_neg1_to_1(i))
end
