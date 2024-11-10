--- Mediator pattern implementation for Lua.
-- mediator2 allows you to subscribe and publish to a central object so
-- you can decouple function calls in your application. It's as simple as:
--
--     mediator:addSubscriber({"channel"}, function)
--
-- Supports namespacing, predicates,
-- and more.
--
-- __Some basics__:
--
-- *Priorities*
--
-- Subscribers can have priorities. The lower the number, the higher the priority.
-- The default priority is after all existing handlers.
-- The priorities are implemented as array-indices, so they are 1-based (highest).
-- This also means that changing priority of a subscriber might impact the absolute value
-- of the priority of other subscribers.
--
-- *Channels*
--
-- Channels have a tree structure, where each channel can have multiple sub-channels.
-- When publishing to a channel, the parent channel will be published to as well.
-- Channels are automatically created when subscribing or publishing to them.
--
-- *Context*
--
-- Subscribers can have a context. The context is a value that will be passed to the subscriber
-- on each call. The context will be omitted from the callback if not provided (`nil`). It can be
-- any valid Lua value, and usually is a table.
-- The context doubles as a `self` parameter for object-based handlers.
--
-- *Predicates*
--
-- Subscribers can have predicates. A predicate is a function that returns a boolean.
-- If the predicate returns `true`, the subscriber will be called.
-- The predicate function will be passed the ctx (if present) + the arguments that were
-- passed to the publish function.
--
-- @module mediator



-- signals to be returned by the subscriber to tell the mediator to stop or continue
local STOP = {}
local CONTINUE = {}



--- Subscriber class.
-- This class is instantiated by the `mediator:subscribe` and `Channel:addSubscriber` methods.
-- @type Subscriber
-- @usage
-- local m = require("mediator")()
-- local sub1 = m:addSubscriber({"car", "engine", "rpm"}, function(value, unit)
--     print("Sub1 ", value, unit)
--   end)
-- local sub2 = m:addSubscriber({"car", "engine", "rpm"}, function(value, unit)
--     print("Sub2 ", value, unit)
--   end)
--
-- m:publish({"car", "engine", "rpm"}, 1000, "rpm")
-- -- Output:
-- -- Sub1 1000 rpm
-- -- Sub2 1000 rpm
--
-- sub2:setPriority(1)
--
-- m:publish({"car", "engine", "rpm"}, 2000, "rpm")
-- -- Output:
-- -- Sub2 2000 rpm
-- -- Sub1 2000 rpm
--
-- sub1:remove()
--
-- m:publish({"car", "engine", "rpm"}, 3000, "rpm")
-- -- Output:
-- -- Sub2 3000 rpm
--
-- local options = {
--   ctx = { count = 0 },       -- if provided, will be passed on each call
--   predicate = nil,
--   priority = 1,              -- make this one the top-priority
-- }
-- local sub3 = m:addSubscriber({"car", "engine", "rpm"}, function(ctx, value, unit)
--     ctx.count = ctx.count + 1
--     print("Sub3 ", ctx.count, value, unit)
--     return m.STOP, count     -- stop the mediator from calling the next subscriber
--   end)
--
-- local results = m:publish({"car", "engine", "rpm"}, 1000, "rpm")
-- -- Output:
-- -- Sub3 1 1000 rpm
--
-- print(results[1]) -- 1      -- the result, count, returned from subscriber sub3

local Subscriber = setmetatable({},{

  -- Instantiates a new Subscriber object.
  -- @tparam function fn The callback function to be called when the channel is published to.
  -- @tparam table options A table of options for the subscriber, see `mediator:subscribe` for fields.
  -- @tparam Channel channel The channel the subscriber is subscribed to.
  -- @treturn Subscriber the newly created subscriber
  __call = function(self, fn, options, channel)
    return setmetatable({
        options = options or {},
        fn = fn,
        channel = channel,
      }, self)
  end
})

function Subscriber:__index(key)
if key == "id" then error("id is gone...") end
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
      self:setPriority(self.options.priority)
      self.options.priority = nil
    end
  end
end



--- Changes the priority of the subscriber.
-- @tparam number priority The new priority of the subscriber.
-- @return the priority as set
function Subscriber:setPriority(priority)
  return self.channel:_setPriority(self, priority)
end



--- Removes the subscriber.
-- @return the removed `Subscriber`
function Subscriber:remove()
  local channel = self.channel
  self.channel = nil
  return channel:_removeSubscriber(self)
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



