$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'total_recall'
require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.color = true
  config.tty = true
end
