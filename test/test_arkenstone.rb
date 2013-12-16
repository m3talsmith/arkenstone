require 'spec_helper'

class ArkenstoneTest < Test::Unit::TestCase
  # class User
  #   include Arkenstone::Document
  #
  #   url 'http://example.com/users/'
  #   attributes :name, :age, :gender, :bearded
  # end
  #
  # user = User.new({name: 'John Doe', age: 18, gender: 'Male', bearded: true}) # curl -x GET 'http://example.com/users'
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
  
  def test_creates_from_params
    options = {name: 'John Doe', age: 18, gender: 'Male', bearded: true}
    user = User.new(options)
    assert(user.class == User)
    assert(user.attributes == options.merge(id: 1))
  end

  def test_sends_json_to_url
  end

  def test_creates_instances_from_json
  end
end
