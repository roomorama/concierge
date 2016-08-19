require 'hanami/helpers'
require_relative "../api/middlewares/request_logging"
require_relative "../api/middlewares/request_context"

module Public
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

      layout false

      middleware.use API::Middlewares::RequestLogging
      middleware.use API::Middlewares::RequestContext

      view.prepare do
        include Hanami::Helpers
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
      host   'concierge-staging-public.roomorama.com'
      port   443
    end

    configure :production do
      handle_exceptions true

      scheme 'https'
      host   'concierge-public.roomorama.com'
      port   443
    end
  end
end
