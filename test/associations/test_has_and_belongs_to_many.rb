require 'spec_helper'

class HasAndBelongsToManyTest < Test::Unit::TestCase
  def test_has_and_belongs_to_many
    eval %(
      module BrewMaster
        class Tag
          include Arkenstone::Document
          url 'http://example.com/tag'

          attributes :id, :name
          has_and_belongs_to_many :beers
        end

        class Beer
          include Arkenstone::Document
          url 'http://example.com/beer'
          
          attributes :id, :brand, :filtered
          has_and_belongs_to_many :tags
        end
      end
    )

    assert(BrewMaster::BeerTag)
    %w(beer beer= beer_id beer_id= cached_beer tag tag= tag_id tag_id= cached_tag).each do |injected_method|
      assert(BrewMaster::BeerTag.new.respond_to?(injected_method.to_sym))
    end

    assert(BrewMaster::Tag.new.respond_to?(:beer_tags))
    assert(BrewMaster::Beer.new.respond_to?(:beer_tags))

    stub_request(:post, BrewMaster::Tag.arkenstone_url + '/').to_return(status: '200', body: {id: 1}.to_json)
    stub_request(:post, BrewMaster::Beer.arkenstone_url + '/').to_return(status: '200', body: {id: 1}.to_json)
    
    %w(blonde pale ipa hot sour).each do |tag|
      BrewMaster::Tag.create(name: tag)
    end

    beer = BrewMaster::Beer.create(brand: 'Full Sail', filtered: false)

    stub_request(:post, "#{BrewMaster::Tag.arkenstone_url}/query").with(body: {name: 'ipa'}.to_json).to_return(:body => [{id: 1, name: 'ipa'}].to_json)

    tag  = BrewMaster::Tag.where(name: 'ipa').first

    stub_request(:get, "#{BrewMaster::Tag.arkenstone_url}/1/beer_tags").to_return(status: 200, body: [].to_json)
    stub_request(:get, "#{BrewMaster::Beer.arkenstone_url}/1/beer_tags").to_return(status: 200, body: [].to_json)

    assert(beer.respond_to?(:tags))
    assert(tag.respond_to?(:beers))

    assert(beer.tags.empty?)
    assert(tag.beers.empty?)
    
    beer.tags << tag
    assert(beer.tags.include?(tag))
    assert(tag.beers.include?(beer))

    beer.reload
    tag.reload

    assert(beer.tags.include?(tag))
    assert(tag.beers.include?(beer))
  end
end
