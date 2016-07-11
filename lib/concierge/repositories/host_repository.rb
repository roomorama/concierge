# +HostRepository+
#
# Persistence operations and query methods for the +hosts+ table.
class HostRepository
  include Hanami::Repository

  # utility method, performing a +COUNT+ to get the number of hosts in the database
  def self.count
    query.count
  end
end
