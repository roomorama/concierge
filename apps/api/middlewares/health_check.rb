require_relative "../../../lib/concierge/request_logger"
require_relative "../../../lib/concierge/json"

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
            status: "ok",
            time: Time.now.strftime("%Y-%m-%d %T %Z")
          }

          request_logger.log(
            http_method:  env["REQUEST_METHOD"],
            status:       200,
            path:         HEALTH_CHECK_PATH,
            time:         0,
            request_body: ""
          )

          [200, { "Content-Type" => "application/json" }, [json_encode(response)]]
        else
          app.call(env)
        end
      end

      private

      def health_check?
        request_path == HEALTH_CHECK_PATH
      end

      def request_path
        env["REQUEST_PATH"] || env["PATH_INFO"]
      end

      def request_logger
        @logger ||= Concierge::RequestLogger.new
      end

    end
  end

end
