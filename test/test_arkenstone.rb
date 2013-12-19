require 'spec_helper'

class ArkenstoneTest < Test::Unit::TestCase

  # A Little psuedo coding here:
  # class User
  #   include Arkenstone::Document
  #
  #   url 'http://example.com/users/'
  #   attributes :name, :age, :gender, :bearded
  # end
  #
  # user = User.create({name: 'John Doe', age: 18, gender: 'Male', bearded: true}) 
  # curl -x GET 'http://example.com/users'
  # user.save # curl -x POST -d name='John Doe' -d 'etc=...' 'http://example.com/users'
  #
  # Returns
  #   header
  #     status: 200
  #   body
  #     {
  #       user: {
  #         id: 1,
  #         name: 'John Doe',
  #         age: 18,
  #         gender: 'Male',
  #         bearded: true
  #       },
  #       message: 'King under the mountain'
  #     }
  
  def test_arkenstone_url_set
    eval %(
      class ArkenstoneUrlTest
        include Arkenstone::Document
        url 'http://example.com'
      end
    )

    assert(ArkenstoneUrlTest)
    assert(ArkenstoneUrlTest.arkenstone_url == 'http://example.com')
  end

  def test_arkenstone_attributes_set
    eval %(
      class ArkenstoneAttributesTest
        include Arkenstone::Document
        attributes :name, :age
      end
    )
    arkenstone = ArkenstoneAttributesTest.new

    assert(ArkenstoneAttributesTest.arkenstone_attributes == [:name, :age])
    assert(arkenstone.respond_to?(:name))
    assert(arkenstone.respond_to?(:age))
  end

  def test_builds_from_params
    user = User.build(user_options)
    assert(user.class == User, "user class was not User")
    assert(user.age == 18, "user's age was not 18")
  end
  
  def test_creates
    user = User.create(user_options)
    assert(user.age == 18, "user's age was not 18")
    assert(user.id == 1, "user doesn't have an id")
    assert(user.created_at, "created_at is nil")
    assert(user.updated_at, "updated_at is nil")
  end

  def test_returns_to_json
    user = User.build(user_options)
    assert(user.to_json, 'user#to_json method does not exist')
    assert(user.arkenstone_json, 'user#arkenstone_json method does not exist')
    # puts "\n\n#{user.to_json}"
    assert(user.to_json == user.arkenstone_json, 'does not match json')
  end

  def test_creates_instances_from_json
  end
end

def user_options
  {name: 'John Doe', age: 18, gender: 'Male', bearded: true}
end
