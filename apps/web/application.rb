require 'hanami/helpers'
require 'hanami/assets'

module Web
  class Application < Hanami::Application
    configure do
      root __dir__

      load_paths << [
        "controllers",
        "views"
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
      security.content_security_policy "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self'; font-src 'self';"

      controller.prepare do
        # include MyAuthentication # included in all the actions
        # before :authenticate!    # run an authentication before callback
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

    configure :production do
      scheme 'https'
      host   'example.org'
      port   443

      assets do
        compile false
        digest  true
      end
    end
  end
end
