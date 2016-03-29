require_relative "../../../lib/concierge/request_logger"

module API
  module Middlewares

    # +API::Middlewares::RequestLogging+
    #
    # Tiny Rack middleware to implement request logging, a feature missing
    # in the currently used Hanami version. Leveragest +Concierge::RequestLogger+
    # to provide the logging functionality.
    #
    # See that class' documentation on usage instructions.
    class RequestLogging

      attr_reader :app, :env

      def initialize(app)
        @app = app
      end

      # logs the request and leaves the response untouched.
      def call(env)
        @env  = env
        start = Time.now

        app.call(env).tap do |status, *|
          elapsed = (Time.now - start).to_f

          request_logger.log(
            http_method:  http_method,
            status:       status,
            path:         request_path,
            time:         elapsed,
            request_body: request_body
          )
        end
      end

      private

      def http_method
        env["REQUEST_METHOD"].upcase
      end

      def request_path
        env["REQUEST_PATH"] || env["PATH_INFO"]
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
