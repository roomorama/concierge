class Concierge::Context

  # +Concierge::Context::SOAPResponse+
  #
  # Thin wrapper for +Concierge::Context::SOAPResponse+ for responses
  # of SOAP requests.
  class SOAPResponse

    CONTEXT_TYPE = "soap_response"

    attr_reader :response, :timestamp

    def initialize(status:, headers:, body:)
      @response = Concierge::Context::NetworkResponse.new(
        status:  status,
        headers: headers,
        body:    body
      )
    end

    def to_h
      response.to_h.merge!(type: CONTEXT_TYPE)
    end

  end

end
