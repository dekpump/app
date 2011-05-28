version = File.read(File.expand_path("../../SPREE_VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_sample'
  s.version     = version
  s.summary     = 'Sample data (including images) for use with Spree.'
  s.description = 'Required dependancy for Spree'

  s.required_ruby_version = '>= 1.8.7'
  s.author      = 'Sean Schofield'
  s.email       = 'sean@railsdog.com'
  s.homepage    = 'http://spreecommerce.com'
  s.rubyforge_project = 'spree_sample'

  s.files        = Dir['LICENSE', 'README.md', 'lib/**/*', 'db/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = true

  s.add_dependency('spree_core', version)
end
