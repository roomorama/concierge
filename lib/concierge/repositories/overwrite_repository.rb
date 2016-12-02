# +OverwriteRepository+
#
# Persistence and query methods for the +overwrites+ table.
#
class OverwriteRepository
  include Hanami::Repository

  # returns the total number of suppliers in the database.
  def self.count
    query.count
  end

  def self.for_host_id(host_id)
    query { where(host_id: host_id) }
  end

  def self.for_property_identifier(identifier)
    query { where(property_identifier: identifier) }
  end

  def self.all_for(identifier:, host_id:)

    host_overwrites = for_host_id(host_id).
                        for_property_identifier(nil).all

    property_overwrites = for_host_id(host_id).
                            for_property_identifier(identifier).all

    host_overwrites + property_overwrites
  end

end
