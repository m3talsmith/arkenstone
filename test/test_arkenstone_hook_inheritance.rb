# frozen_string_literal: true

require 'spec_helper'

class TestHook < Arkenstone::Hook
  attr_accessor :called

  def before_request(_req)
    @called = true
  end
end

class ArkenstoneHookInheritanceTest < Test::Unit::TestCase
  def test_hooks_do_inheritance
    eval %(
      class BaseModel
        include Arkenstone::Document
      end

      class ChildModel < BaseModel
        inherit_hooks
      end
    )
    hook = TestHook.new
    BaseModel.add_hook hook
    Arkenstone::Hook.call_request_hooks ChildModel, nil
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
