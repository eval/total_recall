require "rubygems"
require "bundler"
Bundler.setup

$:.unshift File.expand_path("../../lib", __FILE__)
require "total_recall"

# fullpath to csv-file
def fixture_pathname(str)
  Pathname(%W(spec fixtures #{str}.csv).join(File::SEPARATOR)).realpath
end

def fixture_contents(str)
  File.read(fixture_pathname(str))
end
