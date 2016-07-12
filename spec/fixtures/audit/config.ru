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

require 'rack'

use Rack::Static, :urls => ['/spec']

run -> (env) {
  path = Dir['spec/fixtures/audit/*'].sample
  [200, {'Content-Type' => 'text/html'}, ["Try <a href='#{path}'>#{path}</a> instead"]]
}
