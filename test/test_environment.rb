require 'spec_helper'

class ArkenstoneEnvTest < Test::Unit::TestCase
  def setup
    @env = Arkenstone::Environment.new url: 'http://example.com', verb: :get
  end

  def test_env_takes_hash_to_init
    assert(@env.url == 'http://example.com')
    assert(@env.verb == :get)
  end

  def test_builds_a_request
    result = @env.build_request
    assert(result.class == Net::HTTP::Get)
  end

  def test_built_request_has_body
    @env.body = 'hi'
    result = @env.build_request
    assert(result.body == 'hi')
  end

  def test_builds_a_request_with_a_proc
    @env.body = Proc.new { |req| req.body = 'derp' }
    result = @env.build_request
    assert(result.body == 'derp')
  end
end
