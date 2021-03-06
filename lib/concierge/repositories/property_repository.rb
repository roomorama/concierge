# +PropertyRepository+
#
# Persistence and query methods for the +properties+ table.
#
# The list of properties on Concierge should reflect those that are published
# on Roomorama. If a supplier disconnects or removes certain properties, these
# should no longer be stored in this table.
class PropertyRepository
  include Hanami::Repository

  # returns the total number of properties stored in the database.
  def self.count
    query.count
  end

  # filters properties that belong to any host of a given +supplier+, which is
  # expected to be an instance of the +Supplier+ entity.
  def self.from_supplier(supplier)
    hosts = HostRepository.from_supplier(supplier)

    query do
      where(host_id: hosts.map(&:id))
    end
  end

  # filters properties that belong to a given +host+, which is expected to be
  # a persisted instance of +Host+.
  def self.from_host(host)
    query { where(host_id: host.id) }
  end

  # looks for the +Property+ that matches the given identifier (i.e., the identification
  # of the property from the supplier's point of view.)
  #
  # Returns a collection of properties whose identifier match the given string.
  def self.identified_by(identifier)
    query { where(identifier: identifier) }
  end

  # changes the +select+ clause to include only the column wit the name given.
  def self.only(column)
    query { select(column) }
  end
end
