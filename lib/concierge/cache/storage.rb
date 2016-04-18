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
        database.create(entry)
      end

      entry
    end

    def delete(key)
      entry = read(key)
      database.delete(entry) if entry
    end

    private

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(EntryRepository)
    end

  end
end
