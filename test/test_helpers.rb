require 'spec_helper'

class HelpersTest < Test::Unit::TestCase
  def test_full_url
    eval %(
      class FooTest
        include Arkenstone::Document
        include Arkenstone::Helpers

        url 'http://example.com'
      end
    )

    assert_equal('http://example.com/', FooTest.full_url(FooTest.arkenstone_url))
  end
end
