require_relative '../../http_client'

module Audit
  # +Audit::Server+
  #
  # This class is the Audit web app.
  #
  # For more information on how to interact with Audit, check the project Wiki.
  class Server

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      if status == 404
        case File.basename(env['REQUEST_PATH'])

        when /connection_timeout/
          # First we wait
          sleep Concierge::HTTPClient::CONNECTION_TIMEOUT + 1

          # Then we return the requested info (Concierge::HTTPClient should have errored out by now)
          @app.call(env.merge({
            'PATH_INFO' => env['PATH_INFO'].gsub('connection_timeout', 'success'),
            'REQUEST_PATH' => env['REQUEST_PATH'].gsub('connection_timeout', 'success'),
          }))

        when /wrong_json/
          [200, {}, ["[1, 2, 3]"]]

        when /invalid_json/
          [200, {}, ["{"]]
        end

      end || [status, headers, body]
    end
  end
end
