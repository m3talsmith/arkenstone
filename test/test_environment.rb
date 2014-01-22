require 'spec_helper'

class ArkenstoneEnvTest < Test::Unit::TestCase
  def test_env_takes_hash_to_init
    result = Arkenstone::Environment.new url: 'http://example.com', verb: :GET
    assert(result.url == 'http://example.com')
    assert(result.verb == :GET)
  end
end
