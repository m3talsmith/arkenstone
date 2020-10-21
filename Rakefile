# frozen_string_literal: true

if RUBY_VERSION.split('.')
               .first.to_i < 2
  abort 'Arkesnstone development requires Ruby >= 2.7.1. '\
        'Please upgrade to a newer version of Ruby'
end
require 'rake/testtask'
require './lib/arkenstone/version'

task :build do
  system 'gem build arkenstone.gemspec'
end

task package: :build do
  system "gem push --key github --host https://rubygems.pkg.github.com/m3talsmith arkenstone-#{Arkenstone::VERSION}.gem"
end

task :analyze do
  system 'rubocop -A'
  system 'flog -g lib'
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'test/test_associations'
end

desc 'Run tests'
task default: :test
