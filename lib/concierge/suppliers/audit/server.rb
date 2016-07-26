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
      status, headers, body = handle_404(env) || [status, headers, body] if status == 404

      if File.basename(env['PATH_INFO']) =~ /booking/
        new_body = replace_response_body(body)
        [status, headers.merge('Content-Length' => new_body.length.to_s), [new_body]]
      else
        [status, headers, body]
      end
    end

    private

    def retry_with(env, old_string, new_string)
      @app.call(env.merge({
        'PATH_INFO' => env['PATH_INFO'].gsub(old_string, new_string),
        'REQUEST_PATH' => env['REQUEST_PATH'] && env['REQUEST_PATH'].gsub(old_string, new_string),
      }))
    end

    def handle_404(env)
      case File.basename(env['PATH_INFO'])
      when /sample/
        # sample = success
        retry_with(env, 'sample', 'success')

      when /connection_timeout/
        # First we wait
        sleep Concierge::HTTPClient::CONNECTION_TIMEOUT + 1

        # Then we return the requested info (Concierge::HTTPClient should have errored out by now)
        retry_with(env, 'connection_timeout', 'success')

      when /wrong_json/
        [200, {}, ["[1, 2, 3]"]]

      when /invalid_json/
        [200, {}, ["{"]]
      end
    end

    def replace_response_body(body)
      body_string = case body
      when Rack::File
        IO.read body.path
      else
        body.join("")
      end

      body_string.gsub("REPLACEME", [
        "success",
        "connection_timeout"
      ].sample)
    end
  end
end
