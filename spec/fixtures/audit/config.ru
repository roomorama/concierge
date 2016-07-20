# +Audit supplier server+
#
# This is the mock API server for `Audit` supplier
#
# Usage
#
#   bash$ rackup spec/fixtures/audit/config.ru
#   [2016-07-12 10:44:29] INFO  WEBrick 1.3.1
#   [2016-07-12 10:44:29] INFO  ruby 2.3.0 (2015-12-25) [x86_64-darwin14]
#   [2016-07-12 10:44:29] INFO  WEBrick::HTTPServer#start: pid=92594 port=9292
#
#
# To get successful response, request for
# - http://localhost:9292/spec/fixtures/audit/quotation.success.json
# - http://localhost:9292/spec/fixtures/audit/booking.success.json
# - http://localhost:9292/spec/fixtures/audit/cancel.success.json
#
# To get a connection timeout (sleeps Concierge::HTTPClient::CONNECTION_TIMEOUT + 1 second),
# replace `success` with `connection_timeout`, e.g.
# - http://localhost:9292/spec/fixtures/audit/quotation.connection_timeout.json
#
# To get an invalid json response, replace `success` with `invalid_json` or `wrong_json`, e.g.
# - http://localhost:9292/spec/fixtures/audit/quotation.wrong_json.json

require 'rack'

require_relative '../../../lib/concierge/http_client.rb'
class FileNotFoundHandler
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

use FileNotFoundHandler
use Rack::Static, :urls => ['/spec']

run -> (env) {
  path = Dir['spec/fixtures/audit/*'].sample
  [200, {'Content-Type' => 'text/html'}, ["Try <a href='#{path}'>#{path}</a> instead"]]
}
