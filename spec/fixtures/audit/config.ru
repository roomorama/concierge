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
require_relative '../../../lib/concierge/suppliers/audit/server.rb'

use Audit::Server
use Rack::Static, :urls => ['/spec']

run -> (env) {
  path = Dir['spec/fixtures/audit/*'].sample
  [200, {'Content-Type' => 'text/html'}, ["Try <a href='#{path}'>#{path}</a> instead"]]
}
