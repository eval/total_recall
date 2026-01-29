# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "total_recall"
require "fakefs/spec_helpers"

RSpec.configure do |config|
  config.color = true
  config.tty = true
end
