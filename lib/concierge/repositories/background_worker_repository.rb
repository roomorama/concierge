# +BackgroundWorkerRepository+
#
# Persistence and query methods for the +background_workers+ table.
class BackgroundWorkerRepository
  include Hanami::Repository

  # returns the total number of properties stored in the database.
  def self.count
    query.count
  end

  # returns a collection of backround workers associated with the given +Host+
  # instance.
  def self.for_host(host)
    query do
      where(host_id: host.id)
    end
  end

end
