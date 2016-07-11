# +BackgroundWorkerRepository+
#
# Persistence and query methods for the +background_workers+ table.
class BackgroundWorkerRepository
  include Hanami::Repository

  # returns the total number of properties stored in the database.
  def self.count
    query.count
  end

end
