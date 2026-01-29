# frozen_string_literal: true

require_relative "lib/total_recall/version"

Gem::Specification.new do |spec|
  spec.name = "total_recall"
  spec.version = TotalRecall::VERSION
  spec.authors = ["Gert Goet"]
  spec.email = ["gert@thinkcreate.nl"]

  spec.summary = "Turn any csv into a Ledger journal"
  spec.description = "Turn any csv into a Ledger journal"
  spec.homepage = "https://github.com/eval/total_recall"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eval/total_recall"
  spec.metadata["changelog_uri"] = "https://github.com/eval/total_recall/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile tmp/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "csv"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "terminal-table", "~> 3.0"
  spec.add_dependency "highline", "~> 3.0"
  spec.add_dependency "mustache", "~> 1.0"
end
