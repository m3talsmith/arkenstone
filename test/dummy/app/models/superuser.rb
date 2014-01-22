require_relative 'user'

class SuperUser < User

  url 'http://example.com/superusers'
  attributes :group_name

end
