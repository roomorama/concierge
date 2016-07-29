require "logger"
require_relative "../../../lib/concierge/request_logger"

module Web
  module Middlewares

    # +Web::Middlewares::RequestLogging+
    #
    # Tiny Rack middleware to implement request logging, a feature missing
    # in the currently used Hanami version. Leverages +Concierge::RequestLogger+
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
            query:        query_string,
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

      def query_string
        env["QUERY_STRING"]
      end

      def request_body
        env["rack.input"].read.tap do
          env["rack.input"].rewind
        end
      end

      def request_logger
        @logger ||= Concierge::RequestLogger.new(logger)
      end

      def logger
        output = Hanami.root.join("log", [Hanami.env, "_web.log"].join).to_s
        ::Logger.new(output)
      end

    end
  end

end
