mediator2
=========

This project is a fork of the older [`mediator_lua` project](https://github.com/Olivine-Labs/mediator_lua).
The changes are mostly for making it more Lua specific, and fix a bunch of bugs.

[View the project on Github](https://github.com/Tieske/mediator2)

If you have [luarocks](https://luarocks.org), install it with `luarocks install mediator2`.

A utility class to help you manage events.
------------------------------------------

mediator2 is a simple class that allows you to listen to events by subscribing to
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
