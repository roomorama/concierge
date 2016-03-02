module Support

  # +Support::HTTPStubbing+
  #
  # HTTP stubbing method helpers for network related specs.
  module HTTPStubbing

    # this method will stub a given HTTP call and respond according
    # to the block passed to it.
    #
    # Example
    #
    #   stub_call(:get, "https://www.roomorama.com/users") { [200, {}, "OK"] }
    #
    # The block passed is expected to return a Rack-style response.
    def stub_call(http_method, endpoint, options = {})
      stubs = Faraday::Adapter::Test::Stubs.new do |stubs|
        stubs.public_send(http_method, endpoint) { yield }
      end

      conn = Faraday.new(options) do |f|
        f.adapter :test, stubs
      end

      API::Support::HTTPClient._connection = conn
    end
  end

end
