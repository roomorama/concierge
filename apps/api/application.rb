require 'hanami/helpers'
require_relative "middlewares/health_check"
require_relative "middlewares/request_logging"
require_relative "middlewares/authentication"
require_relative "middlewares/roomorama_webhook"
require_relative "middlewares/request_context"
require_relative "views/accept_json"

module API
  class Application < Hanami::Application
    configure do
      root __dir__

      load_paths << [
        'controllers',
        'views'
      ]

      routes 'config/routes'
      scheme 'https'

      cookies false

      default_request_format  :json
      default_response_format :json
      body_parsers            :json

      layout false

      middleware.use API::Middlewares::RequestLogging
      middleware.use API::Middlewares::HealthCheck
      middleware.use API::Middlewares::Authentication
      middleware.use API::Middlewares::RoomoramaWebhook
      middleware.use API::Middlewares::RequestContext

      view.prepare do
        include Hanami::Helpers
        include API::Views::AcceptJSON
      end
    end

    configure :development do
      handle_exceptions false
    end

    configure :test do
      handle_exceptions false
    end

    configure :staging do
      handle_exceptions true

      scheme 'https'
      host   'concierge-staging.roomorama.com'
      port   443
    end

    configure :production do
      handle_exceptions true

      scheme 'https'
      host   'concierge.roomorama.com'
      port   443
    end
  end
end
