abort 'Arkesnstone development requires Ruby >= 2.7.1. '\
      'Please upgrade to a newer version of Ruby' if RUBY_VERSION.split('.')
                                                     .first.to_i < 2
require 'rake/testtask'

task :build do
  system 'gem build arkenstone.gemspec'
end


Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'test/test_associations'
end

desc 'Run tests'
task :default => :test
