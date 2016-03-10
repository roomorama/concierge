# +ExternalErrorRepository+
#
# Persistence operations and queries of the `external_errors` table.
class ExternalErrorRepository
  include Hanami::Repository

  # returns the total number of external errors stored in the database.
  def self.count
    query.count
  end
end
