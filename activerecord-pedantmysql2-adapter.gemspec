# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pedant_mysql2/version'

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-pedantmysql2-adapter'
  spec.version       = PedantMysql2::VERSION
  spec.authors       = ['Jean Boussier']
  spec.email         = ['jean.boussier@shopify.com']
  spec.summary       = %q{ActiveRecord adapter for MySQL that report warnings.}
  spec.description   = %q{Gives a hook on MySQL warnings that allow you to either raise or log them.}
  spec.homepage      = 'https://github.com/Shopify/activerecord-pedantmysql2-adapter'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 3.2'
  spec.add_dependency 'mysql2', '>= 0.3.12'
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'coveralls'
end
