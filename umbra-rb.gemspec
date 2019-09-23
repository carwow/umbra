# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'umbra/version'

Gem::Specification.new do |spec|
  spec.name          = 'umbra-rb'
  spec.version       = Umbra::VERSION
  spec.authors       = ['carwow Developers']
  spec.email         = ['developers@carwow.co.uk']

  spec.summary       = 'A shadow requesting library for rack based applications'
  spec.homepage      = 'https://github.com/carwow/umbra'
  spec.license       = 'MIT'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'carwow_rubocop'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_dependency 'multi_json', '~> 1.13'
  spec.add_dependency 'oj', '~> 3.9'
  spec.add_dependency 'redis', '~> 4.1'
  spec.add_dependency 'typhoeus', '~> 1.3'
end
