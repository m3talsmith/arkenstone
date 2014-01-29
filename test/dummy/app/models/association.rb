require_relative 'user'

class Thing
  include Arkenstone::Document
  include Arkenstone::Timestamps

  url 'http://example.com/things'
  attributes :id, :name
end

class Role
  include Arkenstone::Document
  include Arkenstone::Timestamps
  attributes :id, :name
end

class Resource
  include Arkenstone::Document
  include Arkenstone::Timestamps
  attributes :id, :name
end

class AssociatedUser < User
  url 'http://example.com/associated_users/'

  has_many :things
  has_many :roles
  has_one :resource

end
