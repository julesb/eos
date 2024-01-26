
local oscidsend = pd.Class:new():register("oscid-send")


function oscidsend:initialize(sel, atoms)
  self.inlets = 1
  return true
end

function oscidsend:in_1_list(oscmsg)
  local receiver_elems = {}
  local value = {}

  -- collect the receiver address parts 
  local i = 1
  while i <= #oscmsg and type(oscmsg[i]) == "string" do
      table.insert(receiver_elems, oscmsg[i])
      i = i + 1
  end

  -- collect the value(s)
  while i <= #oscmsg and type(oscmsg[i]) == "number" do
      table.insert(value, oscmsg[i])
      i = i + 1
  end

  self.receiver = table.concat(receiver_elems, "/")

  if #value == 1 then
    pd.send(self.receiver, "float", value)
    -- print(string.format("oscid-send: receiver=%s, value=%s", self.receiver, value))
  else
    pd.send(self.receiver, "list", value)
    -- print(string.format("oscid-send: receiver=%s, value=list[%d]", self.receiver, #value))
  end
end
