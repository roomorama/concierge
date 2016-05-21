class Concierge::Context

  # +Concierge::Context::IncomingRequest+
  #
  # This class represents the event of a request coming to Concierge.
  # It captures relevant data of the incoming request leveraging
  # +Concierge::Context::NetworkRequest+.
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
  class IncomingRequest

    CONTEXT_TYPE = "incoming_request"

    attr_reader :network_request

    def initialize(method:, path:, query_string:, headers:, body:)
      @network_request = NetworkRequest.new(
        method:       method,
        url:          path,
        query_string: query_string,
        headers:      headers,
        body:         body
      )
    end

    # wraps the underlying +Concierge::Context::NetworkRequest+ object,
    # renaming the +url+ field to +path+ and also changing the event
    # +type+.
    def to_h
      network_request.to_h.tap do |attrs|
        attrs[:type] = CONTEXT_TYPE
        attrs[:path] = attrs.delete(:url)
      end
    end

  end

end
