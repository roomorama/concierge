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
class Concierge::Cache
  class Storage

    def read(key)
      database.with_repository { |repository| repository.by_key(key) }
    end

    def write(key, value)
      entry = read(key)

      if entry
        entry.value = value
        database.update(entry)
      else
        entry = Entry.new(key: key, value: value, updated_at: Time.now)
        create_or_update(entry)
      end

      entry
    end

    def delete(key)
      entry = read(key)
      database.delete(entry) if entry
    end

    private

      # under some very specific situations, by the time the cache is being written,
      # a different process executed a query for the same cache key and wrote it to
      # the database, causing the creation call to fail with a unique constraint
      # violation error. In technical terms, this is a time-of-check, time-of-use
      # issue.
      #
      # This method works around such scenario by falling back to a standard update
      # in case the creation of the record cause the error described above.
      def create_or_update(entry)
        EntryRepository.create(entry)
      rescue Hanami::Model::UniqueConstraintViolationError
        entry = read(entry.key)
        database.update(entry)
      rescue Hanami::Model::Error => err
        database.create(entry)
      end


    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(EntryRepository)
    end

  end
end
