require 'hanami/helpers'
require 'hanami/assets'
require_relative "middlewares/health_check"
require_relative "middlewares/request_logging"
require_relative "middlewares/authentication"
require_relative "middlewares/roomorama_webhook"
require_relative "middlewares/request_context"

module API
  class << self

    # the +context+ variable on the +API+ module holds the current request
    # context. It is initialized to an instance of +Concierge::Context+ at
    # the +API::Middlewares::RequestContext+ middleware and from there, the
    # context is augmented as the request is processed.
    #
    # See the documentation of the +Concierge::Context+ class for more
    # information, as well as usages of this variable throughout the +api+
    # app to understand how it fits the request lifecycle.
    attr_accessor :context
  end

  # initializes +API.context+ to a new instance on boot so that the context
  # is explorable on console sessions, as well as during test execution.
  API.context = Concierge::Context.new

  class Application < Hanami::Application
    configure do
      root __dir__

      load_paths << [
        'support',
        'controllers',
        'views',
        'use_cases',
        'suppliers'
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
