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

  # filters properties that belong to a given +host+, which is expected to be
  # a persisted instance of +Host+.
  def self.from_host(host)
    query { where(host_id: host.id) }
  end

  # returns the +Property+ that matches the given identifier (i.e., the identication
  # of the property from the supplier's point of view.)
  #
  # Returns +nil+ if there is no property with the given identifier.
  def self.identified_by(identifier)
    query { where(identifier: identifier) }.first
  end
end
