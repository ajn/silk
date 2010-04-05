require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run rdoc.'
task :default => :rdoc

desc 'Generate documentation for the silk plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Silk'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
