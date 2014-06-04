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
  gem.homepage      = "https://github.com/eval/total_recall"
  gem.license       = "MIT"

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'thor', '~> 0.19'
  gem.add_dependency 'terminal-table', '~> 1.4'
  gem.add_dependency 'highline', '~> 1.6'
  gem.add_dependency 'mustache', '~> 0.99'
  gem.add_development_dependency "bundler", "~> 1.6"
  gem.add_development_dependency "rake"
  gem.add_development_dependency 'rspec', '~> 3.0.0'
  gem.add_development_dependency 'fakefs'
end
