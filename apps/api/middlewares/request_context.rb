require_relative "../../../lib/concierge/context"
require_relative "../../../lib/concierge/context/incoming_request"

module API
  module Middlewares

    # +API::Middlewares::RequestContext+
    #
    # This middleware is responsible for initializing the request context to a new
    # +Concierge::Context+ instance, so that events that within this request are
    # properly stored and reported.
    class RequestContext

      attr_reader :app, :env

      def initialize(app)
        @app = app
      end

      # initializes the request context, adds information about the current,
      # incoming request, and forwards the request upstream.
      def call(env)
        @env  = env

        initialize_environment
        augment_environment

        app.call(env)
      end

      private

      def initialize_environment
        API.context = Concierge::Context.new
      end

      def augment_environment
        incoming_request = Concierge::Context::IncomingRequest.new(
          method:       http_method,
          path:         request_path,
          query_string: query_string,
          headers:      request_headers,
          body:         request_body
        )

        API.context.augment(incoming_request)
      end

      def http_method
        env["REQUEST_METHOD"].upcase
      end

      def request_path
        env["REQUEST_PATH"] || env["PATH_INFO"]
      end

      def query_string
        env["QUERY_STRING"]
      end

      # Rack presents HTTP headers of the incoming request as entries with keys
      # starting with the +HTTP_+ prefix in the +env+.
      #
      # This method scans the environment looking for entries that match that
      # criteria, and transforms the name to the conventional, capitalised notation,
      # instead of the full-caps representation used by default in the +env+ hash.
      #
      # Example
      #
      #   # env
      #   {
      #     "SERVER" => "unicorn",
      #     "HTTP_CONNECTION" => "keep-alive",
      #     "HTTP_CONTENT_TYPE" => "aplication/json",
      #     "SCRIPT_NAME" => ""
      #     # ...
      #   }
      #
      #   # results in =>
      #   { "Connection" => "keep-alive", "Content-Type" => "application/json" }
      def request_headers
        headers = env.select { |name, _| name.start_with?("HTTP_") }

        Hash[headers.map { |header, value|
          [header.sub(/^HTTP_/, "").split("_").map(&:capitalize).join("-"), value]
        }]
      end

      def request_body
        env["rack.input"].read.tap do
          env["rack.input"].rewind
        end
      end

      def request_logger
        @logger ||= Concierge::RequestLogger.new
      end

    end
  end

end
