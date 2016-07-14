class Concierge::Context

  # +Concierge::Context::CacheInvalidation+
  #
  # This class represents the event of a cache key being invalidated from
  # the cache
  #
  # Usage
  #
  #   request = Concierge::Context::CacheInvalidation.new(
  #     key: "supplier.response",
  #   )
  class CacheInvalidation

    CONTEXT_TYPE = "cache_invalidation"

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
