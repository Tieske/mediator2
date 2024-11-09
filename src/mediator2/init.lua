--- Mediator pattern implementation for Lua.
-- mediator2 allows you to subscribe and publish to a central object so
-- you can decouple function calls in your application. It's as simple as:
--
--     mediator:subscribe({"channel"}, function)
--
-- Supports namespacing, predicates,
-- and more.
-- @module mediator

local function getUniqueId(obj)
  return tonumber(tostring(obj):match(':%s*[0xX]*(%x+)'), 16)
end



--- Subscriber class.
-- This class is instantiated by the `mediator:subscribe` method.
-- @type Subscriber
local Subscriber = setmetatable({},{

  -- Instantiates a new Subscriber object.
  -- @tparam function fn The callback function to be called when the channel is published to.
  -- @tparam table options A table of options for the subscriber, see `mediator:subscribe` for fields.
  -- @tparam Channel channel The channel the subscriber is subscribed to.
  -- @treturn Subscriber the newly created subscriber
  __call = function(self, fn, options, channel)
    local sub = {
      options = options or {},
      fn = fn,
      channel = channel,
    }
    sub.id = getUniqueId(sub)

    return setmetatable(sub, self)
  end
})

function Subscriber:__index(key)
  self[key] = Subscriber[key] -- copy method to instance for faster future access
  return Subscriber[key]
end



--- Updates the subscriber with new options.
-- @tparam table updates A table of updates options for the subscriber, with fields:
-- @tparam[opt] function updates.fn The new callback function to be called when the channel is published to.
-- @tparam[opt] table updates.options The new options for the subscriber, see `mediator:subscribe` for fields.
-- @return nothing
function Subscriber:update(updates)
  if updates then
    self.fn = updates.fn or self.fn
    self.options = updates.options or self.options
    if self.options.priority then
      self.channel:setPriority(self.id, self.options.priority)
      self.options.priority = nil
    end
  end
end



--- Removes the subscriber.
-- @return the removed `Subscriber`
function Subscriber:remove()
  return self.channel:removeSubscriber(self.id)
end



--- Channel class.
-- This class is instantiated automatically by accessing channels (passing the namespace-array) to the
-- `mediator` methods. To create or access one use `mediator:getChannel`.
-- @type Channel
local Channel = setmetatable({}, {

  -- Instantiates a new Channel object.
  -- @tparam string namespace The namespace of the channel.
  -- @tparam Channel parent The parent channel.
  -- @treturn Channel the newly created channel
  __call = function(self, namespace, parent)
    local chan = {
      namespace = namespace,
      subscribers = {},
      channels = {},
      parent = parent,
    }
    return setmetatable(chan, self)
  end
})

function Channel:__index(key)
  self[key] = Channel[key] -- copy method to instance for faster future access
  return Channel[key]
end



