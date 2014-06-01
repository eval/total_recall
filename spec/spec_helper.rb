require "rubygems"
require "bundler"
Bundler.setup

$:.unshift File.expand_path("../../lib", __FILE__)
require "total_recall"
require 'fakefs/spec_helpers'
