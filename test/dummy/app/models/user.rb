class User
  include Arkenstone::Document
  include Arkenstone::Timestamps

  url 'http://example.com/users/'
  attributes :name, :age, :gender, :bearded
  content_type :json # don't set the content_type to use a default form based request
end
