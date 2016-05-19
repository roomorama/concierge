require_relative "../../../lib/concierge/json"
require_relative "../../../lib/concierge/version"

module API
  module Middlewares

    # +API::Middlewares::HealthCheck+
    #
    # Implements a simple endpoint for health checking, skipping authentication
    # requirements enforced in all other endpoints.
    #
    # Requests coming to the +/_ping+ endpoint will always return a +200+ success
    # status, with a small JSON response with the current timestamp.
    class HealthCheck
      include Concierge::JSON

      attr_reader :app, :env

      HEALTH_CHECK_PATH = "/_ping"

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env

        if health_check?
          response = {
            status:  "ok",
            app:     "api",
            time:    Time.now.strftime("%Y-%m-%d %T %Z"),
            version: Concierge::VERSION
          }

          [200, { "Content-Type" => "application/json" }, [json_encode(response)]]
        else
          app.call(env)
        end
      end

      private

      def health_check?
        request_path == [namespace, HEALTH_CHECK_PATH].join
      end

      # in development mode, all apps are loaded, and the URLs are namespaced.
      # This accounts for that behaviour, making sure that the middleware works
      # as expected on all environments.
      def namespace
        case Hanami.env
        when "development"
          "/api"
        else
          ""
        end
      end

      def request_path
        env["REQUEST_PATH"] || env["PATH_INFO"]
      end

      def query_string
        env["QUERY_STRING"]
      end

    end
  end

end
