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

    @dummy_resource = {"id" => 50, "name" => "Resource 1"}
    stub_request(:get, "#{AssociatedUser.arkenstone_url}100/resource").to_return do |req|
      if @dummy_resource.nil?
        { code: 200 }
      else
        { body: @dummy_resource.to_json }
      end
    end

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

  def test_has_one_creates_a_cached_object
    assert(AssociatedUser.method_defined? 'cached_resource')
    assert(@model.cached_resource != nil)
  end

  def test_has_one_creates_a_uncached_object
    assert(AssociatedUser.method_defined? 'resource')
    assert(@model.resource.id == 50)
  end

  def test_has_one_creates_a_setter
    new_values = { id: 75, name: "new resource" }
    stub_request(:post, "#{AssociatedUser.arkenstone_url}100/resource").to_return(body: '')

    assert(AssociatedUser.method_defined? 'resource=')
    new_resource = Resource.build new_values
    @model.resource = new_resource
    @dummy_resource = new_resource
    assert(@model.resource.id == 75)
  end

  def test_has_one_can_delete_an_association
    stub_request(:delete, "#{AssociatedUser.arkenstone_url}100/resource/50").to_return(code: 200)
    @model.resource = nil
    @dummy_resource = nil
    assert(@model.resource == nil)
  end
end
