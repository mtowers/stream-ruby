# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stream/version'

Gem::Specification.new do |gem|
  gem.required_ruby_version = '~>2.2'

  gem.name          = "realself-stream"
  gem.version       = RealSelf::Stream::VERSION
  gem.authors       = ["Matt Towers"]
  gem.email         = ["matt@realself.com"]
  gem.description   = "Standard classes for interacting with RealSelf activity stream services"
  gem.summary       = ""
  gem.homepage      = "https://github.com/RealSelf/stream-ruby"
  gem.license       = "(c) #{Time.now.year} RealSelf, Inc. All Rights Reserved"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "bunny"
  gem.add_dependency "connection_pool", '2.2.0'
  gem.add_dependency "json-schema"
  gem.add_dependency "multi_json"
  gem.add_dependency "httparty"
  gem.add_dependency "rake", "~> 10.0"
  gem.add_dependency "rspec"

  gem.add_development_dependency "mongo", '2.2.0'
  gem.add_development_dependency "pry-byebug"
  gem.add_development_dependency "sneakers", '2.2.1'
end
