require_relative "cache/entry"
require_relative "cache/entry_repository"

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
  class Cache

    # +Concierge::Cache::Storage+
    #
    # Thin wrapper class for the PostgreSQL persistence layer. This makes it
    # easier to change the underlying cache persistence technology without
    # affecting the actual caching logic.
    #
    # It implements the expected +storage+ protocol for +Concierge::Cache+,
    # meaning:
    #
    # * read(key)
    #   This receives a +key+ (+String+) and returns a +Concierge::Cache::Entry+
    #   instance if any, or +nil+ otherwise.
    #
    # * write(key, value)
    #   Persists the +key, value+ combination in the PostgreSQL storage. Returns
    #   a +Concierge::Cache::Entry+ resulting from that.
    #
    # * delete(key)
    #   Deletes the entry associated with the given +key+. Return value: unspecified
    #   and should not be relied upon.
    class Storage

      def read(key)
        EntryRepository.by_key(key)
      end

      def write(key, value)
        entry = read(key)

        if entry
          entry.value = value
          EntryRepository.update(entry)
        else
          entry = Entry.new(key: key, value: value, updated_at: Time.now)
          EntryRepository.create(entry)
        end

        entry
      end

      def delete(key)
        entry = read(key)
        EntryRepository.delete(entry) if entry
      end

    end

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
    def fetch(key, freshness: DEFAULT_TTL)
      full_key = namespaced(key)
      entry    = storage.read(full_key)

      if entry && fresh?(entry, freshness)
        return Result.new(entry.value)
      end

      result = yield
      ensure_result!(result)

      if result.success?
        storage.write(full_key, result.value.to_s)
      end

      result
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

    def ensure_result!(object)
      unless object.is_a?(Result)
        raise ResultObjectExpectedError.new(object)
      end
    end

  end
end
