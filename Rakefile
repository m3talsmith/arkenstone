# frozen_string_literal: true

if RUBY_VERSION.split('.')
               .first.to_i < 3
  abort 'Arkenstone development requires Ruby >= 3.0.2. ' \
        'Please upgrade to a newer version of Ruby'
end
require 'rake/testtask'
require './lib/arkenstone/version'

task :build do
  system 'gem build arkenstone.gemspec'
end

task package: :build do
  system "gem push arkenstone-open-#{Arkenstone::VERSION}.gem"
end

task :analyze do
  system 'rubocop -A'
  system 'flog -g lib'
end

task :docs do
  system 'yard doc'
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'test/test_associations'
  t.verbose = false
  t.warning = false
end

desc 'Run tests'
task default: :test
