# +HostRepository+
#
# Persistence operations and query methods for the +hosts+ table.
class HostRepository
  include Hanami::Repository

  # utility method, performing a +COUNT+ to get the number of hosts in the database
  def self.count
    query.count
  end

  # queries which hosts need to be synchronised at the current moment, by checking
  # the +next_run_at+ column. If that column is +NULL+, it is also considered to
  # be ready for synchronisation.
  def self.pending_synchronisation
    query do
      where { next_run_at < Time.now }.or(next_run_at: nil).order(:next_run_at)
    end
  end
end
