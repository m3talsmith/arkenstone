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
    
    stub_request(:post, Brand.arkenstone_url + '/').to_return(status: '200', body: {id: 1, name: 'Foo'}.to_json)
    stub_request(:get, Brand.arkenstone_url + '/1/balls').to_return(status: 200, body: [].to_json)

    brand = Brand.create(name: 'Foo')

    binding.pry
    assert(!brand.arkenstone_data['cached_balls'])

    stub_request(:post, Brand.arkenstone_url + '/1/balls').to_return(status: '200', body: {id: 1, color: 'blue'}.to_json)

    ball = brand.balls.build(color: 'blue')
    ball.save

    stub_request(:get, Ball.arkenstone_url + '/1').to_return(status: 200, body: {id: 1, color: 'orange'}.to_json)

    ball.reload
    assert(ball.color == 'orange')

    found_ball = Ball.find(ball.id)
    assert(found_ball.color == 'orange')
    brand.balls << ball
    assert(brand.balls.include?(ball))
  end
end
