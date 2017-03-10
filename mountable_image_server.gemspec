# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mountable_image_server/version'

Gem::Specification.new do |spec|
  spec.name          = "mountable_image_server"
  spec.version       = MountableImageServer::VERSION
  spec.authors       = ["David Strauß"]
  spec.email         = ["david@strauss.io"]

  spec.summary       = %q{Simple mountable server for processing images on the fly.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/stravid/mountable_image_server"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rack-test", "~> 0.6.3"

  spec.add_runtime_dependency "sinatra", "~> 2.0.0.beta2"
  spec.add_runtime_dependency "dry-configurable", "~> 0.1.6"
  spec.add_runtime_dependency "skeptick", "~> 0.2.1"
end
