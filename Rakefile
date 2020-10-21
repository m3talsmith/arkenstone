abort 'Arkesnstone development requires Ruby >= 2.7.1. '\
      'Please upgrade to a newer version of Ruby' if RUBY_VERSION.split('.')
                                                     .first.to_i < 2
require 'rake/testtask'
require './lib/arkenstone/version'

task :build do
  system 'gem build arkenstone.gemspec'
end

task :package do
  system "gem push --key github --host https://rubygems.pkg.github.com/m3talsmith arkenstone-#{Arkenstone::VERSION}.gem"
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'test/test_associations'
end

desc 'Run tests'
task :default => :test
