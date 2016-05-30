class Concierge::Context

  # +Concierge::Context::NetworkResponse+
  #
  # This class wraps the data to be collected when a response is retrieved back
  # from an external service (most often, a supplier API.) It gathers the HTTP
  # status of the response, its headers and response body.
  #
  # Usage
  #
  #   response = Concierge::Context::NetworkResponse.new(
  #     status: "200",
  #     headers: {
  #       "Content-Type"   => "application/xml",
  #       "Content-Length" => 20,
  #     },
  #     body: "<status>OK</status>"
  #   )
  class NetworkResponse

    CONTEXT_TYPE = "network_response"

    attr_reader :status, :headers, :body, :timestamp

    def initialize(status:, headers:, body:)
      @status    = status
      @headers   = headers
      @body      = body
      @timestamp = Time.now
    end

    def to_h
      {
        type:      CONTEXT_TYPE,
        timestamp: timestamp,
        status:    status,
        headers:   headers,
        body:      body
      }
    end

  end

end
