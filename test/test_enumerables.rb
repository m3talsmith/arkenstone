# frozen_string_literal: true

require 'spec_helper'

class EnumerableTests < Test::Unit::TestCase
  def test_json_returns_attributes_of_elements
    eval %(
      class EnumerableElement
        include Arkenstone::Document

        attributes :name, :id
      end
    )
    dummy = EnumerableElement.new
    dummy.name = 'test'
    dummy.id = 100

    dummy2 = EnumerableElement.new
    dummy2.name = 'test2'
    dummy2.id = 101

    list = Arkenstone::QueryList.new [dummy, dummy2]
    result = list.to_json
    assert_equal(result, '[{"name":"test","id":100},{"name":"test2","id":101}]')
  end

  def test_initialize_takes_array
    list = Arkenstone::QueryList.new [10, 20]
    assert_equal([10, 20], list)
  end

  def test_initialize_takes_element
    list = Arkenstone::QueryList.new 'test'
    assert_equal ['test'], list
  end
end
