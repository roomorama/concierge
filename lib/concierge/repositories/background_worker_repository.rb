# +BackgroundWorkerRepository+
#
# Persistence and query methods for the +background_workers+ table.
class BackgroundWorkerRepository
  include Hanami::Repository

  # returns the total number of properties stored in the database.
  def self.count
    query.count
  end

  # returns a collection of background workers associated with the given +Host+
  # instance.
  def self.for_host(host)
    query do
      where(host_id: host.id)
    end
  end

  # queries for idle background workers
  def self.idle
    query do
      where(status: "idle")
    end
  end

  # queries for all background workers that are due for execution - that is,
  # those whose +next_run_at+ column is +null+ or holds a timestamp in the past.
  def self.pending
    query do
      where { next_run_at < Time.now }.or(next_run_at: nil).order(:next_run_at)
    end.idle
  end

end
