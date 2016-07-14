require_relative "cache/entry"
require_relative "cache/entry_repository"
require_relative "cache/storage"
require_relative "cache/serializers"

module Concierge

  # +Concierge::Cache+
  #
  # This class performs caching of operations on Concierge on a key-value basis.
  # Example
  #
  #   cache = Concierge::Cache.new
  #   cache.fetch(namespace: "supplier.key") do
  #     # some expensive computation
  #   end
  #
  # Cache keys can also be namespaced for easier identification. Note that this is
  # genereally advisable, since cache keys are supposed to be unique across all
  # callers.
  #
  #   cache = Concierge::Cache.new(namespace: "supplier.quotation")
  #   cache.fetch("key") { # computation }
  #   # => fetched key will be "supplier.quotation.key"
  #
  # By default, all cache keys and values are persisted in a PostgreSQL table
  # (+cache_entries+). +Concierge::Cache::Entry+ entities wrap records from
  # the cache.
  #
  # Cache behaviour can be monitored by subscribing to +Concierge::Announcer+
  # events. Supported events are:
  #
  # * +Concierge::Cache::CACHE_HIT+
  # Triggered when there is a cache lookup hit. Parameters passed:
  #   * +key+   - the key that was looked up.
  #   * +value+ - the cached result associated with the key.
  #   * +type+  - the content type of the cached value. Supported types are only +text+ and +json+.
  #
  # * +Concierge::Cache::CACHE_MISS+
  # Triggered when a cache lookup fails and the result needs to be calculated. Parameters:
  #   * +key+ - the key that was looked up.
  class Cache

    # by default, cached entries have a living time of 1 hour.
    DEFAULT_TTL = 60 * 60

    attr_reader :namespace, :storage

    # +Concierge::Cache::ResultObjectExpectedError+
    #
    # Raised when a +Result+ instance was expected from a caching call, but an
    # instance of a different type was returned.
    #
    # Useful for tracking places where the developer mistakenly returns a non-Result
    # object from a +fetch+ call.
    class ResultObjectExpectedError < StandardError
      def initialize(object)
        super("Expected Result object, received #{object.class.name}")
      end
    end

    # events published through +Concierge::Announcer+.
    CACHE_HIT  = "cache.hit"
    CACHE_MISS = "cache.miss"

    def initialize(namespace: nil, storage: Storage.new)
      @namespace = namespace
      @storage   = storage
    end

    # tries to load the cached result with the given +key+. If it does not exist,
    # the given block is ran and the result of it is saved on the cache.
    #
    # The block given to this method **must** return an instance of +Result+. In case
    # it is not, this method will raise a +Concierge::Cache::ResultObjectExpectedError+
    # exception.
    #
    # If the +Result+ object returned by the block indicates a failure, nothing is
    # saved to the cache.
    #
    # Returns a result that:
    #
    # * when there is a cache hit, wraps the cached content.
    # * when there is a cache miss, returns the result returned by the block itself.
    #
    # Example
    #
    #   cache = Concierge::Cache.new(namespace: "supplier")
    #   cache.fetch("expensive_operation") do
    #     # some expensive computation
    #     Result.new(payload)
    #   end
    #
    #   # => #<Result error=nil value=payload>
    #
    # There is also support for customised levels of cache freshness. By default,
    # if no argument is given, a value from the cache is considered fresh
    # if it was updated less than an hour before. More granular control over
    # the definition of freshness can be obtained by passing a +freshness+
    # parameter to this method. This is the maximum number of seconds that
    # an entry should have been last updated in order for it to be considered
    # fresh.
    #
    # Example
    #
    #   cache = Concierge::Cache.new(namespace: "supplier")
    #   four_hours = 4 * 60 * 60
    #   cache.fetch("expensive_operation", freshness: four_hours) do
    #     # some expensive computation
    #   end
    #
    # Serialization: by default, the value wrapped in the +Result+ instance
    # to be returned by the block passed to this method is serialized to a
    # string (using +to_s+) before persisting the content. However, it might
    # be useful to have different kinds of serializers for different data
    # strucutures. Available serializers are:
    #
    # * Concierge::Cache::Serializers::JSON
    # This serializer transforms the wrapped result into a valid JSON string
    # before storing the value into the cache. Similarly, when a value is
    # read from the cache, this serializer decodes the content back to
    # a +Hash+ instance.
    #
    # Apart from the default serializers, a custom serializer can be
    # passed to this method using the +serializer+ option. Custom
    # implementations need to implement two methods:
    #
    # * encode(value) - transforms a given value to the serialized data
    #                   to be kept in the cache storage.
    # * decode(value) - receives an encoded version of the content (according
    #                   to the +encode+ implementation) and returns a
    #                   +Result+ instance that wraps the decoded content.
    #
    # Example:
    #
    #   class IntegerSerializer
    #     def encode(value)
    #       value.to_s
    #     end
    #
    #     def decode(value)
    #       Result.new(Integer(value))
    #     rescue ArgumentError
    #       Result.error(:invalid_number_representation)
    #     end
    #   end
    #
    #   cache = Concierge::Cache.new
    #   cache.fetch("key", serializer: IntegerSerializer.new) do
    #     1 + 1
    #   end
    #   # => #<Result value=2 ...>
    def fetch(key, freshness: DEFAULT_TTL, serializer: text_serializer)
      full_key = namespaced(key)
      entry    = storage.read(full_key)

      if entry && fresh?(entry, freshness)
        decoded = serializer.decode(entry.value)
        announce_cache_hit(full_key, decoded.value, serializer)

        return decoded
      else
        announce_cache_miss(full_key)
      end

      result = yield
      ensure_result!(result)

      if result.success?
        encoded = serializer.encode(result.value)
        storage.write(full_key, encoded)

        # go through the process of encoding and decoding before returning to
        # make sure the return of this method is consistent whether we are
        # loading from the cache or not.
        serializer.decode(encoded)
      else
        result
      end
    end

    # Invalidates a cache +key+ given. If a computation is performed afterwards
    # using the same key, it will be run again.
    #
    # The given +key+ will be properly namespaced with the namespace given on this
    # class' initialization, if any.
    def invalidate(key)
      full_key = namespaced(key)
      storage.delete(full_key)
    end

    private

    def fresh?(entry, freshness)
      now           = Time.now.to_i
      entry_updated = entry.updated_at.to_i

      (now - entry_updated) < freshness
    end

    def namespaced(key)
      if namespace
        [namespace, key].join(".")
      else
        key.to_s
      end
    end

    def text_serializer
      Serializers::Text.new
    end

    def announce_cache_hit(key, value, serializer)
      Concierge::Announcer.trigger(CACHE_HIT, key, value, serializer.content_type)
    end

    def announce_cache_miss(key)
      Concierge::Announcer.trigger(CACHE_MISS, key)
    end

    def ensure_result!(object)
      unless object.is_a?(Result)
        raise ResultObjectExpectedError.new(object)
      end
    end

  end
end
