# +HostRepository+
#
# Persistence operations and query methods for the +hosts+ table.
class HostRepository
  include Hanami::Repository

  # utility method, performing a +COUNT+ to get the number of hosts in the database
  def self.count
    query.count
  end

  # queries for all hosts that belong to a given +supplier+
  def self.from_supplier(supplier)
    query do
      where(supplier_id: supplier.id)
    end
  end

  # queries for a host with the given +identifier+, which should be unique
  # per supplier.
  def self.identified_by(identifier)
    query do
      where(identifier: identifier)
    end
  end
end
