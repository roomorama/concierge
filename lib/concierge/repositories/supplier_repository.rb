# +SupplierRepository+
#
# Persistence operations and queries of the +suppliers+ table.
class SupplierRepository
  include Hanami::Repository

  # returns the total number of suppliers in the database.
  def self.count
    query.count
  end

  # name - a String, the supplier name to be queried.
  #
  # Returns the Supplier object associated with the given name, or +nil+
  # if one cannot be found.
  def self.named(name)
    query { where(name: name) }.to_a.first
  end
end
