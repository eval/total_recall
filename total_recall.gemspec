# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'total_recall/version'

Gem::Specification.new do |gem|
  gem.name          = "total_recall"
  gem.version       = TotalRecall::VERSION
  gem.authors       = ["Gert Goet"]
  gem.email         = ["gert@thinkcreate.nl"]
  gem.description   = %q{Turn any csv into a Ledger journal}
  gem.summary       = %q{Turn any csv into a Ledger journal}
  gem.homepage      = "https://gitlab.com/eval/total_recall/tree/master#totalrecall-"
  gem.license       = "MIT"

  gem.files         = `git ls-files -z`.split("\x0")
  gem.bindir        = "exe"
  gem.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'thor', '~> 0.19'
  gem.add_dependency 'terminal-table', '~> 1.7'
  gem.add_dependency 'highline', '~> 1.7'
  gem.add_dependency 'mustache', '~> 1.0'
  gem.add_development_dependency 'bundler', '~> 1.11'
  gem.add_development_dependency 'rake', '~> 12.0'
  gem.add_development_dependency 'rspec', '~> 3.4'
  gem.add_development_dependency 'fakefs', '~> 0.10'
end
