module API
  module Middlewares

    # +API::Middlewares::Authentication+
    #
    # Provides a simple authentication layer for Concierge.
    #
    # The Concierge API was primarily designed to be a hub for Roomorama's webhooks.
    # It implements a number of operations on behalf of suppliers, allowing all
    # all instant booking properties to run according to the webhooks flow.
    #
    # However, for security reasons, this application must not respond to any request.
    # Fortunately, the Webhooks functionality on Roomorama already supports some form
    # of request identification via the +Content-Signature+ HTTP header sent on every
    # request. This class implements a verification that the content on that header exists
    # and is valid, allowing us to ensure that the content comes from Roomorama and
    # was not modified along the way.
    #
    # This class will halt with an HTTP status +403+ if any of the folllowing is true:
    #
    # * the request method is not +POST+.
    # * there is no +Content-Type+ HTTP header.
    # * the signature does not match the payload.
    #
    # In case all of the above meet the expectations, the request is accepted and
    # processed. Exception to this rule are endpoints listed on the +WHITELIST+ constant,
    # where the same endpoint is reused across suppliers, and therefore no signature can
    # be enforced on them (since the secret changes per supplier.) Such endpoints should
    # be few and do no significant work.
    #
    # Note that each supplier partner has a different +Client Application+ on Roomorama.
    # That means that each supplier has its own secret, which makes sure that a supplier's
    # secret is only valid on operations on its own properties.
    class Authentication

      # +API::Middlewares::Authentication::Secrets+
      #
      # Internal class to manage the retrieval of application secrets for different
      # suppliers. The recognition of partner is performed using a URL matching
      # approach, since that is what is possible at this layer.
      #
      # Usage
      #
      #   secrets = API::Middlewares::Authentication::Secrets.new
      #   request_path = "/kigo/quote"
      #   secrets.for(request_path) # => X32842I
      class Secrets
        APP_SECRETS = {
          "/jtb"            => ENV["ROOMORAMA_SECRET_JTB"],
          "/kigo/legacy"    => ENV["ROOMORAMA_SECRET_KIGO_LEGACY"],
          "/kigo"           => ENV["ROOMORAMA_SECRET_KIGO"],
          "/atleisure"      => ENV["ROOMORAMA_SECRET_ATLEISURE"],
          "/poplidays"      => ENV["ROOMORAMA_SECRET_POPLIDAYS"],
          "/waytostay"      => ENV["ROOMORAMA_SECRET_WAYTOSTAY"],
          "/ciirus"         => ENV["ROOMORAMA_SECRET_CIIRUS"],
          "/saw"            => ENV["ROOMORAMA_SECRET_SAW"],
          "/rentals_united" => ENV["ROOMORAMA_SECRET_RENTALS_UNITED"]
        }

        attr_reader :mapping

        def initialize(mapping = APP_SECRETS)
          @mapping = mapping
        end

        # Returns the associated secret for a given request +path+ or +nil+
        # in case the path is not recognised.
        def for(path)
          mapping.each do |prefix, secret|
            if path.start_with?(prefix)
              return secret
            end
          end

          nil
        end
      end

      attr_reader :app, :secrets

      HTTP_METHOD         = "POST"
      SIGNATURE_HEADER    = "HTTP_CONTENT_SIGNATURE"
      CONTENT_TYPE_HEADER = "CONTENT_TYPE"
      WHITELIST           = %w(/checkout)
      REQUIRED_HEADERS    = [SIGNATURE_HEADER, CONTENT_TYPE_HEADER]

      def initialize(app, secrets = Secrets.new)
        @app     = app
        @secrets = secrets
      end

      def call(env)
        valid_webhook = http_post?(env) && headers_present?(env) && valid_signature?(env)
        valid_request = valid_non_webhook_request?(env)

        if valid_webhook || valid_request
          app.call(env)
        else
          [403, {}, ["Forbidden"]]
        end
      end

      private

      def http_post?(env)
        env["REQUEST_METHOD"] == HTTP_METHOD
      end

      def headers_present?(env)
        REQUIRED_HEADERS.each do |header|
          return false if env[header].to_s.empty?
        end

        true
      end

      def valid_signature?(env)
        request_body = read_request_body(env)

        return true if whitelisted?(request_path(env))

        valid_request_body = request_body && !request_body.empty?
        secret             = secrets.for(request_path(env))
        expected_signature = sign(request_body, secret: secret) if secret
        signatures_match   = (env[SIGNATURE_HEADER] == expected_signature)

        valid_request_body && secret && signatures_match
      end

      def request_path(env)
        env["PATH_INFO"] || env["REQUEST_PATH"]
      end

      def whitelisted?(path)
        WHITELIST.include?(path)
      end

      def valid_non_webhook_request?(env)
        expected_signature = sign(request_path(env), secret: ENV["CONCIERGE_API_SECRET"])
        env[SIGNATURE_HEADER] == expected_signature
       end

      # +env["rack.input"]+ is a IO-like object. According to the Rack spec,
      # it must respond to +read+ and +rewind+ methods without throwing errors.
      # This reads the response body and makes it available for the upstream
      # application.
      def read_request_body(env)
        env["rack.input"].read.tap do
          env["rack.input"].rewind
        end
      end

      # This is the same method used when signing a request in Roomorama's Webhooks.
      def sign(content, secret:)
        encoded = Base64.encode64(content)
        digest  = OpenSSL::Digest.new("sha1")
        OpenSSL::HMAC.hexdigest(digest, secret, encoded)
      end

    end
  end

end
