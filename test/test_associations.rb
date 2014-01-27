require 'spec_helper'

class AssociationsTest < Test::Unit::TestCase
  def setup
    @model = AssociatedUser.new
    @model.id = 100
    @dummy_things = [{ "id" => 100, "name" => "test" }, { "id" => 200, "name" => "dummy data" }]

    stub_request(:get, "#{AssociatedUser.arkenstone_url}100/things").to_return do |req|
      { body: @dummy_things.to_json }
    end

    stub_request(:get, "#{AssociatedUser.arkenstone_url}100/roles").to_return(body: '')
  end

  def test_has_many_creates_child_array
    assert(AssociatedUser.method_defined? :things)
    assert(@model.things.nil? == false)
    assert(@model.things != [])
    assert(@model.things.count == 2)

    assert(@model.roles == [])
  end

  def test_has_many_creates_cached_method
    assert(AssociatedUser.method_defined? :cached_things)
    assert(@model.cached_things.count == 2)
  end

  def test_has_many_creates_add_child
    stub_request(:post, "#{AssociatedUser.arkenstone_url}100/things").to_return do |req|
      @dummy_things << {"id" => 500, "name" => "new thing"}
      { code: 200 }
    end
    assert(AssociatedUser.method_defined? :add_thing)
    new_thing = Thing.new
    new_thing.name = "new thing"
    new_thing.id = 500
    @model.add_thing new_thing
    assert(@model.cached_things.count == 3)
  end

  def test_has_many_creates_remove_child
    stub_request(:delete, "#{AssociatedUser.arkenstone_url}100/things/100").to_return do |req|
      @dummy_things = [{"id" => 200, "name" => "dummy data"}]
      { code: 200 }
    end
    
    assert(AssociatedUser.method_defined? :remove_thing)
    bad_thing = Thing.new
    bad_thing.id = 100
    @model.remove_thing bad_thing
    assert(@model.cached_things.count == 1)
    assert(@model.cached_things[0].id == 200)
  end
end
