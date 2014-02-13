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

    stub_request(:post, BrewMaster::Tag.arkenstone_url + '/').to_return(status: '200', body: {id: 1}.to_json)
    stub_request(:post, BrewMaster::Beer.arkenstone_url + '/').to_return(status: '200', body: {id: 1}.to_json)
    
    %w(blonde pale ipa hot sour).each do |tag|
      BrewMaster::Tag.create(name: tag)
    end

    beer = BrewMaster::Beer.create(brand: 'Full Sail', filtered: false)

    binding.pry
    stub_request(:post, BrewMaster::Tag.arkenstone_url + '/query').with(body: {}).to_return(status: '200', body: {id: 1}.to_json)

    tag  = BrewMaster::Tag.query(name: 'ipa').first

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
