require 'spec_helper'

class TestHook < Arkenstone::Hook
  attr_accessor :called

  def before_request(req)
    @called = true
  end
end

class BaseModel
  include Arkenstone::Document
end

class ChildModel < BaseModel
  inherit_hooks
end


class ArkenstoneHookInheritanceTest < Test::Unit::TestCase

  def test_hooks_do_inheritance
    hook = TestHook.new
    BaseModel.add_hook hook
    ChildModel.call_request_hooks nil
    assert(hook.called)
  end

  def test_inherit_hooks
    eval %(
      class ArkenstoneHookAttr
        include Arkenstone::Document
        inherit_hooks
      end
    )
    assert(ArkenstoneHookAttr.arkenstone_inherit_hooks)
  end

end
