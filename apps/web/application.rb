require 'hanami/helpers'
require 'hanami/assets'
require_relative "middlewares/request_logging"
require_relative "middlewares/health_check"

module Web
  class Application < Hanami::Application
    configure do
      root __dir__

      load_paths << [
        "controllers",
        "views",
        "support"
      ]

      routes "config/routes"

      cookies true

      sessions :cookie, secret: ENV["CONCIERGE_WEB_APP_SECRET"]

      default_request_format  :html
      default_response_format :html

      layout    :application
      templates 'templates'

      assets do
        javascript_compressor :builtin
        stylesheet_compressor :builtin

        sources << [
          'assets'
        ]
      end

      security.x_frame_options "DENY"

      middleware.use Web::Middlewares::HealthCheck
      middleware.use Web::Middlewares::RequestLogging

      middleware.use Rack::Auth::Basic, "Roomorama Concierge - authentication required" do |username, password|
        Web::Support::Authentication.new(username, password).authorized?
      end

      view.prepare do
        include Hanami::Helpers
        include Web::Assets::Helpers
      end
    end

    configure :development do
      # Don't handle exceptions, render the stack trace
      handle_exceptions false
    end

    configure :test do
      # Don't handle exceptions, render the stack trace
      handle_exceptions false
    end

    configure :staging do
      handle_exceptions true

      scheme 'https'
      host   'concierge-staging-web.roomorama.com'

      assets do
        compile false
        digest  true
      end
    end

    configure :production do
      scheme 'https'
      host   'concierge-web.roomorama.com'
      port   443

      assets do
        compile false
        digest  true
      end
    end
  end
end
