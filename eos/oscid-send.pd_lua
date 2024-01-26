
local oscidsend = pd.Class:new():register("oscid-send")


function oscidsend:initialize(sel, atoms)
  self.inlets = 1
  return true
end


function oscidsend:in_1_list(oscmsg)
  local value = oscmsg[#oscmsg]

  local receiver_elements = {}
  for i = 1, #oscmsg - 1 do
    receiver_elements[i] = oscmsg[i]
  end

  self.receiver = table.concat(receiver_elements, "/")
  print(string.format("oscid-send: receiver=%s, value=%s", self.receiver, value))
  pd.send(self.receiver, "float", {value})
end

