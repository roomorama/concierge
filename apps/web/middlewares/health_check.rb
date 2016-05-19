require_relative "../../../lib/concierge/json"
require_relative "../../../lib/concierge/version"

module Web
  module Middlewares

    # +Web::Middlewares::HealthCheck+
    #
    # Implements a simple endpoint for health checking, necessary for the load
    # balancer to determine if the server is healthy.
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
            app:     "web",
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

      def namespace
        case Hanami.env
        when "development"
          "/web"
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
