module Concierge
  class Cache

    # +Concierge::Cache::Entry+
    #
    # This entity correspond to an entry in the default storage provider for caching
    # Concierge. When a result is cached, it creates a new entry on the `cache_entries`
    # table, allowing faster access to results of expensive operations.
    #
    # Attributes:
    #
    # +id+         - a numerical, incrementing ID. No meaning on this entity.
    # +key+        - the key associated with a value. Example: +supplier.quotation.price_response+.
    # +value+      - the cached value associated with a +key+.
    # +updated_at+ - a timestamp indicating when the entry was last updated.
    class Entry
      include Hanami::Entity

      attributes :id, :key, :value, :updated_at
    end
  end
end
