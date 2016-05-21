class Concierge::Context

  # +Concierge::Context::NetworkRequest+
  #
  # This class represents the event of a network request
  # being performed by Concierge.  It captures relevant data
  # of the request and allows future analyses to inspect
  # the parameters passed to the request.
  #
  # Usage
  #
  #   request = Concierge::Context::NetworkRequest.new(
  #     method:       "post",
  #     url:          "https://maps.googleapis.com/geocode/json",
  #     query_string: "address=115%20Amoy%20St.",
  #     headers: {
  #       "Connection"   => "keep-alive",
  #       "Content-Type" => "application/json"
  #     },
  #     body: "{ \"key\": \"value\" }"
  #   )
  #
  # All named parameters on initialization are required. This class conforms to
  # the expected protocol of Concierge events, responding to the +to_h+ method,
  # producing a serialized version of the data given.
  class NetworkRequest

    # This is the content of events of the +type+ field of the event
    # registering network requests.
    CONTEXT_TYPE = "network_request"

    attr_reader :http_method, :url, :headers, :body

    def initialize(method:, url:, query_string:, headers:, body:)
      @http_method = method
      @url         = build_url(url, query_string)
      @headers     = headers
      @body        = body
    end

    def to_h
      {
        type:        CONTEXT_TYPE,
        http_method: http_method.upcase,
        url:         url,
        headers:     headers,
        body:        body
      }
    end

    private

    def build_url(url, query_string)
      if query_string.to_s.empty?
        url
      else
        [url, "?", query_string].join
      end
    end

  end

end
