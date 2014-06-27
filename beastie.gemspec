# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'beastie/version'

Gem::Specification.new do |spec|
  spec.name          = "beastie"
  spec.version       = Beastie::VERSION
  spec.authors       = ["Adolfo Villafiorita"]
  spec.email         = ["adolfo.villafiorita@me.com"]
  spec.description   = %q{A command-line issue and bug tracking system}
  spec.summary       = %q{A command-line issue and bug tracking system which uses a file per bug, yaml for data storage and it is not opinionated about versioning system, workflows, fieldsets, etc.  Useful for small and personal projects when high formality is not required.}
  spec.homepage      = "https://github.com/avillafiorita/beastie"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "mercenary", "~> 0.3"
end
