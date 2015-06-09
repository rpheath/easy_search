# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'easy_search/version'

Gem::Specification.new do |spec|
  spec.name          = "easy_search"
  spec.version       = EasySearch::VERSION
  spec.authors       = ["Ryan Heath"]
  spec.email         = ["ryan@rpheath.com"]

  spec.summary       = %q{A small DSL for simple searches.}
  spec.description   = %q{A small Ruby library that provides a DSL for simple LIKE searches.}
  spec.homepage      = "http://www.github.com/rpheath/easy_search"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 0"
end
