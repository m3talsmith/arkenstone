# frozen_string_literal: true

require 'spec_helper'

class DocumentOverridesTest < Test::Unit::TestCase
  def test_reload_override
    eval %(
      class Brand
        include Arkenstone::Document

        url 'http://example.com/brands'
        attributes :name
        has_many :balls
      end

      class Ball
        include Arkenstone::Document

        attributes :color
        belongs_to :brand
      end
    )

    stub_request(:post, Brand.arkenstone_url + '/').to_return(status: '200', body: { id: 1, name: 'Foo' }.to_json)
    stub_request(:get, Brand.arkenstone_url + '/1/balls').to_return(status: 200, body: [].to_json)

    brand = Brand.create(name: 'Foo')
    assert(!brand.arkenstone_data[:balls])

    stub_request(:post, Brand.arkenstone_url + '/1/balls/').to_return(status: '200', body: { id: 1, color: 'blue', brand_id: brand.id }.to_json)

    ball = brand.balls.create(color: 'blue')
    assert(brand.arkenstone_data[:balls])

    stub_request(:get, Ball.arkenstone_url + '/1').to_return(status: 200, body: { id: 1, color: 'blue', brand_id: brand.id }.to_json)
    ball.reload

    assert(ball.color == 'blue')

    found_ball = Ball.find(ball.id)
    assert(found_ball.color == 'blue')
    assert_equal(ball.to_json, found_ball.to_json)
  end
end
