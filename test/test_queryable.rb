# frozen_string_literal: true

require 'spec_helper'

class QueryableTests < Test::Unit::TestCase
  def test_query_url
    url = 'http://example.com/users/query'
    assert(url == User.query_url)
  end

  def test_where_with_string
    dummy_user1 = user_options(name: 'user 1')
    dummy_user2 = user_options(name: 'user 2')
    stub_request(:post, "#{User.arkenstone_url}query").to_return(body: [dummy_user1, dummy_user2].to_json)
    results = User.where '{name: "user 1"}'
    assert(results.nil? == false)
    assert(results.first.instance_of?(User))
  end

  def test_where_with_hash
    dummy_user1 = user_options(name: 'user 1')
    dummy_user2 = user_options(name: 'user 2')
    stub_request(:post, "#{User.arkenstone_url}query").with(body: { name: 'user 1' }.to_json).to_return(body: [dummy_user1, dummy_user2].to_json)
    results = User.where({ name: 'user 1' })
    assert(results.nil? == false)
    assert(results.first.instance_of?(User))
  end

  def test_where_with_block
    dummy_user1 = user_options(name: 'user 1')
    dummy_user2 = user_options(name: 'user 2')
    stub_request(:post, "#{User.arkenstone_url}query").with(body: { name: 'user 1' }).to_return(body: [dummy_user1, dummy_user2].to_json)
    results = User.where do
      {
        name: 'user 1'
      }
    end
    assert(results.nil? == false)
  end

  def test_where_nil
    result = User.where
    assert(result.nil?)
  end

  def test_where_no_results
    stub_request(:post, "#{User.arkenstone_url}query").to_return(body: [].to_json)
    result = User.where ''
    assert(result == [])
  end
end

def user_options(options = {})
  { name: 'John Doe', age: 18, gender: 'Male', bearded: true }.merge!(options)
end
