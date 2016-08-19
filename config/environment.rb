require "rubygems"
require "bundler/setup"
require "hanami/setup"
require_relative "../lib/concierge"

apps = {
  api:     %w(api),
  web:     %w(web),
  workers: %w(workers),
  public:  %w(public),
  all:     %w(api web workers public)
}

unless apps.keys.include?(Concierge.app)
  raise RuntimeError.new("Unknown CONCIERGE_APP: #{Concierge.app}")
end

Dir["./config/initializers/*.rb"].sort.each { |f| require f }

apps[Concierge.app].each { |app| require_relative "../apps/#{app}/application" }

Hanami::Container.configure do
  case Concierge.app
  when :api
    mount API::Application, at: "/"
  when :web
    mount Web::Application, at: "/"
  when :public
    mount Public::Application, at: "/public"

  when :all
    mount API::Application, at: "/api"
    mount Web::Application, at: "/web"
    mount Public::Application, at: "/public"
  end
end
