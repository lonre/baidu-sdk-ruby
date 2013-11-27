# encoding: UTF-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baidu/version'

Gem::Specification.new do |spec|
  spec.name          = "baidu-sdk"
  spec.version       = Baidu::VERSION
  spec.authors       = ["Lonre Wang"]
  spec.email         = ["me@wanglong.me"]
  spec.description   = %q{Unofficial Baidu REST api sdk for ruby, including OAuth, PCS, etc.}
  spec.summary       = %q{Unofficial Baidu REST API SDK for Ruby.}
  spec.homepage      = "https://github.com/lonre/baidu-sdk-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency     "multipart-post", "~> 1.2"
  spec.add_development_dependency "bundler", "~> 1.3"
end
