# frozen_string_literal: true

require 'minitest/autorun'
require 'webmock/test_unit'

# Add in some pry debuggin niceties
require 'pry'
require 'pry-nav'

# Include code coverage
require 'simplecov'
SimpleCov.start

# Make a simple document for test cases.
require_relative '../lib/arkenstone.rb'
Dir['./test/dummy/app/models/**/*.rb'].sort.each { |f| require f }
