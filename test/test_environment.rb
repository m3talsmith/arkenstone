# frozen_string_literal: true

require 'spec_helper'

class ArkenstoneEnvTest < Test::Unit::TestCase
  def setup
    @env = Arkenstone::Environment.new url: 'http://example.com', verb: :get
  end

  def test_env_takes_hash_to_init
    assert(@env.url == 'http://example.com')
    assert(@env.verb == :get)
  end
end
