module Concierge
  class Cache

    # +Concierge::Cache::EntryRepository+
    #
    # Persistence operations and queries of the `cache_entries` table.
    class EntryRepository
      include Hanami::Repository

      # returns the total number of cached entries stored in the database.
      def self.count
        query.count
      end

      # returns the most recently updated +Concierge::Cache::Entry+ instance.
      # If the table is empty, this method returns +nil+.
      def self.most_recent
        scope = query { reverse_order(:updated_at).limit(1) }
        scope.to_a.first
      end

      # returns the a +Concierge::Cache::Entry+ instance with the given +key+.
      # If no such element is found, this returns +nil+.
      def self.by_key(key)
        scope = query { where(key: key) }
        scope.to_a.first
      end
    end

  end
end
