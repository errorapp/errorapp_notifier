# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'errorapp_notifier/version'

Gem::Specification.new do |spec|
  spec.name          = "errorapp_notifier"
  spec.version       = ErrorappNotifier::VERSION
  spec.authors       = ["Rashmi"]
  spec.email         = ["rays.rashmi@gmail.com"]
  spec.description   = %q{ Notifier for sending errors to ErrorApp }
  spec.summary       = %q{ ErrorApp is a webapp for monitoring exceptions and other failures in your live applications. }
  spec.homepage      = "http://errorapp.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "actionpack", "~> 3.2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "2.14"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "json"

  spec.add_dependency "rack"
end
