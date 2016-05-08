require "rubygems"
require "bundler/setup"
require "hanami/setup"
require_relative "../lib/concierge"

apps = %w(api web)
unless apps.include?(Concierge.app)
  raise RuntimeError.new("Unknown CONCIERGE_APP: #{Concierge.app}")
end

require_relative "../apps/#{Concierge.app}/application"

Hanami::Container.configure do
  case Concierge.app
  when "api"
    mount API::Application, at: "/"
  when "web"
    mount Web::Application, at: "/"
  end
end
