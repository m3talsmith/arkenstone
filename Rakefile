require 'rake/testtask'

task :build do
  system "gem build arkenstone.gemspec"
end


Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'test/test_associations'
  puts t.libs
end

desc "Run tests"
task :default => :test
