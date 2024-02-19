require 'active_support/all'
require 'rack/unreloader'
require 'sinatra'

Unreloader = Rack::Unreloader.new{Sinatra::Application}
Unreloader.require './server.rb'
run Unreloader

