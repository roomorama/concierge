# +ExternalErrorRepository+
#
# Persistence operations and queries of the `external_errors` table.
class ExternalErrorRepository
  include Hanami::Repository

  # returns the total number of external errors stored in the database.
  def self.count
    query.count
  end

  # returns the most recent +ExternalError+ instance added to the database.
  # If the table is empty, this method returns +nil+.
  def self.most_recent
    scope = query { order(:happened_at).limit(1) }
    scope.to_a.first
  end
end
