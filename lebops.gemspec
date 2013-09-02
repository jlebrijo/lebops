# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lebops/version'

Gem::Specification.new do |spec|
  spec.name          = "lebops"
  spec.version       = Lebops::VERSION
  spec.authors       = ["Juan Lebrijo"]
  spec.email         = ["juan@lebrijo.com"]
  spec.description   = %q{Rake and Capistrano tasks particular for Lebrijo.com servers}
  spec.summary       = %q{Gem for Lebrijo.com Deployment}
  spec.homepage      = "http://www.lebrijo.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "capistrano"
  spec.add_runtime_dependency "rvm-capistrano"

end
