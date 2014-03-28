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

  def test_associations_dont_clobber_existing_methods
    AssociatedUser.add_association_method 'test_method' do
      'replaced'
    end
    model = AssociatedUser.new
    assert(model.test_method == 'on AssociatedUser')
    #model = UserWithMethods.new
    #assert(model.things == 'on UserWithMethods')
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

  def test_associations_uses_the_same_namespace
    eval %(
      module Foo
        class Bar
          include Arkenstone::Document
        end

        class MyClass
          include Arkenstone::Document
          url "http://example.com/myclasses/"

          attributes :id, :name

          has_many :bars
        end
      end
    )
    stub_request(:get, "#{Foo::MyClass.arkenstone_url}100/bars").to_return(body: '')
    model = Foo::MyClass.new
    model.id = 100
    result = model.bars
    assert(result != nil)
  end

  def test_assoications_handles_405
    eval %(
      module Foo
        class Bar
          include Arkenstone::Document
        end

        class MyClass
          include Arkenstone::Document
          url "http://example.com/myclasses/"

          attributes :id, :name

          has_one :bar
        end
      end
    )
    stub_request(:get, "#{Foo::MyClass.arkenstone_url}100/bar").to_return(status: '405', body: "ERROR")
    model = Foo::MyClass.new
    model.id = 100
    result = model.bar
    assert(result == [])

  end

  def test_belongs_to_association
    eval %(
      module Foo
        class Bar
          include Arkenstone::Document
          url 'http://example.com/bar'

          attributes :id
          belongs_to :freezer
        end

        class Freezer
          include Arkenstone::Document
          url 'http://example.com/freezer'
          
          attributes :id, :age
          has_many :bars
        end
      end
    )

    stub_request(:post, Foo::Freezer.arkenstone_url + '/').to_return(status: '200', body: {id: 1}.to_json)
    stub_request(:post, Foo::Bar.arkenstone_url + '/').to_return(status: '200', body: {id: 1, freezer_id: 1}.to_json)

    freezer = Foo::Freezer.create({age: 30})
    bar     = Foo::Bar.create({freezer: freezer})

    stub_request(:get, "#{Foo::Freezer.arkenstone_url}/1").to_return(status: 200, body: freezer.to_json)

    assert_equal(freezer.id, bar.freezer_id) 
    assert_equal(freezer.to_json, bar.freezer.to_json)
    assert_equal(bar.cached_freezer.id, freezer.id)
  end

   def test_has_and_belongs_to_many
     # Pending Test
     
     return true
     eval %(
       module Foo
         class Bar
           include Arkenstone::Document
           url 'http://example.com/bar'
 
           attributes :id
           has_and_belongs_to_many :freezers
         end

         class Freezer
           include Arkenstone::Document
           url 'http://example.com/freezer'

           attributes :id, :age
           has_and_belongs_to_many :bars
         end
       end
     )

     stub_request(:post, "#{Foo::Freezer.arkenstone_url}/").to_return(status: '200', body: {id: 1, bar_ids: []}.to_json)
     stub_request(:post, "#{Foo::Bar.arkenstone_url}/").to_return(status: '200', body: {id: 1, freezer_ids: [1]}.to_json)

     freezer = Foo::Freezer.create({age: 30})
     bar     = Foo::Bar.create({freezers: [freezer]})

     stub_request(:get, "#{Foo::Freezer.arkenstone_url}/1").to_return(status: 200, body: freezer.merge({bar_ids: [bar.id]}).to_json)
     stub_request(:get, "#{Foo::Bar.arkenstone_url}/1").to_return(status: 200, body: bar.merge({freezer_ids: [freezer.id]}).to_json)

     assert(bar.freezer_ids.include?(freezer.id))
     assert(freezer.bar_ids.include?(bar.id))

     freezer = Foo::Freezer.find(1)
     bar     = Foo::Bar.find(1)

     assert_equal(1, freezer.bars.length)
     assert_equal(1, bar.freezers.length)

     found_freezer = bar.freezers.first
     found_bar     = freezer.bars.first

     assert_equal(freezer.to_json, found_freezer.to_json)
     assert_equal(bar.to_json, found_bar.to_json)
   end


  def test_handles_nested_json
    eval %(
      module Foo
        class Bar
          include Arkenstone::Document
          url 'http://example.com/bar'

          attributes :id
          belongs_to :freezer
        end

        class Freezer
          include Arkenstone::Document
          url 'http://example.com/freezer'
          
          attributes :id, :age
          has_many :bars
        end
      end
    )

    stub_request(:post, Foo::Freezer.arkenstone_url + '/').to_return(status: '200', body: {id: 1}.to_json)
    stub_request(:post, Foo::Bar.arkenstone_url + '/').to_return(status: '200', body: {id: 1, freezer_id: 1}.to_json)

    freezer = Foo::Freezer.create({age: 30})
    bar     = Foo::Bar.create({freezer: freezer})

    stub_request(:get, "#{Foo::Freezer.arkenstone_url}/1").to_return(status: 200, body: {id: 1, age: 30, bars: [{id: 1}]}.to_json)
    stub_request(:get, "#{Foo::Freezer.arkenstone_url}/1/bars").to_return(status: 200, body: [{id: 1}].to_json)

    freezer = Foo::Freezer.find(freezer.id)

    assert(freezer.bars)
    assert(freezer.bar_ids)
    assert(freezer.bar_ids.include?(bar.id))
  end

  def test_allows_custom_url
    eval %(
      class Tool
        include Arkenstone::Document
        attributes :name
        url 'http://example.com/tools'
      end

      class Garage
        include Arkenstone::Document
        attributes :address
        url 'http://example.com/garages'

        has_many :tools, model_name: 'derps'
      end
    )
    stub_request(:get, "#{Garage.arkenstone_url}/10/derps").to_return(body: [{name: "test"},{name: "other"}].to_json)
    g = Garage.new
    g.id = 10
    tools = g.tools
    assert_equal(2, tools.count)
  end
end
