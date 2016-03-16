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
    # processed.
    class Authentication
      attr_reader :app

      HTTP_METHOD         = "POST"
      SIGNATURE_HEADER    = "HTTP_CONTENT_SIGNATURE"
      CONTENT_TYPE_HEADER = "CONTENT_TYPE"
      REQUIRED_HEADERS    = [SIGNATURE_HEADER, CONTENT_TYPE_HEADER]

      def initialize(app)
        @app = app
      end

      def call(env)
        valid_webhook = http_post?(env) && headers_present?(env) && valid_signature?(env)

        if valid_webhook
          app.call(env)
        else
          [403, {}, "Forbidden"]
        end
      end

      private

      def http_post?(env)
        env["REQUEST_METHOD"] == "POST"
      end

      def headers_present?(env)
        REQUIRED_HEADERS.each do |header|
          return false if env[header].to_s.empty?
        end

        true
      end

      def valid_signature?(env)
        request_body = env["rack.input"].read
        env[SIGNATURE_HEADER] == sign(request_body, secret: credentials.secret.to_s)
      end

      # This is the same method used when signing a request in Roomorama's Webhooks.
      def sign(content, secret:)
        encoded = Base64.encode64(content)
        digest  = OpenSSL::Digest.new("sha1")
        OpenSSL::HMAC.hexdigest(digest, secret, encoded)
      end

      def credentials
        @credentials ||= Concierge::Credentials.for("roomorama_webhooks")
      end
    end
  end

end
