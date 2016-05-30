class Concierge::Context

  # +Concierge::Context::CacheMiss+
  #
  # This class represents the event of a cache lookup miss
  # performed by Concierge.
  #
  # Usage
  #
  #   request = Concierge::Context::CacheMiss.new(
  #     key: "supplier.response",
  #   )
  class CacheMiss

    CONTEXT_TYPE = "cache_miss"

    attr_reader :key, :timestamp

    def initialize(key:)
      @key       = key
      @timestamp = Time.now
    end

    def to_h
      {
        type:      CONTEXT_TYPE,
        timestamp: timestamp,
        key:       key,
      }
    end

  end

end
