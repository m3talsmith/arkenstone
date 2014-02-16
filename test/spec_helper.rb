require 'test/unit'
require 'webmock/test_unit'

# Add in some pry debuggin niceties
require 'pry'
require 'pry-nav'

#Make a simple document for test cases.
require_relative '../lib/arkenstone.rb'
Dir['./test/dummy/app/models/**/*.rb'].each { |f| require f }
