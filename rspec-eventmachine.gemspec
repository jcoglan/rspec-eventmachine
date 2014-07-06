Gem::Specification.new do |s|
  s.name              = 'rspec-eventmachine'
  s.version           = '0.2.0'
  s.summary           = 'RSpec extensions for testing EventMachine code'
  s.author            = 'James Coglan'
  s.email             = 'jcoglan@gmail.com'
  s.homepage          = 'http://github.com/jcoglan/rspec-eventmachine'
  s.license           = 'MIT'

  s.extra_rdoc_files  = %w[README.md]
  s.rdoc_options      = %w[--main README.md --markup markdown]
  s.require_paths     = %w[lib]

  s.files = %w[README.md] + Dir.glob('lib/**/*.rb')

  s.add_dependency 'eventmachine', '>= 0.12.0'
  s.add_dependency 'rspec', '>= 2.0', '< 4.0'
end

