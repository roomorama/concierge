require 'hanami/helpers'
require 'hanami/assets'

module API
  class Application < Hanami::Application
    configure do
      root __dir__

      load_paths << [
        'support',
        'controllers',
        'views',
        'use_cases'
      ]

      routes 'config/routes'
      scheme 'https'

      cookies false

      default_request_format :json
      default_response_format :json
      body_parsers :json

      layout false

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

    configure :production do
      handle_exceptions true

      scheme 'https'
      host   'concierge.roomorama.com'
      port   443
    end
  end
end
