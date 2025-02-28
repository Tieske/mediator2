-- using `ctx` to pass `self` to the callback function.

local Mediator = require 'mediator2'
local m = Mediator()


local myObject = {
  noise_count = 0
}

function myObject:makeNoiseHandler(noise)
  self.noise_count = self.noise_count + 1
  print(self.noise_count, noise)
end

local c = m:getChannel({"animal", "cat"})
c:addSubscriber(myObject.makeNoiseHandler, { ctx = myObject })
m:publish("meow")

