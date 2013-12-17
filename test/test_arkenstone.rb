require 'spec_helper'

class ArkenstoneTest < Test::Unit::TestCase
  # class User
  #   include Arkenstone::Document
  #
  #   url 'http://example.com/users/'
  #   attributes :name, :age, :gender, :bearded
  # end
  #
  # user = User.create({name: 'John Doe', age: 18, gender: 'Male', bearded: true}) # curl -x GET 'http://example.com/users'
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
    options = {name: 'John Doe', age: 18, gender: 'Male', bearded: true}
    user = User.build(options)
    assert(user.class == User, "user class was not User")
    assert(user.age == 18, "user's age was not 18")
  end
  

  def test_sends_json_to_url
  end

  def test_creates_instances_from_json
  end
end
