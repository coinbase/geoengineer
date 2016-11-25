require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:default) do |t|
end

desc 'Generate documentation'
begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', '-', 'docs/*.md']
    t.options = ['--main', 'README.md', '-o', './docs', '--asset', './assets']
  end
rescue LoadError
  task :yard do puts "Please install yard first!"; end
end
