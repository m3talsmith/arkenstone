# frozen_string_literal: true

require 'spec_helper'

class QueryBuilderTest < Test::Unit::TestCase
  def setup
    @builder = Arkenstone::QueryBuilder.new
  end

  def test_build_find_with_one_param
    json = @builder.build do
      {
        foo: 'foo'
      }
    end

    assert_equal '{"foo":"foo"}', json
  end

  def test_build_find_in
    json = @builder.build do
      {
        foo: _in(%w[foo bar])
      }
    end
    assert_equal '{"foo":{"$in":["foo","bar"]}}', json
  end

  def test_query_find_comparison
    json = @builder.build do
      {
        foo: _gt(500)
      }
    end
    assert_equal '{"foo":{"$gt":500}}', json
  end

  def test_query_complex_find
    json = @builder.build do
      {
        foo: 'foo',
        bar: _in(%w[foo bar]),
        baz: _gt(400)
      }
    end
    assert_equal '{"foo":"foo","bar":{"$in":["foo","bar"]},"baz":{"$gt":400}}', json
  end

  def test_query_and
    json = @builder.build do
      _and(
        { foo: 'foo' },
        { bar: 'bar' }
      )
    end
    assert_equal '{"$and":[{"foo":"foo"},{"bar":"bar"}]}', json
  end

  def test_query_and_with_gt
    json = @builder.build do
      _and(
        { foo: _gt(200) },
        { foo: _lt(300) }
      )
    end
    assert_equal '{"$and":[{"foo":{"$gt":200}},{"foo":{"$lt":300}}]}', json
  end

  def test_include
    json = @builder.build do
      _include %w[Foo Bar]
      {
        foo: 'foo'
      }
    end
    assert_equal '{"$include":["Foo","Bar"],"foo":"foo"}', json
  end

  def test_limit
    json = @builder.build do
      _limit 5
      {
        foo: 'foo'
      }
    end
    assert_equal '{"$limit":5,"foo":"foo"}', json
  end

  def test_complex_include_with_booleans
    json = @builder.build do
      _include %w[DocDataElement Document]
      _or(
        _and(
          { 'DocDataElement.Name' => 'AccountNumber' },
          { 'Value' => '123456' }
        ),
        _and(
          { 'DocDataElement.Name' => 'Zip' },
          { 'Value' => '55555' }
        )
      )
    end
    assert_equal '{"$include":["DocDataElement","Document"],"$or":[{"$and":[{"DocDataElement.Name":"AccountNumber"},{"Value":"123456"}]},{"$and":[{"DocDataElement.Name":"Zip"},{"Value":"55555"}]}]}', json
  end

  def test_query_not
    json = @builder.build do
      _or(
        _and(
          { foo: _gt(200) },
          { bar: 'bar' }
        ),
        _not(
          { baz: 'derp' }
        )
      )
    end
    assert_equal '{"$or":[{"$and":[{"foo":{"$gt":200}},{"bar":"bar"}]},{"$not":[{"baz":"derp"}]}]}', json
  end

  def test_query_or
    json = @builder.build do
      _or(
        { foo: _gt(200) },
        { bar: 'bar' }
      )
    end
    assert_equal '{"$or":[{"foo":{"$gt":200}},{"bar":"bar"}]}', json
  end

  def test_query_complex_and
    json = @builder.build do
      _or(
        _and(
          { foo: _gt(200) },
          { bar: 'bar' }
        ),
        _and(
          { derp: 'derp' }
        )
      )
    end
    assert_equal '{"$or":[{"$and":[{"foo":{"$gt":200}},{"bar":"bar"}]},{"$and":[{"derp":"derp"}]}]}', json
  end

  def test_query_is_idempotent
    json = @builder.build do
      _and(
        { foo: _gt(200) },
        { bar: 'bar' }
      )
    end
    assert_equal '{"$and":[{"foo":{"$gt":200}},{"bar":"bar"}]}', json
    json = @builder.build do
      _and(
        { foo: _gt(200) },
        { derp: 'derp derp' }
      )
    end
    assert_equal '{"$and":[{"foo":{"$gt":200}},{"derp":"derp derp"}]}', json
  end
end
