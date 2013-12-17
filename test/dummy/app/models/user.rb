class User
  include Arkenstone::Document

  url 'http://example.com/users/'
  attributes :name, :age, :gender, :bearded
end
