class Concierge::Context

  # +Concierge::Context::JSONParsingError+
  #
  # Records events of responses that were expected to be valid JSON payloads
  # but could not be successfully parsed.
  class JSONParsingError

    CONTEXT_TYPE = "json_parsing_error"

    attr_reader :message, :timestamp

    def initialize(message:)
      @message   = message
      @timestamp = Time.now
    end

    def to_h
      {
        type:      CONTEXT_TYPE,
        timestamp: timestamp,
        message:   message
      }
    end

  end

end
