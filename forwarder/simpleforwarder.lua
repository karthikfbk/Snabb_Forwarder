
module(..., package.seeall)
local packet = require("core.packet")
Simpleforwarder = {}

function Simpleforwarder:new ()
   local o = { packet_counter = 1 }
   return setmetatable(o, {__index = Simpleforwarder})
end

function Simpleforwarder:push()
   local i = assert(self.input.input, "input port not found")
   local o = assert(self.output.output, "output port not found")

   while not link.empty(i) and not link.full(o) do
      self:process_packet(i, o)
      self.packet_counter = self.packet_counter + 1
   end

   if link.full(o) then
	print("Output link is full")
   end
end


function Simpleforwarder:process_packet(i, o)
   local p = link.receive(i)	
   link.transmit(o, p)   
end
