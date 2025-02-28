-- An example of using MQTT topics with the mediator
local mqttMediator = require("mediator2")()


local function splitTopic(str)
  local fields = {}
  str:gsub("([^/]*)", function(c) fields[#fields+1] = c end)
  return fields
end


--- Publish an incoming MQTT message to the Mediator subscribers
local function mqttPublish(topic, ...)
  return mqttMediator:publish(splitTopic(topic), ...)
end


--- Create a Mediator subscriber to listen for incoming MQTT topics
local function mqttSubscribe(topic, handler, options)
  local segments = splitTopic(topic)
  for i, segment in ipairs(segments) do
    if segment == "+" then
      segments[i] = mqttMediator.WILDCARD
    end
  end

  options = options or {}

  if segments[#segments] == "#" then
    segments[#segments] = mqttMediator.WILDCARD
    options.skipChildren = false
  else
    options.skipChildren = true
  end

  return mqttMediator:addSubscriber(segments, handler, options)
end

-------------------------------------------------------------------------------
-- Let's test it!
-------------------------------------------------------------------------------

mqttSubscribe("foo/bar/baz", function(...)
  print("\tfoo/bar/baz: ", ...)
end)

mqttSubscribe("foo/+/baz", function(...)
  print("\tfoo/+/baz:   ", ...)
end)

mqttSubscribe("foo/bar/+", function(...)
  print("\tfoo/bar/+:   ", ...)
end)

mqttSubscribe("foo/#", function(...)
  print("\tfoo/#:       ", ...)
end)

print("foo/bar/baz")
mqttPublish("foo/bar/baz", "hello to foo/bar/baz")
print("foo/no-bar/baz")
mqttPublish("foo/no-bar/baz", "hello to foo/no-bar/baz")
print("foo//baz")
mqttPublish("foo//baz", "hello to foo//baz") -- empty segment
print("foo/baz")
mqttPublish("foo/baz", "hello to foo/baz")
print("foo")
mqttPublish("foo", "hello to foo")
