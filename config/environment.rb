require 'rubygems'
require 'bundler/setup'
require 'hanami/setup'
require_relative '../lib/concierge'
require_relative '../apps/api/application'

Hanami::Container.configure do
  mount API::Application, at: '/'
end
