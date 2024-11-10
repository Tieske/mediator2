describe("mediator", function()
  local Mediator
  local m, c, testfn, testfn2, testfn3

  before_each(function()
    Mediator = require("mediator2")
    m = Mediator()
    c = m:getChannel({"test"}) -- creates the channel, by looking it up
    testfn = function() end
    testfn2 = function() end
    testfn3 = function() end
  end)

  after_each(function()
    m = nil
    c = nil
    testfn = nil
    testfn2 = nil
    testfn3 = nil
  end)

  it("can register subscribers", function()
    c:addSubscriber(testfn)

    assert.are.equal(#c.subscribers, 1)
    assert.are.equal(c.subscribers[1].fn, testfn)
  end)

  it("can register lots of subscribers", function()
    c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    assert.are.equal(#c.subscribers, 2)
    assert.are.equal(c.subscribers[2].fn, sub2.fn)
  end)

  it("can register subscribers with specified priorities", function()
    c:addSubscriber(testfn)
    c:addSubscriber(testfn2)
    local sub3 = c:addSubscriber(testfn3, { priority = 1 })

    assert.are.equal(c.subscribers[1].fn, sub3.fn)
  end)

  it("can change subscriber priority forward after being added", function()
    c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    sub2:setPriority(1)

    assert.are.equal(c.subscribers[1], sub2)
  end)

  it("can change subscriber priority backwards after being added", function()
    local sub1 = c:addSubscriber(testfn)
    c:addSubscriber(testfn2)

    sub1:setPriority(2)

    assert.are.equal(c.subscribers[2], sub1)
  end)

  it("can change subscriber priority through subscriber", function()
    local sub1 = c:addSubscriber(testfn)
    c:addSubscriber(testfn2)

    sub1:update { options = { priority = 2 } }
    assert.are.equal(c.subscribers[2], sub1)
    assert.is_nil(sub1. options.priority) -- must be cleared
  end)

  it("keeps subscriber priority within bounds upon change", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)
    assert.are.equal(c.subscribers[1], sub1)
    assert.are.equal(c.subscribers[2], sub2)

    sub1:setPriority(99)
    assert.are.equal(c.subscribers[2], sub1)
    assert.are.equal(c.subscribers[1], sub2)

    sub1:setPriority(0)
    assert.are.equal(c.subscribers[1], sub1)
    assert.are.equal(c.subscribers[2], sub2)
  end)

  it("can add subchannels", function()
    c:addChannel("level2")
    assert.are_not.equal(c.channels["level2"], nil)
  end)

  it("returns existing subchannel if it exists", function()
    local c1 = c:addChannel("level2")
    local c2 = c:addChannel("level2")
    assert.are.equal(c1, c2)
  end)

  it("can check if a subchannel has been added", function()
    c:addChannel("level2")
    assert.is.truthy(c:hasChannel("level2"), true)
  end)

  it("can return channels", function()
    c:addChannel("level2")
    assert.is_not.equal(c:getChannel("level2"), nil)
  end)

  it("can remove subscribers", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    sub2:remove()

    assert.is.equal(c.subscribers[1], sub1)
    assert.is.equal(c.subscribers[2], nil)
  end)

  it("can publish to a channel", function()
    local olddata = { test = false }
    local data = { test = true }

    local assertFn = function(data)
      olddata = data
    end

    c:addSubscriber(assertFn)
    c:publish(data)

    assert.is.truthy(olddata.test)
  end)

  it("ignores if you publish to a nonexistant subchannel", function()
    local data = { test = true }
    assert.is_not.error(function() m:publish({ "nope" }, data) end)
  end)

  it("ignores if you publish to a nonexistant subchannel with subchannels", function()
    local data = { test = true }
    assert.is_not.error(function() m:publish({ "nope", "wat" }, data) end)
  end)

  it("sends all the publish arguments to subscribers", function()
    local data = { test = true }
    local arguments

    local assertFn = function(data, wat, seven)
      arguments = { data, wat, seven }
    end

    c:addSubscriber(assertFn)
    c:publish({}, "test", data, "wat", "seven")

    assert.are.equal(#arguments, 3)
  end)

  it("can stop propagation", function()
    local olddata = { test = 0 }
    local data = { test = 1 }
    local data2 = { test = 2 }

    local assertFn = function(data)
      olddata = data
      return m.STOP
    end

    local assertFn2 = function(data)
      olddata = data2
    end

    c:addSubscriber(assertFn)
    c:addSubscriber(assertFn2)

    c:publish(data)

    assert.are.equal(olddata.test, 1)
  end)

  it("fails if propagation is neither STOP nor CONTINUE", function()
    local function assertFn(data)
      return "wat"
    end

    c:addSubscriber(assertFn)

    assert.is.error(function() c:publish({}) end)
  end)

  it("publishes to parent channels", function()
    local olddata = { test = false }
    local data = { test = true }

    local assertFn = function(...)
      olddata = data
    end

    c:addChannel("level2")

    c.channels["level2"]:addSubscriber(assertFn)

    c.channels["level2"]:publish({}, data)

    assert.is.truthy(olddata.test)
  end)

  it("can return a channel from the mediator level", function()
    assert.is_not.equal(m:getChannel({"test", "level2"}), nil)
    assert.are.equal(m:getChannel({"test", "level2"}), m:getChannel({"test"}):getChannel("level2"))
  end)

  it("can publish to channels from the mediator level", function()
    local received
    local assertFn = function(data) received = data end

    m:subscribe({"test"}, assertFn)
    m:publish({"test"}, "hi")
    assert.are.equal(received, "hi")
  end)

  it("publishes to the proper subchannel", function()
    local a = spy.new(function() end)
    local b = spy.new(function() end)

    m:subscribe({ "request", "a" }, a)
    m:subscribe({ "request", "b" }, b)

    m:publish({ "request", "a" })
    m:publish({ "request", "b" })

    assert.spy(a).was.called(1)
    assert.spy(b).was.called(1)
  end)

  it("can publish to a subscriber at the mediator level", function()
    local olddata = "wat"

    local assertFn = function(data)
      olddata = data
    end

    m:subscribe({"test"}, assertFn)
    m:publish({ "test" }, "hi")

    assert.are.equal(olddata, "hi")
  end)

  it("can publish a subscriber to all parents at the mediator level", function()
    local olddata = "wat"
    local olddata2 = "watwat"

    local assertFn = function(data)
      olddata = data
      return nil, true
    end

    local assertFn2 = function(data)
      olddata2 = data
      return nil, true
    end

    c:addChannel("level2")

    m:subscribe({ "test", "level2" }, assertFn)
    m:subscribe({ "test" }, assertFn2)

    m:publish({ "test", "level2" }, "didn't read lol")

    assert.are.equal(olddata, "didn't read lol")
    assert.are.equal(olddata2, "didn't read lol")
  end)

  it("has predicates", function()
    local olddata = "wat"
    local olddata2 = "watwat"

    local assertFn = function(data)
      olddata = data
    end

    local assertFn2 = function(data)
      olddata2 = data
    end

    local predicate = function()
      return false
    end

    c:addChannel("level2")

    m:subscribe({"test","level2"}, assertFn)
    m:subscribe({"test"}, assertFn2, { predicate = predicate })

    m:publish({"test", "level2"}, "didn't read lol")

    assert.are.equal(olddata, "didn't read lol")
    assert.are_not.equal(olddata2, "didn't read lol")
  end)

  it("passes the ctx to the subscriber callback", function()
    local ctx = nil
    local assertFn = function(c, data)
      ctx = c
    end

    c:addSubscriber(assertFn, { ctx = "wat" })
    c:publish({})

    assert.are.equal("wat", ctx)
  end)

  it("passes 'false' as a valid ctx to the subscriber callback", function()
    local ctx = nil
    local assertFn = function(c, data)
      ctx = c
      assert.are.equal("wat", data)
    end

    c:addSubscriber(assertFn, { ctx = false })
    c:publish("wat")

    assert.are.equal(false, ctx)
  end)

  it("can pass self as context for object-based handlers", function()
    local myObject = {
      last_noise = nil,
    }
    function myObject:makeNoise(noise)
      self.last_noise = noise
    end

    c:addSubscriber(myObject.makeNoise, { ctx = myObject })
    c:publish("meow")

    assert.are.equal("meow", myObject.last_noise)
  end)
end)
