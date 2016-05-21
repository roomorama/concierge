class Concierge::Context

  # +Concierge::Context::IncomingRequest+
  #
  # This class represents the event of a request coming to Concierge.
  # It captures relevant data of the incoming request and allows future analysis
  # to inspect the parameters passed to the request.
  #
  # Usage
  #
  #   incoming = Concierge::Context::IncomingRequest.new(
  #     method:       "post",
  #     path:         "/jtb/quote",
  #     query_string: nil,
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
  class IncomingRequest

    # serialized contexts must have a +type+ key. This is the content of events
    # registering incoming requests.
    CONTEXT_TYPE = "incoming_request"

    attr_reader :http_method, :path, :headers, :body

    def initialize(method:, path:, query_string:, headers:, body:)
      @http_method = method
      @path        = build_path(path, query_string)
      @headers     = headers
      @body        = body
    end

    def to_h
      {
        type:        CONTEXT_TYPE,
        http_method: http_method.upcase,
        path:        path,
        headers:     headers,
        body:        body
      }
    end

    private

    def build_path(path, query_string)
      if query_string.to_s.empty?
        path
      else
        [path, "?", query_string].join
      end
    end

  end

end
