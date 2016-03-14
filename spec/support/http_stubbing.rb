module Support

  # +Support::HTTPStubbing+
  #
  # HTTP stubbing method helpers for network related specs.
  module HTTPStubbing

    def self.included(base)
      base.class_eval do
        # reset stubs on every example.
        before do |example|
          @_stubs = nil
        end
      end
    end

    # this method will stub a given HTTP call and respond according
    # to the block passed to it.
    #
    # Example
    #
    #   stub_call(:get, "https://www.roomorama.com/users") { [200, {}, "OK"] }
    #
    # The block passed is expected to return a Rack-style response.
    def stub_call(http_method, url, options = {})
      uri = URI(url)
      endpoint = [uri.scheme, "://", uri.host].join
      path = uri.path

      stubs.public_send(http_method, path) { yield }

      conn = Faraday.new(url: endpoint) do |f|
        f.adapter :test, stubs
      end

      API::Support::HTTPClient._connection = conn
    end

    # reuse stubs across different calls so that previous stubs are not lost.
    def stubs
      @_stubs ||= Faraday::Adapter::Test::Stubs.new
    end
  end

end
