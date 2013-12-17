class User
  include Arkenstone::Document
  include Arkenstone::Timestamps

  url 'http://example.com/users/'
  attributes :name, :age, :gender, :bearded
end
