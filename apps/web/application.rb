require 'hanami/helpers'
require 'hanami/assets'

module Web
  class Application < Hanami::Application
    configure do
      root __dir__

      load_paths << [
        'controllers',
        'views'
      ]

      routes 'config/routes'
      scheme 'https'

      # URI host used by the routing system to generate absolute URLs
      # Defaults to "localhost"
      #
      # host 'example.org'

      cookies false

      default_request_format :json
      default_response_format :json
      body_parsers :json

      layout false

      # X-Frame-Options is a HTTP header supported by modern browsers.
      # It determines if a web page can or cannot be included via <frame> and
      # <iframe> tags by untrusted domains.
      #
      # Web applications can send this header to prevent Clickjacking attacks.
      security.x_frame_options "DENY"

      view.prepare do
        include Hanami::Helpers
        include Web::Assets::Helpers

        include Web::Views::AcceptJSON
      end
    end

    configure :development do
      handle_exceptions false
    end

    configure :test do
      handle_exceptions false
    end

    configure :production do
      scheme 'https'
      host   'concierge.roomorama.com'
      port   443
    end
  end
end
