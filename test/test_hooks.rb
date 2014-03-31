require 'spec_helper'

class RequestHook < Arkenstone::Hook
  attr_accessor :called
  def before_request(req)
    @called = true
  end
end

class ResponseHook < Arkenstone::Hook
  attr_accessor :called
  def after_complete(resp)
    @called = true
  end
end

class ArkenstoneHookTest < Test::Unit::TestCase
  def test_hook_called_before_request
    request_hook = RequestHook.new
    User.add_hook request_hook
    assert(User.arkenstone_hooks.count == 1)
    stub_request(:get, User.arkenstone_url + '1').to_return(body: "{}")
    User.find(1)
    assert(request_hook.called, "hook was not called")
  end

  def test_hook_called_after_complete
    resp_hook = ResponseHook.new
    User.add_hook resp_hook
    stub_request(:get, User.arkenstone_url + '1').to_return(body: "{}")
    User.find(1)
    assert(resp_hook.called, "response hook was not called")
  end

  def test_has_hooks
    eval %(
      class BaseThing
        include Arkenstone::Document
        add_hook RequestHook.new
      end
    )
    assert_equal(true, Arkenstone::Hook.has_hooks?(BaseThing))
  end

  def test_has_hooks_via_inheritance
    eval %(
      class BaseThing
        include Arkenstone::Document
        add_hook RequestHook.new
      end

      class ChildThing < BaseThing
        inherit_hooks
      end

    )
    assert_equal(true, Arkenstone::Hook.has_hooks?(ChildThing))
  end

  def test_has_hooks_negative
    eval %(
      class NoHooks
      end
    )
    assert_equal(false, Arkenstone::Hook.has_hooks?(NoHooks))
  end

  def teardown
    User.arkenstone_hooks = []
  end


end
