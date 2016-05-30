class Concierge::Context

  # +Concierge::Context::CacheHit+
  #
  # This class represents the event of a cache lookup hit
  # performed by Concierge. It captures the relevant data
  # of the lookup, so that even if network calls are not
  # performed, it is possible to analyse the manipulated data.
  #
  # Usage
  #
  #   request = Concierge::Context::CacheHit.new(
  #     key:       "supplier.response",
  #     value:     "{ \"version\": \"1.2\" }",
  #     content_type: "json"
  #   )
  class CacheHit

    CONTEXT_TYPE = "cache_hit"

    attr_reader :key, :value, :content_type, :timestamp

    def initialize(key:, value:, content_type:)
      @key          = key
      @value        = value
      @content_type = content_type
      @timestamp    = Time.now
    end

    def to_h
      {
        type:         CONTEXT_TYPE,
        timestamp:    timestamp,
        key:          key,
        value:        value,
        content_type: content_type
      }
    end

  end

end
