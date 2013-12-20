require 'test/unit'
require 'webmock/test_unit'

#Make a simple document for test cases.
require_relative '../lib/arkenstone.rb'
Dir['./test/dummy/app/models/**/*.rb'].each { |f| require f }
