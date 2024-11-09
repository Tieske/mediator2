mediator\_lua
===========

Version 1.1.2

For more information, please see

[View the project on Github](https://github.com/Tieske/mediator2)

If you have [luarocks](https://luarocks.org), install it with `luarocks install mediator2`.

A utility class to help you manage events.
------------------------------------------

mediator\_lua is a simple class that allows you to listen to events by subscribing to
and sending data to channels. Its purpose is to help you decouple code where you
might otherwise have functions calling functions calling functions, and instead
simply call

```lua
mediator.publish( { "chat" }, { message = "hi" })
```

Why?
----

My specific use case: manage HTTP routes called in OpenResty. There's an excellent
article that talks about the Mediator pattern (in Javascript) in more in detail by
[Addy Osmani](https://addyosmani.com/largescalejavascript/#mediatorpattern)
(that made me go back and refactor this code a bit.)

Usage
-----

You can register events with the mediator two ways: using channels, or with a
*predicate* to perform more complex matching (a predicate is a function that
returns a true/false value that determines if mediator should run the callback.)

Instantiate a new mediator, and then you can be subscribing, removing, and publishing.

Example:

```lua
local Mediator = require "mediator2"
local mediator = Mediator() -- instantiate a new mediator

local subscriber = mediator:subscribe(
  { "chat", "Lua", "mediator" },  -- the namespace
  function(...) print(...) end,   -- the callback
)

mediator:publish(
  { "chat", "Lua", "mediator" },  -- channel to publish to
  "hello", "from", "Lua"          -- data to publish
)

-->> prints "hello from lua"

mediator:removeSubscriber(subscriber.id, { "chat", "Lua", "mediator" } )
```

Subscription callback signature:

```lua
local result, continue = function(...)
```
Where:

- `result` is a result passed back to the publisher (any type)
- `continue` determines whether any additional callbacks will be called

Callback execution order (if `continue` remains truthy over the chain) is to
first call the handlers for the channel, and then traverse up to the parent channel
and call its handlers, all the way up.

The options accepted by a subscription:
```lua
{
  predicate = function(arg1, arg2) return arg1 == arg2 end
  priority = 1|2|... (array index; max of callback array length, min of 1)
}
```

When you call `subscribe`, you get a `subscriber` object back that you can use to
update and change options. It looks like:


```lua
{
  id, -- unique identifier
  fn, -- function you passed in
  options, -- options
  channel, -- provides a pointer back to its channel
  update(options) -- function that accepts { fn, options }
}
```

Examples:


```lua
Mediator = require("mediator2")
local mediator = Mediator()

-- Print data when the "message" channel is published to
-- Subscribe returns a "Subscriber" object
mediator:subscribe({ "message" }, function(data) print(data) end);
mediator:publish({ "message" }, "Hello, world");

  >> Hello, world

-- Print the message when the predicate function returns true
local predicate = function(data)
  return data.From == "Jack"
end

mediator.Subscribe({ "channel" }, function(data) print(data.Message) end, { predicate = predicate });
mediator.Publish({ "channel" }, { Message = "Hey!", From = "Jack" })
mediator.Publish({ "channel" }, { Message = "Hey!", From = "Drew" })

  >> Hey!
```

You can remove events by passing in a type or predicate, and optionally the
function to remove.


```lua
-- removes all methods bound to a channel
mediator:remove({ "channel" })

-- unregisters MethodFN, a named function we defined elsewhere, from "channel"
mediator:remove({ "channel" }, MethodFN)
```

You can call the registered functions with the `publish` method, which accepts
an args array:


```lua
mediator:publish({ "channel" }, "argument", "another one", { etc: true }); # args go on forever
```

You can namespace your subscribing / removing / publishing. This will recurisevely
call children, and also subscribers to direct parents.


```lua
mediator:subscribe({ "application:chat:receiveMessage" }, function(data){ ... })

-- will recursively call anything in the appllication:chat:receiveMessage namespace
-- will also call thins directly subscribed to application and application:chat,
-- but not their children
mediator:publish({ "application", "chat", "receiveMessage" }, "Jack Lawson", "Hey")

-- will recursively remove everything under application:chat
mediator:remove({ "application", "chat" })
```

You can update Subscriber priority:


```lua
local sub = mediator:subscribe({ "application", "chat" }, function(data){ ... })
local sub2 = mediator:subscribe({ "application", "chat" }, function(data){ ... })

-- have sub2 executed first
mediator.GetChannel({ "application", "chat" }).SetPriority(sub2.id, 0);
```

You can update Subscriber callback, and/or options:


```lua
sub:update({ fn: ..., options = { ... }})
```

You can stop the chain of execution by calling channel:stopPropagation()


```lua
-- for example, let's not post the message if the `from` and `to` are the same
mediator.Subscribe({ "application", "chat" }, function(data, channel)
  -- throw an error message or something
  channel:stopPropagation()
end, options = {
  predicate = function(data) return data.From == data.To end,
  priority = 0
})
```


Testing
-------

Uses [busted](https://lunarmodules.github.io/busted/) for testing, and
[luacheck](https://github.com/lunarmodules/luacheck) for linting; you can install both
through [luarocks](https://luarocks.org).

Contributing
------------

Build stuff, run the tests, then submit a pull request with comments and a
description of what you've done, and why.

License
-------
This code and its accompanying README and are
[MIT licensed](https://www.opensource.org/licenses/mit-license.php).


In Closing
----------
Have fun, and please submit suggestions and improvements! You can leave any
issues here, or contact me on Twitter (@ajacksified).
