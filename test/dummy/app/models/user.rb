# frozen_string_literal: true

class User
  include Arkenstone::Document
  include Arkenstone::Timestamps
  include Arkenstone::Queryable

  url 'http://example.com/users/'
  attributes :name, :age, :gender, :bearded
end
