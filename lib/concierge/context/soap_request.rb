class Concierge::Context

  # +Concierge::Context::SOAPRequest+
  #
  # This class represents the event of a SOAP request
  # being performed by Concierge. It captures the endpoint,
  # SOAP operation and message being sent.
  #
  # Usage
  #
  #   request = Concierge::Context::SOAPRequest.new(
  #     endpoint:  "https://maps.googleapis.com/geocode/json",
  #     operation: "gby010",
  #     payload:   "<xml>content</xml>"
  #   )
  class SOAPRequest

    CONTEXT_TYPE = "soap_request"

    attr_reader :endpoint, :operation, :payload, :timestamp

    def initialize(endpoint:, operation:, payload:)
      @endpoint  = endpoint
      @operation = operation
      @payload   = payload
      @timestamp = Time.now
    end

    def to_h
      {
        type:      CONTEXT_TYPE,
        timestamp: timestamp,
        endpoint:  endpoint,
        operation: operation,
        payload:   payload
      }
    end

  end

end