-- Sets the priority of a subscriber.
-- @tparam number id The id of the subscriber to set the priority of.
-- @tparam number priority The new priority of the subscriber.
-- @return the priority set
function Channel:_setPriority(subscriber, priority)
  priority = math.max(math.min(math.floor(priority), #self.subscribers), 1)

  local index
  for i, callback in ipairs(self.subscribers) do
    if callback == subscriber then
      index = i
      break
    end
  end

  if not index then
    error("Subscriber not found") -- this is an internal error, should never happen
  end

  table.remove(self.subscribers, index)
  table.insert(self.subscribers, priority, subscriber)
  return priority
end


--- Adds a single namespace/sub-channel to the current channel.
-- If the channel already exists, the existing one will be returned.
-- @tparam string namespace The namespace of the channel to add.
-- @treturn Channel the newly created channel
function Channel:addChannel(namespace)
  self.channels[namespace] = self.channels[namespace] or Channel(namespace, self)
  return self.channels[namespace]
end



--- Checks if a single namespace/sub-channel exists within the current channel.
-- @tparam string namespace The namespace of the channel to check.
-- @treturn boolean `true` if the channel exists, `false` otherwise
function Channel:hasChannel(namespace)
  return namespace and self.channels[namespace] and true
end



--- Gets a single namespace/sub-channel from the current channel, or creates it if it doesn't exist.
-- @tparam string namespace The namespace of the channel to get.
-- @treturn Channel the existing, or newly created channel
function Channel:getChannel(namespace)
  return self.channels[namespace] or self:addChannel(namespace)
end



-- Removes a subscriber.
-- @tparam number id The id of the subscriber to remove.
-- @treturn Subscriber the removed subscriber
function Channel:_removeSubscriber(subscriber)
  for i, callback in ipairs(self.subscribers) do
    if subscriber == callback then
      table.remove(self.subscribers, i)
      return subscriber
    end
  end
  -- TODO: add test for this error
  error("Subscriber not found")
end



-- Publishes to the channel.
-- After publishing is complete, the parent channel will be published to as well.
-- @tparam table result Return values (first only) from the callbacks will be stored in this table
-- @param ... The arguments to pass to the subscribers.
-- @treturn table The result table after all subscribers have been called.
function Channel:_publish(result, ...)
  for i, subscriber in ipairs(self.subscribers) do
    local ctx = subscriber.options.ctx
    local predicate = subscriber.options.predicate
    local shouldRun = true
    if predicate then
      if ctx ~= nil then
        shouldRun = predicate(ctx, ...)
      else
        shouldRun = predicate(...)
      end
    end

    if shouldRun then
      local continue
      if ctx ~= nil then
        continue, result[#result+1] = subscriber.fn(ctx, ...)
      else
        continue, result[#result+1] = subscriber.fn(...)
      end
      if continue ~= nil then
        if continue == STOP then
          return result
        elseif continue ~= CONTINUE then
          local info = debug.getinfo(subscriber.fn)
          local err = ("Invalid return value from subscriber%s:%s, expected mediator.STOP or mediator.CONTINUE"):format(info.source, info.linedefined)
          error(err)
        end
      end
    end
  end

  if self.parent then
    return self.parent:_publish(result, ...)
  else
    return result
  end
end



--- Publishes to the channel.
-- After publishing is complete, the parent channel will be published to as well.
-- @param ... The arguments to pass to the subscribers.
-- @treturn table The result table after all subscribers have been called.
function Channel:publish(...)
  return self:_publish({}, ...)
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


--- Gets a channel by its namespaces, or creates them if they don't exist.
-- @tparam array channelNamespaces The namespace-array of the channel to get.
-- @treturn Channel the existing, or newly created channel
-- @usage
-- local m = require("mediator")()
-- local channel = m:getChannel({"car", "engine", "rpm"})
function Mediator:getChannel(channelNamespaces)
  local channel = self.channel

  for _, namespace in ipairs(channelNamespaces) do
    channel = channel:getChannel(namespace)
  end

  return channel
end



--- Subscribes to a channel.
-- @tparam array channelNamespaces The namespace-array of the channel to subscribe to (created if it doesn't exist).
-- @tparam function fn The callback function to be called when the channel is published to.
-- signature: `continueSignal, result = fn([ctx,] ...)` where `result` is any value to be stored in the result
-- table and passed back to the publisher. `continueSignal` is a signal to the mediator to stop or continue
-- calling the next subscriber, should be `mediator.STOP` or `mediator.CONTINUE` (default).
-- @tparam table options A table of options for the subscriber, with fields:
-- @tparam[opt] function options.ctx The context to call the subscriber with, will be omitted from the callback if `nil`.
-- @tparam[opt] function options.predicate A function that returns a boolean. If `true`, the subscriber will be called.
-- The predicate function will be passed the ctx + the arguments that were passed to the publish function.
-- @tparam[opt] integer options.priority The priority of the subscriber. The lower the number,
-- the higher the priority. Defaults to after all existing handlers.
-- @treturn Subscriber the newly created subscriber
function Mediator:addSubscriber(channelNamespaces, fn, options)
  return self:getChannel(channelNamespaces):addSubscriber(fn, options)
end



--- Publishes to a channel (and its parents).
-- @tparam array channelNamespaces The namespace-array of the channel to publish to (created if it doesn't exist).
-- @param ... The arguments to pass to the subscribers.
-- @treturn table The result table after all subscribers have been called.
-- @usage
-- local m = require("mediator")()
-- m:publish({"car", "engine", "rpm"}, 1000, "rpm")
--
-- -- a more efficient way would be to keep the channel and directly publish to it:
-- local channel = m:getChannel({"car", "engine", "rpm"})
-- channel:publish(1000, "rpm")
function Mediator:publish(channelNamespaces, ...)
  return self:getChannel(channelNamespaces):publish(...)
end



--- Stops the mediator from calling the next subscriber.
-- @field STOP
-- @usage
-- local sub = mediator:addSubscriber({"channel"}, function()
--   result_data = {}
--   return mediator.STOP, result_data
-- end)
Mediator.STOP = STOP



--- Lets the mediator continue calling the next subscriber.
-- This is the default value if nothing is returned from a subscriber callback.
-- @field CONTINUE
-- @usage
-- local sub = mediator:addSubscriber({"channel"}, function()
--   result_data = {}
--   return mediator.CONTINUE, result_data
-- end)
Mediator.CONTINUE = CONTINUE



return Mediator
