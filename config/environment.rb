require "rubygems"
require "bundler/setup"
require "hanami/setup"
require_relative "../lib/concierge"

apps = {
  api: %w(api),
  web: %w(web),
  all: %w(api web)
}

unless apps.keys.include?(Concierge.app)
  raise RuntimeError.new("Unknown CONCIERGE_APP: #{Concierge.app}")
end

apps[Concierge.app].each { |app| require_relative "../apps/#{app}/application" }

Hanami::Container.configure do
  case Concierge.app
  when :api
    mount API::Application, at: "/"
  when :web
    mount Web::Application, at: "/"
  when :all
    mount API::Application, at: "/api"
    mount Web::Application, at: "/web"
  end
end
