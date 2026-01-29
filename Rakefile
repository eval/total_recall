# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

if ENV["CI"]
  # version.rb is written at CI which prevents guard_clean from passing.
  # Redefine guard_clean to make it a noop.
  Rake::Task["release:guard_clean"].clear
  task "release:guard_clean"

  # As a release is triggered by a tag, nothing should be pushed.
  Rake::Task["release:source_control_push"].clear
  task "release:source_control_push"
end