--- Creates a subscriber and adds it to the channel.
-- @tparam function fn The callback function to be called when the channel is published to.
-- @tparam table options A table of options for the subscriber. See `mediator:subscribe` for fields.
-- @treturn Subscriber the newly created subscriber
function Channel:addSubscriber(fn, options)
  options = options or {}

  local priority = options.priority or (#self.subscribers + 1)
  priority = math.max(math.min(math.floor(priority), #self.subscribers + 1), 1)
  options.priority = nil

  local callback = Subscriber(fn, options, self)

  table.insert(self.subscribers, priority, callback)

  return callback
end



--- Gets a subscriber by its id.
-- @tparam number id The id of the subscriber to get.
-- @return table or nil if not found. The table will have field `index` with the index (or priority)
-- of the subscriber in its channel, and field `value` with the subscriber object itself.
function Channel:getSubscriber(id)
  for i, callback in ipairs(self.subscribers) do
    if callback.id == id then return { index = i, value = callback } end
  end
  for _, channel in pairs(self.channels) do
    local sub = channel:getSubscriber(id)
    if sub then return sub end
  end
end



--- Sets the priority of a subscriber.
-- @tparam number id The id of the subscriber to set the priority of.
-- @tparam number priority The new priority of the subscriber.
-- @return nothing
function Channel:setPriority(id, priority)
  local callback = self:getSubscriber(id)

  priority = math.max(math.min(math.floor(priority), #self.subscribers), 1)

  -- TODO: fix bug; getSubscriber will recursively search through all child-namespaces, so
  -- the subscriber might reside in ANOTHER channel. But below we're assuming that the `index`
  -- is valid for THIS channel.
  if callback.value then
    table.remove(self.subscribers, callback.index)
    table.insert(self.subscribers, priority, callback.value)
  end
end



--- Adds a namespace/sub-channel to the channel.
-- @tparam string namespace The namespace of the channel to add.
-- @treturn Channel the newly created channel
function Channel:addChannel(namespace)
  self.channels[namespace] = Channel(namespace, self)
  return self.channels[namespace]
end



--- Checks if a namespace/sub-channel exists.
-- @tparam string namespace The namespace of the channel to check.
-- @treturn boolean `true` if the channel exists, `false` otherwise
function Channel:hasChannel(namespace)
  return namespace and self.channels[namespace] and true
end



--- Gets a namespace/sub-channel, or creates it if it doesn't exist.
-- @tparam string namespace The namespace of the channel to get.
-- @treturn Channel the existing, or newly created channel
function Channel:getChannel(namespace)
  return self.channels[namespace] or self:addChannel(namespace)
end



--- Removes a subscriber.
-- @tparam number id The id of the subscriber to remove.
-- @treturn Subscriber the removed subscriber, or nil if not found
function Channel:removeSubscriber(id)
  local callback = self:getSubscriber(id)

  if callback and callback.value then
    for _, channel in pairs(self.channels) do
      channel:removeSubscriber(id)
    end

    return table.remove(self.subscribers, callback.index)
  end
end



--- Publishes to the channel.
-- After publishing is complete, the parent channel will be published to as well.
-- @tparam table result Return values (first only) from the callbacks will be stored in this table
-- @param ... The arguments to pass to the subscribers.
-- @treturn table The result table after all subscribers have been called.
function Channel:publish(result, ...)
  for i = 1, #self.subscribers do
    local callback = self.subscribers[i]

    -- if it doesn't have a predicate, or it does and it's true then run it
    if not callback.options.predicate or callback.options.predicate(...) then
        -- just take the first result and insert it into the result table
      local value, continue = callback.fn(...) -- TODO: continue seems easy to break, should it be "stop" instead?

      if value then table.insert(result, value) end
      if not continue then return result end
    end
  end

  if self.parent then
    return self.parent:publish(result, ...)
  else
    return result
  end
end



--- Mediator class.
-- This class is instantiated by calling on the module table.
-- @type Mediator

local Mediator = setmetatable({},{
  __call = function(self)
    local med = {
      channel = Channel('root'),
    }
    return setmetatable(med, self)
  end
})

function Mediator:__index(key)
  self[key] = Mediator[key] -- copy method to instance for faster future access
  return Mediator[key]
end


--- Gets a channel by its namespace, or creates it if it doesn't exist.
-- @tparam array channelNamespace The namespace-array of the channel to get.
-- @treturn Channel the existing, or newly created channel
function Mediator:getChannel(channelNamespace)
  local channel = self.channel

  for i=1, #channelNamespace do
    channel = channel:getChannel(channelNamespace[i])
  end

  return channel
end



--- Subscribes to a channel.
-- @tparam array channelNamespace The namespace-array of the channel to subscribe to (created if it doesn't exist).
-- @tparam function fn The callback function to be called when the channel is published to.
-- signature: `anyResult, boolContinue = fn(...)` where `anyResult` is any value to be stored in the result table,
-- and `boolContinue` is a boolean indicating whether to continue calling the next subscriber.
-- @tparam table options A table of options for the subscriber, with fields:
-- @tparam[opt] function options.predicate A function that returns a boolean. If `true`, the subscriber will be called.
-- The predicate function will be passed the arguments that were passed to the publish function.
-- @tparam[opt] integer options.priority The priority of the subscriber. The lower the number,
-- the higher the priority. Defaults to after all existing handlers.
-- @treturn Subscriber the newly created subscriber
function Mediator:subscribe(channelNamespace, fn, options)
  return self:getChannel(channelNamespace):addSubscriber(fn, options)
end



--- Gets a channel subscriber by its id.
-- @tparam number id The id of the subscriber to get.
-- @tparam array channelNamespace The namespace-array of the channel to get the subscriber from (created if it doesn't exist).
-- @return table or nil if not found. The table will have field `index` with the index (or priority)
-- of the subscriber in its channel, and field `value` with the subscriber object itself.
function Mediator:getSubscriber(id, channelNamespace)
  -- TODO: channel:getSubscriber will recursivly search through all child-namespaces, so
  -- we don't need the channelNamespace parameter here. It should default to the `root` channel
  return self:getChannel(channelNamespace):getSubscriber(id)
end



--- Removes a subscriber.
-- @tparam number id The id of the subscriber to remove.
-- @tparam array channelNamespace The namespace-array of the channel to remove the subscriber from (created if it doesn't exist).
-- @treturn Subscriber the removed subscriber, or nil if not found
function Mediator:removeSubscriber(id, channelNamespace)
  -- TODO: channel:getSubscriber will recursivly search through all child-namespaces, so
  -- we don't need the channelNamespace parameter here. It should default to the `root` channel
  return self:getChannel(channelNamespace):removeSubscriber(id)
end



--- Publishes to a channel (and its parents).
-- @tparam array channelNamespace The namespace-array of the channel to publish to (created if it doesn't exist).
-- @param ... The arguments to pass to the subscribers.
-- @treturn table The result table after all subscribers have been called.
function Mediator:publish(channelNamespace, ...)
  return self:getChannel(channelNamespace):publish({}, ...)
end



return Mediator
