# +SyncProcessRepository+
#
# Persistence and query methods for the +sync_processes+ table.
#
# Every synchronisation process that kicks in is recorded as an entry
# in this table.
class SyncProcessRepository
  include Hanami::Repository

  # returns the total number of properties stored in the database.
  def self.count
    query.count
  end

  def self.recent_successful_sync_for_host(host)
    query do
      where(successful: true).
      where(host_id: host.id).
      desc(:started_at)
    end
  end

end
